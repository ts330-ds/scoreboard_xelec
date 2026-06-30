import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Saare `debugPrint(...)` calls ko FileLogger me mirror karta hai (bina
/// refactor). Main aur background dono isolates isse call karte hain.
void installDebugPrintCapture() {
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      FileLogger.instance.log(message, tag: 'PRINT');
    }
    original(message, wrapWidth: wrapWidth);
  };
}

/// Map/List ko readable indented JSON me badalta hai (logs ke liye).
/// Non-string keys (BLE `Map<dynamic,dynamic>`) ko bhi handle karta hai.
String prettyJson(dynamic data, {int maxChars = 20000}) {
  if (data == null) return 'null';
  String out;
  if (data is Map || data is List) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      out = encoder.convert(_normalizeForJson(data));
    } catch (_) {
      out = data.toString();
    }
  } else {
    out = data.toString();
  }
  if (out.length > maxChars) {
    out = '${out.substring(0, maxChars)}… (${out.length} chars total, truncated)';
  }
  return out;
}

Object? _normalizeForJson(Object? v) {
  if (v is Map) {
    return v.map((k, val) => MapEntry(k.toString(), _normalizeForJson(val)));
  }
  if (v is List) return v.map(_normalizeForJson).toList();
  // Primitives JSON-safe; baaki sab (e.g. custom objects) string me.
  if (v is num || v is bool || v is String || v == null) return v;
  return v.toString();
}

/// App-wide file logger.
///
/// Saare logs ko ek single append-only file me likhta hai jise client
/// profile screen se padh aur share kar sakta hai. Disk pe direct har line
/// likhne ke bajaye ek in-memory buffer me jama karke periodically flush
/// karta hai — taaki BLE/HTTP ke high-frequency logs UI ko slow na karein.
///
/// File internal app storage (documents dir) me rehti hai — koi runtime
/// permission nahi chahiye, aur sirf share button se hi bahar jaati hai.
class FileLogger {
  FileLogger._();
  static final FileLogger instance = FileLogger._();

  /// Main isolate ki log file. Background isolate `_bgFileName` use karta hai
  /// taaki dono ek hi file pe na likhein (concurrent-write conflict avoid).
  static const String mainFileName = 'app_log.txt';
  static const String bgFileName = 'bg_log.txt';

  /// Is isolate ki active file ka naam (init me set hota hai).
  String _activeName = mainFileName;

  /// File itni badi hone pe sabse purana data hata diya jaata hai (rolling log).
  static const int _maxBytes = 20 * 1024 * 1024; // 20 MB

  /// Trim ke baad file me itna recent data rakha jaata hai (purana drop ho jata).
  static const int _keepBytes = 15 * 1024 * 1024; // last 15 MB

  /// Buffer ko itne interval pe disk pe flush karte hain.
  static const Duration _flushInterval = Duration(seconds: 2);

  final DateFormat _ts = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  File? _file;
  IOSink? _sink;
  final StringBuffer _buffer = StringBuffer();
  Timer? _flushTimer;
  bool _ready = false;

  /// File me ab tak kitne bytes hain (approx) — runtime pe size cap enforce karne ke liye.
  int _writtenBytes = 0;

  /// Trim chal raha hai — re-entry rokne ke liye.
  bool _trimming = false;

  /// Logger ke andar already hain — re-entry guard.
  ///
  /// `installDebugPrintCapture` har `debugPrint` ko `log()` me mirror karta hai.
  /// Agar logger ke apne error-handler (`_flush`/`clear` ke catch) `debugPrint`
  /// call karein, to wo capture hoke wapas `log()` -> `_writeRaw` -> `_flush`
  /// -> throw -> `debugPrint` -> ... ek synchronous infinite loop ban jata hai
  /// jo main thread freeze (ANR) kar deta hai. Ye flag us recursion ko todta hai.
  bool _inLog = false;

  /// Live log lines — viewer screen real-time tail ke liye subscribe karta hai.
  final StreamController<String> _liveController =
      StreamController<String>.broadcast();
  Stream<String> get liveStream => _liveController.stream;

