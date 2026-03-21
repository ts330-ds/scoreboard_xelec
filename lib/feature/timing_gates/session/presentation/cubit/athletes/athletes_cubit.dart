import 'dart:io';

import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/athletes/athletes_state.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/repository/athlete_repository.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_model.dart';

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
        withData: true,
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
        parsed = _parseExcel(file);
      } else {
        emit(state.copyWith(isImporting: false));
        errorCubit.showError('Unsupported format. Use .csv or .xlsx');
        return;
      }

      if (parsed.isEmpty) {
        emit(state.copyWith(isImporting: false));
        errorCubit.showWarning('No valid athletes found. Check the file format.');
        return;
      }

      // Store preview — UI will show dialog
      emit(state.copyWith(isImporting: false, importPreview: parsed));
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
        'Storage permission denied. Please allow file access to upload.',
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

      athletes.add(AthleteModel(
        id: generateId(),
        fullName: name,
        athleteId: _col(cols, colMap['athleteId']).trim(),
        bib: _col(cols, colMap['bib']).trim(),
        team: _col(cols, colMap['team']).trim(),
        dob: _col(cols, colMap['dob']).trim(),
        age: int.tryParse(_col(cols, colMap['age']).trim()),
        sex: _col(cols, colMap['sex']).trim(),
        discipline: _col(cols, colMap['discipline']).trim(),
        trials: int.tryParse(_col(cols, colMap['trials']).trim()) ?? 3,
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

  List<AthleteModel> _parseExcel(PlatformFile file) {
    final bytes = file.bytes;
    if (bytes == null) {
      if (file.path == null) return [];
      return _parseExcelBytes(File(file.path!).readAsBytesSync());
    }
    return _parseExcelBytes(bytes);
  }

  List<AthleteModel> _parseExcelBytes(List<int> bytes) {
    final excel = excel_lib.Excel.decodeBytes(bytes);
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null) return [];

    final rows = sheet.rows;
    if (rows.isEmpty) return [];

    final firstRow =
        rows.first.map((c) => (c?.value?.toString() ?? '').toLowerCase()).toList();
    final hasHeader = firstRow
        .any((h) => h.contains('name') || h.contains('id') || h.contains('athlete'));

    Map<String, int> colMap = {};
    if (hasHeader) {
      for (int i = 0; i < firstRow.length; i++) {
        final h = firstRow[i];
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

    final dataRows = hasHeader ? rows.skip(1).toList() : rows;
    final athletes = <AthleteModel>[];

    for (final row in dataRows) {
      final vals = row.map((c) => c?.value?.toString() ?? '').toList();
      if (vals.isEmpty) continue;
      final name = _col(vals, colMap['name']).trim();
      if (name.isEmpty) continue;

      athletes.add(AthleteModel(
        id: generateId(),
        fullName: name,
        athleteId: _col(vals, colMap['athleteId']).trim(),
        bib: _col(vals, colMap['bib']).trim(),
        team: _col(vals, colMap['team']).trim(),
        dob: _col(vals, colMap['dob']).trim(),
        age: int.tryParse(_col(vals, colMap['age']).trim()),
        sex: _col(vals, colMap['sex']).trim(),
        discipline: _col(vals, colMap['discipline']).trim(),
        trials: int.tryParse(_col(vals, colMap['trials']).trim()) ?? 3,
      ));
    }
    return athletes;
  }

  String _col(List<String> cols, int? idx) =>
      (idx != null && idx < cols.length) ? cols[idx] : '';

  // ── Helper: generate athlete ID ───────────────────────────────────────────

  String generateId() => const Uuid().v4();
}
