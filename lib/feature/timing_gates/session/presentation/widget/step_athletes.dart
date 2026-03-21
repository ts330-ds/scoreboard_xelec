import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/repository/athlete_repository.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_state.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class StepAthletes extends StatefulWidget {
  const StepAthletes({super.key});

  @override
  State<StepAthletes> createState() => _StepAthletesState();
}

class _StepAthletesState extends State<StepAthletes> {
  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _surface2 = Color(0xFFF0F4F8);
  static const _border = Color(0xFFDDE3EC);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _success = Color(0xFF16A34A);
  static const _error = Color(0xFFDC2626);

  bool _isUploading = false;

  // ── Permission handling ───────────────────────────────────────

  Future<bool> _ensureStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    // Android 13+ (SDK 33+): file_picker uses Storage Access Framework (SAF)
    // which opens the system file picker directly — no permission needed.
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) return true;

    // Android < 13: needs READ_EXTERNAL_STORAGE
    final status = await Permission.storage.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) _showPermissionDeniedDialog(context);
      return false;
    }

    final result = await Permission.storage.request();
    if (result.isGranted || result.isLimited) return true;

    if (result.isPermanentlyDenied && context.mounted) {
      _showPermissionDeniedDialog(context);
    } else if (context.mounted) {
      context.read<GlobalErrorCubit>().showWarning(
        'Storage permission denied. Please allow file access to upload.',
      );
    }
    return false;
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage access is permanently denied.\n'
          'Please enable "Files and media" permission for this app in Settings.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(color: _primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── File upload ───────────────────────────────────────────────
  Future<void> _pickAndParseFile(
    BuildContext context,
    TimingSessionCubit cubit,
  ) async {
    final hasPermission = await _ensureStoragePermission(context);
    if (!hasPermission) return;

    setState(() => _isUploading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isUploading = false);
        return;
      }

      final file = result.files.first;
      final ext = (file.extension ?? '').toLowerCase();
      List<AthleteModel> parsed = [];
      int skippedRows = 0;

      if (ext == 'csv') {
        final r = _parseCsv(file);
        parsed = r.athletes;
        skippedRows = r.skipped;
      } else if (ext == 'xlsx' || ext == 'xls') {
        final r = _parseExcel(file);
        parsed = r.athletes;
        skippedRows = r.skipped;
      } else {
        setState(() => _isUploading = false);
        if (context.mounted) {
          context.read<GlobalErrorCubit>().showError(
            'Unsupported format. Use .csv or .xlsx',
          );
        }
        return;
      }

      if (parsed.isEmpty) {
        setState(() => _isUploading = false);
        if (context.mounted) {
          final msg = skippedRows > 0
              ? 'No valid athletes found — $skippedRows row(s) skipped due to missing name.'
              : 'No valid athletes found. Check the file format.';
          context.read<GlobalErrorCubit>().showWarning(msg);
        }
        return;
      }

      setState(() => _isUploading = false);

      if (context.mounted) {
        _showImportPreview(context, cubit, parsed, file.name, skippedRows: skippedRows);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (context.mounted) {
        context.read<GlobalErrorCubit>().showError(
          'Failed to read file: ${e.toString()}',
        );
      }
    }
  }

  // ── CSV Parsing ───────────────────────────────────────────────
  ({List<AthleteModel> athletes, int skipped}) _parseCsv(PlatformFile file) {
    final bytes = file.bytes;
    String content;
    if (bytes != null) {
      content = String.fromCharCodes(bytes);
    } else if (file.path != null) {
      content = File(file.path!).readAsStringSync();
    } else {
      return (athletes: [], skipped: 0);
    }

    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return (athletes: [], skipped: 0);

    final headerLine = lines.first.toLowerCase();
    final hasHeader =
        headerLine.contains('name') || headerLine.contains('athlete');

    Map<String, int> colMap = {};
    if (hasHeader) {
      final headers = _splitCsvRow(lines.first.toLowerCase());
      for (int i = 0; i < headers.length; i++) {
        final h = headers[i].trim();
        if (h.contains('name')) colMap['name'] = i;
        if ((h.contains('athlete') && h.contains('id')) ||
            h == 'athlete_id' ||
            h == 'id') {
          colMap['athleteId'] = i;
        }
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
    int skipped = 0;

    for (final line in dataLines) {
      final cols = _splitCsvRow(line);
      if (cols.isEmpty) { skipped++; continue; }
      final name = _col(cols, colMap['name']).trim();
      if (name.isEmpty) { skipped++; continue; }

      athletes.add(AthleteModel(
        id: const Uuid().v4(),
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
    return (athletes: athletes, skipped: skipped);
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

  String _col(List<String> cols, int? idx) =>
      (idx != null && idx < cols.length) ? cols[idx] : '';

  // ── Excel Parsing ─────────────────────────────────────────────
  ({List<AthleteModel> athletes, int skipped}) _parseExcel(PlatformFile file) {
    final bytes = file.bytes;
    if (bytes == null) {
      if (file.path == null) return (athletes: [], skipped: 0);
      return _parseExcelBytes(File(file.path!).readAsBytesSync());
    }
    return _parseExcelBytes(bytes);
  }

  // excel v4.x returns CellValue (sealed class) — extract plain string safely
  String _cellStr(excel_lib.Data? cell) {
    if (cell == null) return '';
    final v = cell.value;
    if (v == null) return '';
    // Pattern-match each CellValue subtype to get actual value
    if (v is excel_lib.TextCellValue) return v.value.toString();
    if (v is excel_lib.IntCellValue) return v.value.toString();
    if (v is excel_lib.DoubleCellValue) {
      // e.g. BIB "101" stored as 101.0 → return "101" not "101.0"
      final d = v.value;
      if (d == d.truncateToDouble()) return d.toInt().toString();
      return d.toString();
    }
    if (v is excel_lib.BoolCellValue) return v.value.toString();
    if (v is excel_lib.DateCellValue) {
      return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
    }
    if (v is excel_lib.DateTimeCellValue) {
      return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')} ${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}:${v.second.toString().padLeft(2, '0')}  ';
    }
    // Fallback — covers any future subtypes
    return v.toString();
  }

  ({List<AthleteModel> athletes, int skipped}) _parseExcelBytes(List<int> bytes) {
    try {
      final excel = excel_lib.Excel.decodeBytes(bytes);

      // Guard: no sheets in file
      if (excel.tables.isEmpty) return (athletes: [], skipped: 0);

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];
      if (sheet == null) return (athletes: [], skipped: 0);

      final rows = sheet.rows;
      if (rows.isEmpty) return (athletes: [], skipped: 0);

      final firstRow = rows.first.map((c) => _cellStr(c).toLowerCase()).toList();
      final hasHeader = firstRow.any(
        (h) => h.contains('name') || h.contains('athlete'),
      );

      Map<String, int> colMap = {};
      if (hasHeader) {
        for (int i = 0; i < firstRow.length; i++) {
          final h = firstRow[i].trim();
          if (h.contains('name')) colMap['name'] = i;
          if ((h.contains('athlete') && h.contains('id')) ||
              h == 'athlete_id' ||
              h == 'id') {
            colMap['athleteId'] = i;
          }
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
      int skipped = 0;

      for (final row in dataRows) {
        try {
          final vals = row.map((c) => _cellStr(c)).toList();
          if (vals.isEmpty || vals.every((v) => v.trim().isEmpty)) {
            skipped++;
            continue;
          }
          final name = _col(vals, colMap['name']).trim();
          if (name.isEmpty) { skipped++; continue; }

          athletes.add(AthleteModel(
            id: const Uuid().v4(),
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
        } catch (_) {
          // Bad row — skip silently
          skipped++;
        }
      }
      return (athletes: athletes, skipped: skipped);
    } catch (e) {
      throw Exception('Failed to read Excel file: $e');
    }
  }

  // ── Dedupe key (mirrors cubit logic) ─────────────────────────
  String _dedupeKey(AthleteModel a) =>
      a.athleteId.isNotEmpty ? a.athleteId.toLowerCase() : a.fullName.toLowerCase();

  // ── Import Preview ────────────────────────────────────────────
  void _showImportPreview(
    BuildContext context,
    TimingSessionCubit cubit,
    List<AthleteModel> athletes,
    String fileName, {
    int skippedRows = 0,
  }) {
    // Calculate how many are duplicates against current session list
    final existingKeys =
        cubit.state.athletes.map(_dedupeKey).toSet();
    final newCount =
        athletes.where((a) => !existingKeys.contains(_dedupeKey(a))).length;
    final dupCount = athletes.length - newCount;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Import Athletes',
                          style: TextStyle(
                            color: _text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          fileName,
                          style: const TextStyle(color: _subtext, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Stats row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _statChip('${athletes.length} found', _success),
                  if (dupCount > 0) ...[
                    _statChip('$dupCount duplicate', const Color(0xFFD97706)),
                    _statChip('$newCount new', _primary),
                  ],
                  if (skippedRows > 0)
                    _statChip('$skippedRows skipped', const Color(0xFFEF4444)),
                ],
              ),
              if (skippedRows > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$skippedRows row(s) skipped — missing Full Name field.',
                          style: const TextStyle(
                              color: Color(0xFF991B1B), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (dupCount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Text(
                    '$dupCount athlete(s) already exist. Choose how to import:',
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: _surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _previewRow('Athlete ID', 'Name', 'Team', 'Trials', isHeader: true),
                    const Divider(color: _border, height: 1),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: athletes.length > 6 ? 6 : athletes.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: _border, height: 1),
                        itemBuilder: (_, i) {
                          if (i == 5 && athletes.length > 6) {
                            return Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                '+ ${athletes.length - 5} more athletes...',
                                style: const TextStyle(
                                  color: _subtext,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }
                          final a = athletes[i];
                          final isDup = existingKeys.contains(_dedupeKey(a));
                          return _previewRow(
                            a.athleteId.isNotEmpty ? a.athleteId : '-',
                            a.fullName,
                            a.team,
                            '${a.trials}',
                            isDuplicate: isDup,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons
              if (dupCount > 0) ...[
                // Two options when duplicates exist
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: newCount == 0
                        ? null
                        : () {
                            cubit.importAthletes(athletes);
                            sl<AthleteRepository>().saveAll(athletes);
                            Navigator.pop(ctx);
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      newCount == 0
                          ? 'No new athletes to add'
                          : 'Add $newCount New Only (skip duplicates)',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      cubit.importAthletes(athletes, replaceAll: true);
                      sl<AthleteRepository>().saveAll(athletes);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Replace All (${athletes.length} athletes)'),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ] else ...[
                // No duplicates — simple import
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        cubit.importAthletes(athletes);
                        sl<AthleteRepository>().saveAll(athletes);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Import ${athletes.length} Athletes'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _previewRow(
    String col1,
    String name,
    String team,
    String trials, {
    bool isHeader = false,
    bool isDuplicate = false,
  }) {
    final color = isDuplicate ? const Color(0xFFD97706) : (isHeader ? _subtext : _text);
    final style = TextStyle(
      color: color,
      fontSize: isHeader ? 9 : 11,
      fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
      letterSpacing: isHeader ? 0.5 : 0,
    );
    return Container(
      color: isDuplicate ? const Color(0xFFFFFBEB) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(col1, style: style, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(name, style: style, overflow: TextOverflow.ellipsis),
                ),
                if (isDuplicate) ...[
                  const SizedBox(width: 4),
                  const Text(
                    'dup',
                    style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(team, style: style, overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: 40,
            child: Text(trials, style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimingSessionCubit, TimingSessionState>(
      builder: (context, state) {
        final cubit = context.read<TimingSessionCubit>();
        final athletes = state.filteredAthletes;
        return Container(
          color: _bg,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _uploadZone(context, cubit),
                      const SizedBox(height: 12),
                      // Two quick-add options
                      Row(
                        children: [
                          Expanded(
                            child: _actionCard(
                              icon: Icons.group_add_outlined,
                              label: 'Select from Saved',
                              onTap: () => _showSelectFromSaved(context, cubit),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _actionCard(
                              icon: Icons.person_add_outlined,
                              label: 'Add Manually',
                              onTap: () => _showAddModal(context, cubit),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sessionListHeader(state, cubit),
                      const SizedBox(height: 10),
                      const SizedBox(height: 14),
                      if (state.athletes.isEmpty)
                        _emptyState()
                      else
                        _athleteList(athletes, cubit),
                    ],
                  ),
                ),
              ),
              _bottomNav(cubit),
            ],
          ),
        );
      },
    );
  }

  // ── Upload Zone ───────────────────────────────────────────────
  Widget _uploadZone(BuildContext context, TimingSessionCubit cubit) {
    return GestureDetector(
      onTap: _isUploading ? null : () => _pickAndParseFile(context, cubit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: _isUploading ? _primaryLight : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isUploading ? _primary : _border,
            width: _isUploading ? 1.5 : 1,
          ),
        ),
        child: _isUploading ? _uploadingState() : _uploadIdleState(),
      ),
    );
  }

  Widget _uploadIdleState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: _primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.upload_file, color: _primary, size: 28),
        ),
        const SizedBox(height: 10),
        const Text(
          'Upload Athlete File',
          style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap to select an Excel (.xlsx) or CSV file',
          style: TextStyle(color: _subtext, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _fileTag('XLS', const Color(0xFF1D6F42)),
            const SizedBox(width: 6),
            _fileTag('XLSX', const Color(0xFF1D6F42)),
            const SizedBox(width: 6),
            _fileTag('CSV', const Color(0xFF0064A5)),
          ],
        ),
      ],
    );
  }

  Widget _fileTag(String ext, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        ext,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _uploadingState() {
    return const Column(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(color: _primary, strokeWidth: 2),
        ),
        SizedBox(height: 10),
        Text('Reading file...', style: TextStyle(color: _primary, fontSize: 13)),
      ],
    );
  }

  // ── Action Card (Select from Saved / Add Manually) ────────────
  Widget _actionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _primary, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: _primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Session list header with search + team filter ─────────────
  Widget _sessionListHeader(TimingSessionState state, TimingSessionCubit cubit) {
    return Row(
      children: [
        Expanded(child: _searchField(state, cubit)),
        if (state.allTeams.isNotEmpty) ...[
          const SizedBox(width: 8),
          _teamFilter(state, cubit),
        ],
      ],
    );
  }

  // ── Select from Saved bottom sheet ────────────────────────────
  void _showSelectFromSaved(BuildContext context, TimingSessionCubit cubit) {
    final allSaved = sl<AthleteRepository>().getAll();

    if (allSaved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No saved athletes yet. Upload a file first.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SelectFromSavedSheet(
        allSaved: allSaved,
        alreadyInSession: cubit.state.athletes,
        onConfirm: (selected) {
          for (final a in selected) {
            cubit.addAthlete(a);
          }
        },
      ),
    );
  }

  Widget _searchField(TimingSessionState state, TimingSessionCubit cubit) {
    return TextField(
      onChanged: cubit.updateSearch,
      style: const TextStyle(color: _text, fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: _subtext, size: 18),
        hintText: 'Search athletes...',
        hintStyle: const TextStyle(color: _subtext, fontSize: 13),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _teamFilter(TimingSessionState state, TimingSessionCubit cubit) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.teamFilter.isEmpty ? null : state.teamFilter,
          hint: const Text('All Teams', style: TextStyle(color: _subtext, fontSize: 12)),
          dropdownColor: _surface,
          style: const TextStyle(color: _text, fontSize: 12),
          iconEnabledColor: _subtext,
          items: [
            const DropdownMenuItem(value: '', child: Text('All Teams')),
            ...state.allTeams.map(
              (t) => DropdownMenuItem(value: t, child: Text(t)),
            ),
          ],
          onChanged: (v) => cubit.updateTeamFilter(v ?? ''),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: const Column(
        children: [
          Icon(Icons.group_outlined, color: _subtext, size: 48),
          SizedBox(height: 12),
          Text(
            'No athletes added',
            style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Upload a file or tap Add above.',
            style: TextStyle(color: _subtext, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _athleteList(List<AthleteModel> athletes, TimingSessionCubit cubit) {
    return Column(
      children: athletes.map((a) {
        final subtitle = [
          if (a.athleteId.isNotEmpty) a.athleteId,
          if (a.bib.isNotEmpty) 'BIB: ${a.bib}',
          if (a.team.isNotEmpty) a.team,
        ].join(' · ');

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _primaryLight,
                child: Text(
                  a.initials,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.fullName,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(color: _subtext, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  _iconBtn(Icons.remove, () => cubit.changeTrials(a.id, -1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${a.trials}',
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _iconBtn(Icons.add, () => cubit.changeTrials(a.id, 1)),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => cubit.removeAthlete(a.id),
                child: const Icon(Icons.delete_outline, color: _error, size: 20),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _surface2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, color: _subtext, size: 14),
      ),
    );
  }

  Widget _bottomNav(TimingSessionCubit cubit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: cubit.prevStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: _subtext,
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Back'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: cubit.nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Next: Gate Setup',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Add Manually Modal ────────────────────────────────────────
  void _showAddModal(BuildContext context, TimingSessionCubit cubit) {
    final nameCtrl = TextEditingController();
    final athleteIdCtrl = TextEditingController();
    final bibCtrl = TextEditingController();
    final dobCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final disciplineCtrl = TextEditingController();
    final teamCtrl = TextEditingController();
    int trials = 3;
    String selectedSex = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Athlete',
                  style: TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _modalField('Full Name *', nameCtrl, hint: 'First Last'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _modalField('Athlete ID', athleteIdCtrl, hint: 'ATH-001'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _modalField('BIB', bibCtrl, hint: '42'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _modalField('Date of Birth', dobCtrl, hint: 'DD/MM/YYYY'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _modalField('Age', ageCtrl, hint: '22', isNumber: true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sex',
                            style: TextStyle(
                              color: _subtext,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: _surface2,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSex.isEmpty ? null : selectedSex,
                                hint: const Text(
                                  'Select',
                                  style: TextStyle(color: _subtext, fontSize: 13),
                                ),
                                isExpanded: true,
                                dropdownColor: _surface,
                                style: const TextStyle(color: _text, fontSize: 13),
                                items: ['Male', 'Female', 'Other']
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setModalState(() => selectedSex = v ?? ''),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _modalField('Discipline', disciplineCtrl, hint: 'Sprint'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _modalField('Team / Group', teamCtrl, hint: 'Sprint A'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Trials',
                      style: TextStyle(color: _subtext, fontSize: 11),
                    ),
                    const Spacer(),
                    _iconBtn(
                      Icons.remove,
                      () => setModalState(() => trials = (trials - 1).clamp(1, 10)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$trials',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _iconBtn(
                      Icons.add,
                      () => setModalState(() => trials = (trials + 1).clamp(1, 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final athlete = AthleteModel(
                          id: const Uuid().v4(),
                          fullName: nameCtrl.text.trim(),
                          athleteId: athleteIdCtrl.text.trim(),
                          bib: bibCtrl.text.trim(),
                          dob: dobCtrl.text.trim(),
                          age: int.tryParse(ageCtrl.text.trim()),
                          sex: selectedSex,
                          discipline: disciplineCtrl.text.trim(),
                          team: teamCtrl.text.trim(),
                          trials: trials,
                        );
                        cubit.addAthlete(athlete);
                        sl<AthleteRepository>().save(athlete);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add Athlete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modalField(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _subtext,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: _text, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _subtext, fontSize: 13),
            filled: true,
            fillColor: _surface2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Select from Saved Athletes — bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SelectFromSavedSheet extends StatefulWidget {
  const _SelectFromSavedSheet({
    required this.allSaved,
    required this.alreadyInSession,
    required this.onConfirm,
  });

  final List<AthleteModel> allSaved;
  final List<AthleteModel> alreadyInSession;
  final void Function(List<AthleteModel> selected) onConfirm;

  @override
  State<_SelectFromSavedSheet> createState() => _SelectFromSavedSheetState();
}

class _SelectFromSavedSheetState extends State<_SelectFromSavedSheet> {
  static const _primary = Color(0xFF1565C0);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _border = Color(0xFFDDE3EC);
  static const _surface = Color(0xFFFFFFFF);
  static const _surface2 = Color(0xFFF0F4F8);
  static const _primaryLight = Color(0xFFE3F2FD);

  String _search = '';
  final Set<String> _selectedIds = {};
  late List<AthleteModel> _available;

  @override
  void initState() {
    super.initState();
    // Exclude athletes already in session (by dedupeKey)
    final sessionKeys = widget.alreadyInSession
        .map((a) => a.athleteId.isNotEmpty
            ? a.athleteId.toLowerCase()
            : a.fullName.toLowerCase())
        .toSet();
    _available = widget.allSaved.where((a) {
      final key = a.athleteId.isNotEmpty
          ? a.athleteId.toLowerCase()
          : a.fullName.toLowerCase();
      return !sessionKeys.contains(key);
    }).toList();
  }

  List<AthleteModel> get _filtered {
    if (_search.isEmpty) return _available;
    final q = _search.toLowerCase();
    return _available.where((a) {
      return a.fullName.toLowerCase().contains(q) ||
          a.athleteId.toLowerCase().contains(q) ||
          a.team.toLowerCase().contains(q) ||
          a.bib.toLowerCase().contains(q);
    }).toList();
  }

  void _toggleAll() {
    setState(() {
      final filtered = _filtered;
      final allSelected =
          filtered.isNotEmpty && filtered.every((a) => _selectedIds.contains(a.id));
      if (allSelected) {
        for (final a in filtered) {
          _selectedIds.remove(a.id);
        }
      } else {
        for (final a in filtered) {
          _selectedIds.add(a.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selectedCount = _selectedIds.length;
    final allSelected =
        filtered.isNotEmpty && filtered.every((a) => _selectedIds.contains(a.id));

    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      height: MediaQuery.of(context).size.height * 0.80,
      child: Column(
        children: [
          // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Select Athletes',
                    style: TextStyle(
                      color: _text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_available.isNotEmpty)
                    TextButton(
                      onPressed: _toggleAll,
                      child: Text(
                        allSelected ? 'Deselect All' : 'Select All',
                        style: const TextStyle(
                            color: _primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: _text, fontSize: 13),
                decoration: InputDecoration(
                  prefixIcon:
                      const Icon(Icons.search, color: _subtext, size: 18),
                  hintText: 'Search by name, ID, team...',
                  hintStyle: const TextStyle(color: _subtext, fontSize: 13),
                  filled: true,
                  fillColor: _surface2,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primary, width: 1.5),
                  ),
                ),
              ),
            ),
            // List
            Expanded(
              child: _available.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_off_outlined,
                              color: _subtext, size: 40),
                          SizedBox(height: 10),
                          Text(
                            'All saved athletes are already\nin this session',
                            style: TextStyle(color: _subtext, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No athletes match your search',
                            style: TextStyle(color: _subtext, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: _border, height: 1),
                          itemBuilder: (_, i) {
                            final a = filtered[i];
                            final isSelected = _selectedIds.contains(a.id);
                            final subtitle = [
                              if (a.athleteId.isNotEmpty) a.athleteId,
                              if (a.bib.isNotEmpty) 'BIB: ${a.bib}',
                              if (a.team.isNotEmpty) a.team,
                            ].join(' · ');
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    isSelected ? _primary : _primaryLight,
                                child: Text(
                                  a.initials,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : _primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                a.fullName,
                                style: const TextStyle(
                                    color: _text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: subtitle.isNotEmpty
                                  ? Text(subtitle,
                                      style: const TextStyle(
                                          color: _subtext, fontSize: 11))
                                  : null,
                              trailing: Checkbox(
                                value: isSelected,
                                activeColor: _primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                onChanged: (_) => setState(() {
                                  if (isSelected) {
                                    _selectedIds.remove(a.id);
                                  } else {
                                    _selectedIds.add(a.id);
                                  }
                                }),
                              ),
                              onTap: () => setState(() {
                                if (isSelected) {
                                  _selectedIds.remove(a.id);
                                } else {
                                  _selectedIds.add(a.id);
                                }
                              }),
                            );
                          },
                        ),
            ),
            // Confirm button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: _surface,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedCount == 0
                      ? null
                      : () {
                          final selected = _available
                              .where((a) => _selectedIds.contains(a.id))
                              .toList();
                          widget.onConfirm(selected);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    disabledBackgroundColor: _border,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    selectedCount == 0
                        ? 'Select athletes to add'
                        : 'Add $selectedCount Athlete${selectedCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}