  /// `main()` me sabse pehle ek baar call karo. Background isolate
  /// `fileName: FileLogger.bgFileName` pass karta hai.
  Future<void> init({String fileName = mainFileName}) async {
    if (_ready) return;
    _activeName = fileName;
    try {
      final logDir = await _logsDir();
      _file = File('${logDir.path}/$_activeName');
      _writtenBytes = await _file!.exists() ? await _file!.length() : 0;

      // APPEND mode — har launch pe file overwrite nahi hoti, logs jamte rehte hain.
      _sink = _file!.openWrite(mode: FileMode.writeOnlyAppend);
      _ready = true;

      // Launch pe agar file limit cross kar chuki hai to purana data trim karo.
      if (_writtenBytes >= _maxBytes) {
        await _trimOldest();
      }

      _flushTimer?.cancel();
      _flushTimer = Timer.periodic(_flushInterval, (_) => _flush());

      final now = DateTime.now();
      final src = _activeName == bgFileName ? 'BACKGROUND' : 'MAIN';
      _writeRaw('\n========================================================\n'
          '==== $src SESSION START  ${_ts.format(now)} ====\n'
          '========================================================');
    } catch (e) {
      // Logger kabhi app crash na kare — silently disable.
      debugPrint('[FileLogger] init failed: $e');
      _ready = false;
    }
  }

  /// Rolling log — file `_maxBytes` cross kare to sabse purana data hata kar
  /// sirf last `_keepBytes` rakho. Naya data aata rehta hai, purana drop hota hai.
  Future<void> _trimOldest() async {
    if (_trimming || _file == null) return;
    _trimming = true;
    try {
      // Pending buffer disk pe daalo, phir sink band karo.
      if (_buffer.isNotEmpty) {
        _sink?.write(_buffer.toString());
        _buffer.clear();
      }
      await _sink?.flush();
      await _sink?.close();
      _sink = null;

      final bytes = await _file!.readAsBytes();
      var start = bytes.length - _keepBytes;
      if (start < 0) start = 0;
      // Line ke beech se na kaate — agle newline (\n = 0x0A) tak aage badho.
      while (start < bytes.length && bytes[start] != 0x0A) {
        start++;
      }
      if (start < bytes.length) start++; // newline skip
      final tail = bytes.sublist(start);

      await _file!.writeAsBytes(tail, flush: true);
      _writtenBytes = tail.length;
    } catch (e) {
      debugPrint('[FileLogger] trim failed: $e');
    } finally {
      // Sink dobara append mode me kholo (trim ke baad bhi logging chalti rahe).
      try {
        _sink = _file!.openWrite(mode: FileMode.writeOnlyAppend);
      } catch (_) {}
      _trimming = false;
    }
  }

  /// Ek log line likho. `tag` se source (BLE/API/TASK-ZIP) identify hota hai.
  void log(String message, {String tag = 'APP', String level = 'INFO'}) {
    // Re-entry guard: logger ke andar se aayi koi bhi log line (e.g. error
    // handler ka captured debugPrint) yahin ruk jaati hai — warna synchronous
    // infinite recursion main thread ko freeze kar deti hai.
    if (_inLog) return;
    _inLog = true;
    try {
      final line = '${_ts.format(DateTime.now())} [$level] [$tag] $message';
      _writeRaw(line);
      // Viewer khula ho to live tail ke liye line bhejo.
      if (_liveController.hasListener) {
        _liveController.add(line);
      }
    } finally {
      _inLog = false;
    }
    // NOTE: yahan console `print` jaan-bujh ke nahi — high-frequency BLE events
    // pe synchronous console I/O main thread block kar deta hai (ANR). debugPrint
    // se aaye logs vaise bhi original handler ke through console me dikhte hain.
  }

  void _writeRaw(String line) {
    if (!_ready) return;
    _buffer.writeln(line);
    _writtenBytes += line.length + 1;
    // 20MB cross — purana data hatao (rolling). Trim ke dauraan re-entry guarded.
    if (_writtenBytes >= _maxBytes && !_trimming) {
      _trimOldest();
    }
    // Buffer bada ho gaya to turant flush — memory me jama na rahe.
    if (_buffer.length > 16 * 1024) {
      _flush();
    }
  }

  void _flush() {
    // Trim ke dauraan sink null hota hai — tab buffer ko chhod do, baad me jayega.
    if (!_ready || _buffer.isEmpty || _sink == null) return;
    try {
      _sink?.write(_buffer.toString());
      _buffer.clear();
    } catch (e) {
      debugPrint('[FileLogger] flush failed: $e');
    }
  }

