// ══════════════════════════════════════════════════════════════════════════════
// session_pdf_service.dart
//
// SIKHNE KA GUIDE — PDF kaise banta hai Flutter mein:
//
// 1. PACKAGE: `pdf` (dart_pdf)
//    - Ye Flutter ke liye PDF banane ka library hai
//    - Iske saare widgets ka naam `pw` se shuru hota hai
//      (pw = PdfWidget) — Flutter ke `Widget` jaisa hi sochna
//    - pw.Column, pw.Row, pw.Text, pw.Table — bilkul Flutter jaisa!
//
// 2. PACKAGE: `printing`
//    - PDF ko share / download karne ke liye
//    - `Printing.sharePdf(bytes: ..., filename: ...)` ek share sheet
//      open karta hai — WhatsApp, Gmail, Files — sab mein bhej sako
//
// 3. COLORS:
//    - Flutter mein `Color(0xFF1565C0)` use hota hai
//    - PDF mein `PdfColor.fromHex('#1565C0')` use hota hai
//
// 4. SIZES:
//    - PDF mein sizes `points` mein hote hain (1 inch = 72 points)
//    - `PdfPageFormat.a4` standard A4 page hai
//    - `PdfPageFormat.a4.availableWidth` = page ki usable width
//
// 5. FLOW:
//    final doc = pw.Document();        // blank document banao
//    doc.addPage(pw.Page(...));         // page add karo
//    final bytes = await doc.save();   // bytes mein convert karo
//    Printing.sharePdf(bytes: bytes);  // share karo
//
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:io';     // File, Directory, Platform
import 'dart:typed_data'; // Uint8List

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart'; // getExternalStorageDirectory etc.
import 'package:pdf/pdf.dart';    // PdfColor, PdfPageFormat, PdfColors
import 'package:pdf/widgets.dart' as pw; // pw.Column, pw.Text, pw.Table etc.
import 'package:printing/printing.dart'; // Printing.sharePdf()
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/test_session_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/trial_result_model.dart';

class SessionPdfService {
  // ── App Colors (PDF format mein) ──────────────────────────────────────────
  // Flutter ka `Color(0xFF1565C0)` → PDF ka `PdfColor.fromHex('#1565C0')`
  static final _primaryColor   = PdfColor.fromHex('#1565C0');
  static final _primaryLight   = PdfColor.fromHex('#E3F2FD');
  static final _textColor      = PdfColor.fromHex('#1E2A3A');
  static final _subtextColor   = PdfColor.fromHex('#6B7A8D');
  static final _borderColor    = PdfColor.fromHex('#DDE3EC');
  static final _successColor   = PdfColor.fromHex('#16A34A');
  static final _goldColor      = PdfColor.fromHex('#D97706');
  static final _silverColor    = PdfColor.fromHex('#64748B');
  static final _bronzeColor    = PdfColor.fromHex('#92400E');
  static final _bgColor        = PdfColor.fromHex('#F4F6F9');
  static final _rowEvenColor   = PdfColor.fromHex('#F8FAFC');

  // ── Date Formatter ────────────────────────────────────────────────────────
  static final _dateFmt = DateFormat('dd MMM yyyy');

