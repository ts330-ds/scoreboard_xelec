import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/athletes/athletes_state.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/repository/athlete_repository.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_model.dart';

/// Thrown inside parsing helpers when an error message has already been
/// shown via [errorCubit] so the caller must NOT show a second message.
class _ParseException implements Exception {
  const _ParseException();
}

class AthletesCubit extends Cubit<AthletesState> {
  final AthleteRepository repository;
  final GlobalErrorCubit errorCubit;

  AthletesCubit({required this.repository, required this.errorCubit})
      : super(const AthletesState());

  // ── Initialize ────────────────────────────────────────────────────────────

  void initialize() {
    _reloadPage(page: 0);
  }

  // ── Pagination ────────────────────────────────────────────────────────────

  void loadNextPage() {
    if (state.isLoading || !state.hasMore) return;
    _reloadPage(page: state.currentPage + 1, append: true);
  }

  void _reloadPage({int page = 0, bool append = false}) {
    emit(state.copyWith(isLoading: true));

    final newAthletes = repository.getPaged(
      page: page,
      search: state.searchQuery,
      team: state.teamFilter,
    );

    final combined = append ? [...state.athletes, ...newAthletes] : newAthletes;

    emit(state.copyWith(
      athletes: combined,
      isLoading: false,
      currentPage: page,
      hasMore: repository.hasMore(
        page: page,
        search: state.searchQuery,
        team: state.teamFilter,
      ),
      allTeams: repository.getAllTeams(),
      totalCount: repository.count(
        search: state.searchQuery,
        team: state.teamFilter,
      ),
    ));
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addAthlete(AthleteModel athlete) async {
    await repository.save(athlete);
    _reloadPage(page: 0);
  }

  Future<void> updateAthlete(AthleteModel athlete) async {
    await repository.update(athlete);
    _reloadPage(page: state.currentPage);
  }

  Future<void> deleteAthlete(String id) async {
    await repository.delete(id);
    // If current page becomes empty after delete, go to previous page
    final newPage = state.athletes.length == 1 && state.currentPage > 0
        ? state.currentPage - 1
        : state.currentPage;
    _reloadPage(page: newPage);
  }

  // ── Search & Filter ───────────────────────────────────────────────────────

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
    _reloadPage(page: 0);
  }

  void updateTeamFilter(String team) {
    emit(state.copyWith(teamFilter: team));
    _reloadPage(page: 0);
  }

  // ── File Import ───────────────────────────────────────────────────────────

  /// Step 1: Pick + parse file → stores preview in state.
  /// UI should watch [state.hasImportPreview] to show the confirmation dialog.
  Future<void> importFromFile() async {
    final hasPermission = await _ensureStoragePermission();
    if (!hasPermission) return;

    emit(state.copyWith(isImporting: true));

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,       // always request in-memory bytes
      );

      if (result == null || result.files.isEmpty) {
        emit(state.copyWith(isImporting: false));
        return;
      }

      final file = result.files.first;
      final ext = (file.extension ?? '').toLowerCase();
      List<AthleteModel> parsed = [];

      if (ext == 'csv') {
        parsed = _parseCsv(file);
      } else if (ext == 'xlsx' || ext == 'xls') {
        parsed = await _parseExcelSafe(file);
      } else {
        emit(state.copyWith(isImporting: false));
        errorCubit.showError('Unsupported format. Use .csv or .xlsx');
        return;
      }

      if (parsed.isEmpty) {
        emit(state.copyWith(isImporting: false));
        errorCubit.showWarning(
          'No athletes found in file.\n'
          'Make sure the sheet has a "Name" column header.',
        );
        return;
      }