  /// Pending buffer disk pe likho aur file path return karo.
  /// Share/read se pehle call karo taaki latest logs file me ho.
  Future<File?> flushAndGetFile() async {
    if (!_ready || _file == null) return null;
    _flush();
    try {
      await _sink?.flush();
    } catch (_) {}
    return _file;
  }

  /// Logs clear karo — is isolate ki file truncate + dusri (bg) file bhi delete.
  Future<void> clear() async {
    if (!_ready || _file == null) return;
    try {
      // Sink ko pehle null karo: clear ke awaits ke beech aane wali koi bhi
      // log/flush ab closed sink pe write na kare (warna throw -> error log
      // -> recursion). `_flush` _sink == null pe skip kar deta hai.
      final sink = _sink;
      _sink = null;
      await sink?.flush();
      await sink?.close();
      _buffer.clear();
      await _file!.writeAsString('');
      _writtenBytes = 0;
      _sink = _file!.openWrite(mode: FileMode.writeOnlyAppend);

      // Dusri isolate ki file (background) bhi khali kar do.
      final logDir = await _logsDir();
      final other = File(
          '${logDir.path}/${_activeName == mainFileName ? bgFileName : mainFileName}');
      if (await other.exists()) {
        await other.writeAsString('');
      }
      log('Logs cleared by user', tag: 'LOGGER');
    } catch (e) {
      debugPrint('[FileLogger] clear failed: $e');
    }
  }

  // ── Static helpers (file location + merged read across isolates) ──────────

  static Future<Directory> _logsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${dir.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    return logDir;
  }

  /// Main + background dono log files ko timestamp ke order me merge karke
  /// ek combined string deta hai (viewer ke liye).
  static Future<String> readMergedLogs() async {
    // Pehle main isolate ka pending buffer disk pe daal do.
    await instance.flushAndGetFile();
    try {
      final logDir = await _logsDir();
      final mainF = File('${logDir.path}/$mainFileName');
      final bgF = File('${logDir.path}/$bgFileName');
      final mainTxt = await mainF.exists() ? await mainF.readAsString() : '';
      final bgTxt = await bgF.exists() ? await bgF.readAsString() : '';
      if (bgTxt.isEmpty) return mainTxt;
      if (mainTxt.isEmpty) return bgTxt;
      return _mergeByTimestamp(mainTxt, bgTxt);
    } catch (e) {
      return 'Could not read logs: $e';
    }
  }

  /// Merged logs ko ek temp file me likh kar share ke liye return karta hai.
  static Future<File?> buildShareFile() async {
    try {
      final merged = await readMergedLogs();
      final tmp = await getTemporaryDirectory();
      final out = File('${tmp.path}/xelex_logs.txt');
      await out.writeAsString(merged, flush: true);
      return out;
    } catch (e) {
      debugPrint('[FileLogger] buildShareFile failed: $e');
      return null;
    }
  }

  // Har record ka pehla line timestamp se shuru hota hai; continuation lines
  // (pretty JSON) usi record ka hissa hain. Records ko timestamp se sort karte hain.
  static final RegExp _tsLine =
      RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}');

  static String _mergeByTimestamp(String a, String b) {
    final recs = <_LogRecord>[];
    recs.addAll(_parseRecords(a));
    recs.addAll(_parseRecords(b));
    // Stable sort by leading timestamp (fixed-width to lexical sort works).
    recs.sort((x, y) => x.ts.compareTo(y.ts));
    return recs.map((r) => r.text).join('\n');
  }

  static List<_LogRecord> _parseRecords(String content) {
    final records = <_LogRecord>[];
    final lines = content.split('\n');
    StringBuffer? cur;
    String curTs = '';
    for (final line in lines) {
      if (_tsLine.hasMatch(line)) {
        if (cur != null) records.add(_LogRecord(curTs, cur.toString()));
        cur = StringBuffer(line);
        curTs = line.substring(0, 23); // timestamp width
      } else {
        // Header/continuation line — current record ka hissa (ya orphan).
        cur ??= StringBuffer();
        if (cur.isNotEmpty) cur.write('\n');
        cur.write(line);
      }
    }
    if (cur != null) records.add(_LogRecord(curTs, cur.toString()));
    return records;
  }
}

class _LogRecord {
  final String ts;
  final String text;
  _LogRecord(this.ts, this.text);
}