  // ══════════════════════════════════════════════════════════════════════════
  // _generateBytes — INTERNAL: PDF ka raw data (bytes) banao
  //
  // Ye private method dono public methods use karein:
  //   generateAndShare → bytes → Printing.sharePdf()
  //   saveToDevice     → bytes → File.writeAsBytes()
  //
  // Aise refactor kiya taaki PDF sirf ek jagah banta hai — DRY principle
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> _generateBytes(TestSessionModel session) async {
    // Blank document
    final doc = pw.Document();

    // Athletes fastest → slowest sort
    final ranked = [...session.results]
      ..sort((a, b) {
        final ab = a.bestTime, bb = b.bestTime;
        if (ab == null && bb == null) return 0;
        if (ab == null) return 1;
        if (bb == null) return -1;
        return ab.compareTo(bb);
      });

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        header: (context) => _buildHeader(session, context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSessionInfo(session),
          pw.SizedBox(height: 20),
          _buildLeaderboard(ranked),
          pw.SizedBox(height: 20),
          _buildDetailedResults(ranked, session),
        ],
      ),
    );

    // doc.save() → Uint8List (raw PDF bytes)
    return Uint8List.fromList(await doc.save());
  }

  // ── METHOD 1: Share PDF ───────────────────────────────────────────────────
  // Share sheet khulta hai — WhatsApp, Gmail, Files app — jahan bhi bhejo
  //
  static Future<void> generateAndShare({
    required TestSessionModel session,
  }) async {
    final bytes = await _generateBytes(session);

    // Printing.sharePdf = Android/iOS native share sheet
    await Printing.sharePdf(
      bytes: bytes,
      filename: _makeFilename(session),
    );
  }

  // ── METHOD 2: Save to Device ──────────────────────────────────────────────
  //
  // KAISE KAAM KARTA HAI:
  //   Android → External storage: /Android/data/com.xelec.xelex_esp/files/SportsIQ/
  //             (Files app mein "Internal Storage > Android > data > ... > files > SportsIQ")
  //   iOS     → App Documents folder
  //             (Files app mein "On My iPhone > xelex_esp > SportsIQ")
  //
  // RETURN: saved file ka full path (success pe), ya null (failure pe)
  //
  static Future<String?> saveToDevice({
    required TestSessionModel session,
  }) async {
    final bytes = await _generateBytes(session);

    // path_provider se storage directory lo
    // Platform.isAndroid check karo — har platform ka folder alag hota hai
    Directory? baseDir;
    if (Platform.isAndroid) {
      // getExternalStorageDirectory() = /storage/emulated/0/Android/data/<pkg>/files
      // Ye permission ke bina bhi kaam karta hai (app-specific external storage)
      baseDir = await getExternalStorageDirectory();
    } else {
      // iOS ke liye: Documents folder — Files app mein dikhta hai
      baseDir = await getApplicationDocumentsDirectory();
    }

    if (baseDir == null) return null;

    // 'SportsIQ' subfolder banao andar
    // Directory.create(recursive: true) = folders chain bana deta hai agar na ho
    final folder = Directory('${baseDir.path}/SportsIQ');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    // File object banao aur bytes likh do
    final file = File('${folder.path}/${_makeFilename(session)}');
    await file.writeAsBytes(bytes);

    // Full path return karo — screen pe snackbar mein dikhayenge
    return file.path;
  }

  // ── FILENAME ──────────────────────────────────────────────────────────────
  // e.g. "SportsIQ_SummerSprint_20260315.pdf"
  static String _makeFilename(TestSessionModel s) {
    final name = s.sessionName
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w_]'), '');
    final date = DateFormat('yyyyMMdd').format(s.date);
    return 'SportsIQ_${name}_$date.pdf';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER — Har page ke upar
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _buildHeader(
    TestSessionModel session,
    pw.Context context,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // App name + "Session Report" ek hi row mein
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // App name — bold blue
            pw.Text(
              'Sports IQ',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            // Generated date — right side
            pw.Text(
              'Generated: ${_dateFmt.format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 9, color: _subtextColor),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        // Session name (subtitle)
        pw.Text(
          'Session Report — ${session.sessionName}',
          style: pw.TextStyle(
            fontSize: 11,
            color: _subtextColor,
          ),
        ),
        pw.SizedBox(height: 8),
        // Divider line
        pw.Divider(color: _primaryColor, thickness: 1.5),
        pw.SizedBox(height: 4),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FOOTER — Har page ke neeche (page number)
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: _borderColor),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Sports IQ — Timing Report',
              style: pw.TextStyle(fontSize: 8, color: _subtextColor),
            ),
            // `context.pageNumber` current page, `context.pagesCount` total pages
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: _subtextColor),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SESSION INFO — Date, mode, location etc.
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _buildSessionInfo(TestSessionModel s) {
    // _infoRow: ek helper jo "Label: Value" row banata hai
    pw.Widget infoRow(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 110,
                child: pw.Text(
                  label,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _subtextColor,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
            ],
          ),
        );

    // Completion stats
    final completed = s.results.fold<int>(
        0, (sum, r) => sum + r.completedTrials.length);
    final total = s.athletes.length * s.trialsCount;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _bgColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SESSION DETAILS',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 8),
          // 2-column grid of info rows
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    infoRow('Date', _dateFmt.format(s.date)),
                    infoRow('Mode', s.modeLabel),
                    infoRow('Athletes', '${s.athletes.length}'),
                    infoRow('Trials each', '${s.trialsCount}'),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    infoRow('Location', s.location.isEmpty ? '—' : s.location),
                    infoRow('Trial order',
                        s.trialMode == 'round_robin' ? 'Round robin' : 'Athlete complete'),
                    infoRow('Completed', '$completed / $total trials'),
                    infoRow('Status', _capitalize(s.status)),
                  ],
                ),
              ),
            ],
          ),
          if (s.notes.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Divider(color: _borderColor),
            pw.SizedBox(height: 4),
            infoRow('Notes', s.notes),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LEADERBOARD TABLE
  // ══════════════════════════════════════════════════════════════════════════
  //
  // pw.Table kaise kaam karta hai:
  //   pw.Table(
  //     children: [
  //       pw.TableRow(children: [cell1, cell2, cell3]),  // row 1
  //       pw.TableRow(children: [cell1, cell2, cell3]),  // row 2
  //     ],
  //   )
  //
  static pw.Widget _buildLeaderboard(List<AthleteResultModel> ranked) {
    // ── Medal colors for top 3 ──────────────────────────────────────────────
    PdfColor rankColor(int rank) {
      if (rank == 1) return _goldColor;
      if (rank == 2) return _silverColor;
      if (rank == 3) return _bronzeColor;
      return _textColor;
    }

    // ── Helper: ek table cell banao ────────────────────────────────────────
    pw.Widget cell(
      String text, {
      bool bold = false,
      PdfColor? color,
      pw.Alignment align = pw.Alignment.centerLeft,
      double fontSize = 9.5,
    }) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Align(
            alignment: align,
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? _textColor,
              ),
            ),
          ),
        );

    // ── Header row ─────────────────────────────────────────────────────────
    pw.TableRow headerRow() => pw.TableRow(
          decoration: pw.BoxDecoration(color: _primaryColor),
          children: [
            cell('#', bold: true, color: PdfColors.white, align: pw.Alignment.center),
            cell('Athlete', bold: true, color: PdfColors.white),
            cell('Team', bold: true, color: PdfColors.white),
            cell('Best Time', bold: true, color: PdfColors.white, align: pw.Alignment.center),
            cell('Avg Time', bold: true, color: PdfColors.white, align: pw.Alignment.center),
            cell('Trials', bold: true, color: PdfColors.white, align: pw.Alignment.center),
          ],
        );

    // ── Data rows (alternating background) ─────────────────────────────────
    List<pw.TableRow> dataRows() => ranked.asMap().entries.map((e) {
          final rank = e.key + 1;
          final r = e.value;
          final isEven = rank % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? _rowEvenColor : PdfColors.white,
            ),
            children: [
              // Rank number
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Container(
                    width: 20,
                    height: 20,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: rank <= 3
                          ? rankColor(rank).shade(0.15)
                          : _bgColor,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '$rank',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: rankColor(rank),
                      ),
                    ),
                  ),
                ),
              ),
              cell(r.fullName, bold: rank <= 3, color: rankColor(rank)),
              cell(r.team.isEmpty ? '—' : r.team),
              cell(
                r.bestTime != null ? '${r.bestTime!.toStringAsFixed(3)}s' : '—',
                bold: true,
                color: rankColor(rank),
                align: pw.Alignment.center,
              ),
              cell(
                r.avgTime != null ? '${r.avgTime!.toStringAsFixed(3)}s' : '—',
                align: pw.Alignment.center,
              ),
              cell(
                '${r.completedTrials.length}',
                align: pw.Alignment.center,
              ),
            ],
          );
        }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('RESULTS LEADERBOARD'),
        pw.SizedBox(height: 8),
        // pw.Table mein columnWidths se column ki width fix karo
        pw.Table(
          border: pw.TableBorder.all(color: _borderColor, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(32),   // Rank
            1: const pw.FlexColumnWidth(3),     // Name (flexible)
            2: const pw.FlexColumnWidth(2),     // Team
            3: const pw.FixedColumnWidth(72),   // Best time
            4: const pw.FixedColumnWidth(72),   // Avg time
            5: const pw.FixedColumnWidth(42),   // Trials
          },
          children: [headerRow(), ...dataRows()],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DETAILED RESULTS — Har athlete ki individual trial times
  // ══════════════════════════════════════════════════════════════════════════
  static pw.Widget _buildDetailedResults(
    List<AthleteResultModel> ranked,
    TestSessionModel session,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('DETAILED TRIAL RESULTS'),
        pw.SizedBox(height: 8),
        ...ranked.map((r) => _buildAthleteCard(r, session.trialsCount)),
      ],
    );
  }

  static pw.Widget _buildAthleteCard(
    AthleteResultModel r,
    int trialsCount,
  ) {
    // ── Trial status label ──────────────────────────────────────────────────
    String statusLabel(TrialResultModel t) {
      if (t.isCompleted) return '${t.totalTime!.toStringAsFixed(3)}s';
      if (t.isFalseStart) return 'FS';
      if (t.isSkipped) return 'Skip';
      return '—';
    }

    PdfColor statusColor(TrialResultModel t) {
      if (t.isCompleted) return _textColor;
      if (t.isFalseStart) return PdfColors.red700;
      if (t.isSkipped) return _subtextColor;
      return _subtextColor;
    }

    // ── Build header: name + bib + team ────────────────────────────────────
    final bibText = r.bib.isNotEmpty ? '  ·  BIB: ${r.bib}' : '';
    final teamText = r.team.isNotEmpty ? '  ·  ${r.team}' : '';
    final laneText = r.shuttleLane != null ? '  ·  Lane ${r.shuttleLane}' : '';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      // pw.Container = Flutter ke Container jaisa (background, border etc.)
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _borderColor),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Athlete name bar ──────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: pw.BoxDecoration(
                color: _primaryLight,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(6),
                  topRight: pw.Radius.circular(6),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    r.fullName,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  pw.Text(
                    '$bibText$teamText$laneText'.trimLeft().replaceFirst('  ·  ', ''),
                    style: pw.TextStyle(fontSize: 9, color: _subtextColor),
                  ),
                ],
              ),
            ),

            // ── Trial times table ─────────────────────────────────────────
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Table(
                border: pw.TableBorder.all(color: _borderColor, width: 0.5),
                columnWidths: {
                  // First col = "Trial" label, rest = trial numbers (equal)
                  0: const pw.FixedColumnWidth(55),
                  for (int i = 1; i <= trialsCount; i++)
                    i: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header row: Trial # 1 | # 2 | # 3 ...
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: _bgColor),
                    children: [
                      _tCell('Trial', isHeader: true),
                      for (int i = 1; i <= trialsCount; i++)
                        _tCell('# $i', isHeader: true, center: true),
                    ],
                  ),
                  // Time row
                  pw.TableRow(
                    children: [
                      _tCell('Time', isHeader: true),
                      for (int i = 1; i <= trialsCount; i++) ...[
                        () {
                          final t = r.trials.where((t) => t.trialNumber == i).firstOrNull;
                          if (t == null) return _tCell('—', center: true, color: _subtextColor);
                          return _tCell(
                            statusLabel(t),
                            center: true,
                            bold: t.isCompleted,
                            color: statusColor(t),
                          );
                        }(),
                      ],
                    ],
                  ),
                  // Splits row (only if any trial has splits)
                  if (r.trials.any((t) => t.splits.isNotEmpty))
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: _rowEvenColor),
                      children: [
                        _tCell('Splits', isHeader: true),
                        for (int i = 1; i <= trialsCount; i++) ...[
                          () {
                            final t = r.trials
                                .where((t) => t.trialNumber == i)
                                .firstOrNull;
                            if (t == null || t.splits.isEmpty) {
                              return _tCell('—', center: true, color: _subtextColor);
                            }
                            final splitsStr =
                                t.splits.map((s) => s.toStringAsFixed(2)).join(' | ');
                            return _tCell(splitsStr, center: true, color: _subtextColor);
                          }(),
                        ],
                      ],
                    ),
                ],
              ),
            ),

            // ── Summary: Best + Avg ───────────────────────────────────────
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: pw.Row(
                children: [
                  if (r.bestTime != null)
                    _statBadge('Best', '${r.bestTime!.toStringAsFixed(3)}s', _successColor),
                  pw.SizedBox(width: 10),
                  if (r.avgTime != null)
                    _statBadge('Avg', '${r.avgTime!.toStringAsFixed(3)}s', _primaryColor),
                  pw.SizedBox(width: 10),
                  _statBadge(
                    'Completed',
                    '${r.completedTrials.length} / ${r.trials.length}',
                    _subtextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Table cell helper ─────────────────────────────────────────────────────
  static pw.Widget _tCell(
    String text, {
    bool isHeader = false,
    bool center = false,
    bool bold = false,
    PdfColor? color,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Align(
          alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: (isHeader || bold) ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? (isHeader ? _subtextColor : _textColor),
            ),
          ),
        ),
      );

  // ── Small colored badge: "Best  3.142s" ──────────────────────────────────
  static pw.Widget _statBadge(String label, String value, PdfColor color) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: color.shade(0.1),
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: color.shade(0.3)),
        ),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label  ',
                style: pw.TextStyle(fontSize: 8, color: _subtextColor),
              ),
              pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );

  // ── Section Title (LEADERBOARD, DETAILED RESULTS etc.) ───────────────────
  static pw.Widget _sectionTitle(String title) => pw.Row(
        children: [
          pw.Container(width: 4, height: 14, color: _primaryColor),
          pw.SizedBox(width: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      );

  // ── Capitalize first letter ───────────────────────────────────────────────
  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