      // Store preview — UI will show dialog
      emit(state.copyWith(isImporting: false, importPreview: parsed));
    } on _ParseException {
      // error already shown inside _parseExcelSafe — just reset state
      emit(state.copyWith(isImporting: false));
    } catch (e) {
      emit(state.copyWith(isImporting: false));
      errorCubit.showError('Failed to read file: ${e.toString()}');
    }
  }

  /// Step 2: User confirmed preview → bulk save to Hive.
  Future<void> confirmImport() async {
    final athletes = state.importPreview;
    if (athletes.isEmpty) return;

    emit(state.copyWith(isLoading: true, clearImportPreview: true));

    try {
      await repository.saveAll(athletes);
      _reloadPage(page: 0);
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      errorCubit.showError('Import failed: ${e.toString()}');
    }
  }

  /// Step 2 (cancel): Discard preview.
  void cancelImport() {
    emit(state.copyWith(clearImportPreview: true));
  }

  // ── Permission ────────────────────────────────────────────────────────────

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ (API 33+): READ_EXTERNAL_STORAGE was removed.
    // file_picker uses SAF (ACTION_OPEN_DOCUMENT) which needs NO runtime
    // permission — the system picker handles access itself.
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) return true;

    // Android 10–12 (API 29–32): READ_EXTERNAL_STORAGE still works.
    final status = await Permission.storage.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      errorCubit.showError(
        'Storage permission permanently denied. '
        'Please enable "Files and media" in App Settings.',
      );
      return false;
    }

    final result = await Permission.storage.request();
    if (result.isGranted || result.isLimited) return true;

    if (result.isPermanentlyDenied) {
      errorCubit.showError(
        'Storage permission denied. Enable it in App Settings to import files.',
      );
    } else {
      errorCubit.showWarning(
        'Storage permission denied. Please allow file access to import.',
      );
    }
    return false;
  }

  // ── CSV / Excel Parsing ───────────────────────────────────────────────────

  List<AthleteModel> _parseCsv(PlatformFile file) {
    final bytes = file.bytes;
    String content;
    if (bytes != null) {
      content = String.fromCharCodes(bytes);
    } else if (file.path != null) {
      content = File(file.path!).readAsStringSync();
    } else {
      return [];
    }

    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    final headerLine = lines.first.toLowerCase();
    final hasHeader = headerLine.contains('name') ||
        headerLine.contains('id') ||
        headerLine.contains('athlete');

    Map<String, int> colMap = {};
    if (hasHeader) {
      final headers = _splitCsvRow(lines.first.toLowerCase());
      for (int i = 0; i < headers.length; i++) {
        final h = headers[i].trim();
        if (h.contains('name')) colMap['name'] = i;
        if ((h.contains('athlete') && h.contains('id')) || h == 'athlete_id' || h == 'athleteid') colMap['athleteId'] = i;
        if (h == 'id' || h == 'ath id') colMap['athleteId'] = i;
        if (h.contains('bib')) colMap['bib'] = i;
        if (h.contains('team') || h.contains('group')) colMap['team'] = i;
        if (h.contains('dob') || h.contains('birth')) colMap['dob'] = i;
        if (h == 'age') colMap['age'] = i;
        if (h.contains('sex') || h.contains('gender')) colMap['sex'] = i;
        if (h.contains('discipline') || h.contains('event')) colMap['discipline'] = i;
        if (h.contains('trial')) colMap['trials'] = i;
      }
    } else {
      colMap = {'name': 0, 'athleteId': 1, 'bib': 2, 'team': 3, 'dob': 4, 'trials': 5};
    }

    final dataLines = hasHeader ? lines.skip(1).toList() : lines;
    final athletes = <AthleteModel>[];

    for (final line in dataLines) {
      final cols = _splitCsvRow(line);
      if (cols.isEmpty) continue;
      final name = _col(cols, colMap['name']).trim();
      if (name.isEmpty) continue;

      final athleteId = _col(cols, colMap['athleteId']).trim();
      final bib       = _col(cols, colMap['bib']).trim();
      athletes.add(AthleteModel(
        id:         _importId(name, athleteId, bib),
        fullName:   name,
        athleteId:  athleteId,
        bib:        bib,
        team:       _col(cols, colMap['team']).trim(),
        dob:        _col(cols, colMap['dob']).trim(),
        age:        int.tryParse(_col(cols, colMap['age']).trim()),
        sex:        _col(cols, colMap['sex']).trim(),
        discipline: _col(cols, colMap['discipline']).trim(),
        trials:     int.tryParse(_col(cols, colMap['trials']).trim()) ?? 3,
      ));
    }
    return athletes;
  }

  List<String> _splitCsvRow(String row) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < row.length; i++) {
      final ch = row[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  /// Resolves file bytes from [file], then delegates to [_parseExcelBytes].
  /// Throws [_ParseException] if an error message was already shown.
  Future<List<AthleteModel>> _parseExcelSafe(PlatformFile file) async {
    Uint8List? bytes = file.bytes;

    // Fallback: read from path only when it's a real filesystem path
    // (not a content:// URI from Android SAF).
    if ((bytes == null || bytes.isEmpty) && file.path != null) {
      final path = file.path!;
      if (!path.startsWith('content://')) {
        try {
          bytes = await File(path).readAsBytes();
        } catch (_) {
          // path unreadable — will be caught below
        }
      }
    }

    if (bytes == null || bytes.isEmpty) {
      errorCubit.showError(
        'Could not load file bytes.\n'
        'Try opening the file from your Downloads or Files app.',
      );
      throw const _ParseException();
    }

    return _parseExcelBytes(bytes);
  }

  List<AthleteModel> _parseExcelBytes(Uint8List bytes) {
    final excel_lib.Excel workbook;
    try {
      workbook = excel_lib.Excel.decodeBytes(bytes);
    } catch (e) {
      errorCubit.showError(
        'Cannot open Excel file: ${e.toString().split('\n').first}\n'
        'Make sure it is a valid .xlsx/.xls file (not password-protected).',
      );
      throw const _ParseException();
    }

    if (workbook.tables.isEmpty) {
      errorCubit.showWarning('Excel file has no sheets.');
      throw const _ParseException();
    }
    final sheetName = workbook.tables.keys.first;
    final sheet = workbook.tables[sheetName];
    if (sheet == null || sheet.rows.isEmpty) return [];

    final rows = sheet.rows;

    // Use first row to detect headers
    final firstRow = rows.first
        .map((c) => _cellStr(c).toLowerCase().trim())
        .toList();
    final hasHeader = firstRow
        .any((h) => h.contains('name') || h.contains('id') || h.contains('athlete'));

    Map<String, int> colMap = {};
    if (hasHeader) {
      for (int i = 0; i < firstRow.length; i++) {
        final h = firstRow[i];
        if (h.contains('name')) colMap['name'] = i;
        if ((h.contains('athlete') && h.contains('id')) ||
            h == 'athlete_id' ||
            h == 'athleteid') { colMap['athleteId'] = i; }
        if (h == 'id' || h == 'ath id') colMap['athleteId'] = i;
        if (h.contains('bib')) colMap['bib'] = i;
        if (h.contains('team') || h.contains('group')) colMap['team'] = i;
        if (h.contains('dob') || h.contains('birth')) colMap['dob'] = i;
        if (h == 'age') colMap['age'] = i;
        if (h.contains('sex') || h.contains('gender')) colMap['sex'] = i;
        if (h.contains('discipline') || h.contains('event')) colMap['discipline'] = i;
        if (h.contains('trial')) colMap['trials'] = i;
      }
    } else {
      colMap = {
        'name': 0, 'athleteId': 1, 'bib': 2,
        'team': 3, 'dob': 4, 'trials': 5,
      };
    }

    final dataRows = hasHeader ? rows.skip(1).toList() : rows;
    final athletes = <AthleteModel>[];

    for (final row in dataRows) {
      // Skip completely empty rows
      if (row.every((c) => _cellStr(c).trim().isEmpty)) continue;

      final vals = row.map((c) => _cellStr(c)).toList();
      final name = _col(vals, colMap['name']).trim();
      if (name.isEmpty) continue;

      final athleteId = _col(vals, colMap['athleteId']).trim();
      final bib       = _col(vals, colMap['bib']).trim();
      athletes.add(AthleteModel(
        id:         _importId(name, athleteId, bib),
        fullName:   name,
        athleteId:  athleteId,
        bib:        bib,
        team:       _col(vals, colMap['team']).trim(),
        dob:        _col(vals, colMap['dob']).trim(),
        age:        int.tryParse(_col(vals, colMap['age']).trim()),
        sex:        _col(vals, colMap['sex']).trim(),
        discipline: _col(vals, colMap['discipline']).trim(),
        trials:     int.tryParse(_col(vals, colMap['trials']).trim()) ?? 3,
      ));
    }
    return athletes;
  }

  /// Safely extracts a plain-text string from an excel [Data] cell.
  ///
  /// Excel 4.x uses a sealed [CellValue] hierarchy — calling `.toString()`
  /// directly on [TextCellValue] returns "TextSpan(...)" not the actual text,
  /// because its `.value` field is a Flutter [TextSpan].  We pattern-match
  /// each subtype to get the real value.
  String _cellStr(excel_lib.Data? cell) {
    if (cell == null) return '';
    final val = cell.value;
    if (val == null) return '';
    return switch (val) {
      excel_lib.TextCellValue() => val.value.toString(),
      excel_lib.IntCellValue() => val.value.toString(),
      excel_lib.DoubleCellValue() => val.value.toString(),
      excel_lib.BoolCellValue() => val.value.toString(),
      excel_lib.DateCellValue() =>
        '${val.year}-${val.month.toString().padLeft(2, '0')}-'
        '${val.day.toString().padLeft(2, '0')}',
      excel_lib.FormulaCellValue() => val.formula,
      _ => '',
    };
  }

  String _col(List<String> cols, int? idx) =>
      (idx != null && idx < cols.length) ? cols[idx] : '';

  // ── ID helpers ────────────────────────────────────────────────────────────

  /// Random UUID — used when creating an athlete manually via the form.
  String generateId() => const Uuid().v4();

  /// Deterministic UUID (v5) derived from athlete identity fields.
  ///
  /// Same [name] + [athleteId] + [bib] → same UUID every time.
  /// This means re-importing the same file UPDATES existing athletes
  /// instead of creating duplicates.
  ///
  /// Falls back to [name]-only key if both [athleteId] and [bib] are empty
  /// (e.g. a file with just names).
  String _importId(String name, String athleteId, String bib) {
    final key =
        '${name.trim().toLowerCase()}:${athleteId.trim().toLowerCase()}:${bib.trim().toLowerCase()}';
    // UUID v5 with the DNS namespace gives a stable, collision-resistant ID.
    return const Uuid().v5(Namespace.dns.value, key);
  }
}
