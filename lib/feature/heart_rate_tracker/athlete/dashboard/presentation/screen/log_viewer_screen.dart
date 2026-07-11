import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xelex_esp/core/logging/file_logger.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

/// App logs ko padhne, share karne aur clear karne ki screen.
/// Profile screen ke "App Logs" button se khulti hai.
class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  // Bade log file ko poora render karna heavy hota hai — screen pe sirf last
  // ~200KB (tail) dikhate hain; Share/Copy poori file use karta hai.
  static const int _maxDisplayChars = 200 * 1024;

  String _logs = '';
  bool _loading = true;
  bool _live = true; // live tail on/off
  bool _dirty = false; // naye logs aaye, UI refresh pending
  bool _autoScroll = true; // user upar scroll na kare to hi auto-bottom

  final _scrollCtrl = ScrollController();
  StreamSubscription<String>? _liveSub;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load();
    _subscribeLive();
    // Naye logs ko throttle karke har 600ms me UI pe refresh karte hain
    // (har line pe setState heavy hota — BLE/HTTP bahut tez aate hain).
    _uiTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (_dirty && mounted) {
        setState(() => _dirty = false);
        _maybeAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    _uiTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _subscribeLive() {
    _liveSub = FileLogger.instance.liveStream.listen((line) {
      if (!_live) return;
      _logs += '$line\n';
      if (_logs.length > _maxDisplayChars) {
        _logs = _tail(_logs, _maxDisplayChars);
      }
      _dirty = true; // _uiTimer agle tick pe render karega
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final atBottom = _scrollCtrl.offset >=
        _scrollCtrl.position.maxScrollExtent - 80;
    // User ne upar scroll kiya to auto-scroll band; wapas neeche aaya to on.
    _autoScroll = atBottom;
  }

  void _maybeAutoScroll() {
    if (!_autoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  // Line boundary pe last n chars rakho.
  String _tail(String s, int n) {
    if (s.length <= n) return s;
    var start = s.length - n;
    final nl = s.indexOf('\n', start);
    if (nl != -1 && nl + 1 < s.length) start = nl + 1;
    return s.substring(start);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Main + background dono isolates ki logs merge karke padho.
    final content = await FileLogger.readMergedLogs();
    if (!mounted) return;
    setState(() {
      _logs = _tail(content, _maxDisplayChars);
      _loading = false;
    });
    _autoScroll = true;
    _maybeAutoScroll();
  }

  Future<void> _share() async {
    // Merged (main + background) logs ki ek combined file share karo.
    final file = await FileLogger.buildShareFile();
    if (file == null) {
      _snack('No log file found');
      return;
    }
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/plain')],
      subject: 'Xelex App Logs',
      text: 'Attached are the app logs.',
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _logs));
    _snack('Logs copied to clipboard');
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear logs?'),
        content: const Text(
          'This will permanently delete all saved logs from this device.',
          style: TextStyle(color: AppColors.subtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.subtext)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FileLogger.instance.clear();
      await _load();
    }
  }

  // JSON keys ("...": ) ko bold, baaki text normal. Regex pure text pe chalti
  // hai — chahe JSON pretty-printed ho ya inline.
  static final RegExp _keyRegex = RegExp(r'"(?:[^"\\]|\\.)*"\s*:');

  List<TextSpan> _buildSpans(String text) {
    final spans = <TextSpan>[];
    int last = 0;
    for (final m in _keyRegex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(0),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return spans;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('App Logs'),
        actions: [
          // Live tail on/off — band hone pe naye logs ruk jaate hain.
          IconButton(
            tooltip: _live ? 'Pause live' : 'Resume live',
            icon: Icon(
              _live ? Icons.pause_circle_outline : Icons.play_circle_outline,
              color: _live ? AppColors.primary : null,
            ),
            onPressed: () {
              setState(() => _live = !_live);
              if (_live) {
                _autoScroll = true;
                _load(); // resume pe latest tail sync kar lo
              }
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _logs.isEmpty ? null : _copy,
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline),
            onPressed: _logs.isEmpty ? null : _confirmClear,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.trim().isEmpty
              ? const Center(
                  child: Text('No logs yet',
                      style: TextStyle(color: AppColors.subtext)),
                )
              : Scrollbar(
                  controller: _scrollCtrl,
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    child: SelectableText.rich(
                      TextSpan(children: _buildSpans(_logs)),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'log_viewer_share_fab',
        backgroundColor: AppColors.primary,
        onPressed: _share,
        icon: const Icon(Icons.share, color: Colors.white),
        label: const Text('Share', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
