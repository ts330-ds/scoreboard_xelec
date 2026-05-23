import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/profile/data/model/timing_gate_profile_model.dart';
import 'package:xelex_esp/feature/timing_gates/profile/presentation/cubit/profile_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/profile/presentation/cubit/profile_state.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/test_session_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/trial_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/service/session_pdf_service.dart';

// ── Color constants (shared with screen file) ─────────────────────────────────
const Color sdBg           = Color(0xFFF4F6F9);
const Color sdSurface      = Color(0xFFFFFFFF);
const Color sdPrimary      = Color(0xFF1565C0);
const Color sdPrimaryLight = Color(0xFFE3F2FD);
const Color sdText         = Color(0xFF1E2A3A);
const Color sdSubtext      = Color(0xFF6B7A8D);
const Color sdBorder       = Color(0xFFDDE3EC);
const Color sdSuccess      = Color(0xFF16A34A);
const Color sdGold         = Color(0xFFD97706);
const Color sdSilver       = Color(0xFF64748B);
const Color sdBronze       = Color(0xFF92400E);

// ── Segment label helper ──────────────────────────────────────────────────────
/// Builds ordered segment labels from [gateDistances], skipping any segment
/// whose distance is 0 (e.g. M→G1=0 when athlete starts at G1).
/// Falls back to positional labels when [gateDistances] is empty.
List<String> _buildSegmentLabels(
  List<double> gateDistances,
  int segCount, {
  bool startFromMaster = true,
}) {
  if (!startFromMaster) {
    // Shuttle: athlete bounces G1↔G2↔G1↔G2...
    return List.generate(
      segCount,
      (i) => i % 2 == 0 ? 'G1→G2' : 'G2→G1',
    );
  }
  if (gateDistances.length >= 2) {
    final labels = <String>[];
    for (int i = 0; i < gateDistances.length - 1; i++) {
      if (gateDistances[i + 1] <= 0) continue;
      labels.add(i == 0 ? 'M→G1' : 'G$i→G${i + 1}');
    }
    if (labels.length == segCount) return labels;
  }
  return List.generate(
    segCount,
    (i) => i == 0 ? 'M→G1' : 'G$i→G${i + 1}',
  );
}

// ── YoYo helpers ─────────────────────────────────────────────────────────────

/// Best (highest) YoYo level for [r] — reads ALL trials whose status is
/// 'completed' OR 'eliminated' because eliminated athletes fail [isCompleted].
double? yoyoLevel(AthleteResultModel r) {
  final levels = r.trials
      .where((t) =>
          t.totalTime != null &&
          (t.status == 'completed' || t.status == 'eliminated'))
      .map((t) => t.totalTime!)
      .toList();
  if (levels.isEmpty) return null;
  return levels.reduce((a, b) => a > b ? a : b);
}

/// True if any of [r]'s trials was marked 'eliminated' (YoYo-specific).
bool isYoyoEliminated(AthleteResultModel r) =>
    r.trials.any((t) => t.status == 'eliminated');

// ── Header ────────────────────────────────────────────────────────────────────

class SessionDetailHeader extends StatelessWidget {
  final String sessionName;
  final VoidCallback onBack;
  final VoidCallback onPdf;

  const SessionDetailHeader({
    super.key,
    required this.sessionName,
    required this.onBack,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: sdSurface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: sdText, size: 20),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              sessionName,
              style: const TextStyle(
                  color: sdText, fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'PDF Report',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: sdPrimaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf_outlined,
                  color: sdPrimary, size: 20),
            ),
            onPressed: onPdf,
          ),
        ],
      ),
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class SessionDetailTabBar extends StatelessWidget {
  final TabController tabs;

  const SessionDetailTabBar({super.key, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: sdSurface,
        border: Border(bottom: BorderSide(color: sdBorder)),
      ),
      child: TabBar(
        controller: tabs,
        labelColor: sdPrimary,
        unselectedLabelColor: sdSubtext,
        indicatorColor: sdPrimary,
        indicatorWeight: 2.5,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Leaderboard'),
          Tab(text: 'Charts'),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class OverviewTab extends StatelessWidget {
  final TestSessionModel session;
  final List<AthleteResultModel> ranked;

  const OverviewTab({super.key, required this.session, required this.ranked});

  @override
  Widget build(BuildContext context) {
    final isYoyo = session.isYoyo;
    final allBest = isYoyo
        ? ranked.map((r) => yoyoLevel(r)).where((v) => v != null).cast<double>().toList()
        : ranked.map((r) => r.bestTime).where((t) => t != null).cast<double>().toList();
    final overallBest = allBest.isEmpty
        ? null
        : isYoyo
            ? allBest.reduce((a, b) => a > b ? a : b) // highest level = best
            : allBest.reduce((a, b) => a < b ? a : b); // lowest time = best
    final winner = ranked.isNotEmpty ? ranked.first : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: SdStatCard(
                label: 'Top Athlete',
                value: winner?.fullName.split(' ').first ?? '—',
                icon: Icons.star_outline,
                color: sdGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SdStatCard(
                label: isYoyo ? 'Best Level' : 'Best Time',
                value: overallBest != null
                    ? isYoyo
                        ? 'Lv ${overallBest.toStringAsFixed(1)}'
                        : '${overallBest.toStringAsFixed(3)}s'
                    : '—',
                icon: Icons.emoji_events_outlined,
                color: sdGold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        SdCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SdSectionTitle('Session Details'),
              const SizedBox(height: 12),
              SdInfoRow(Icons.calendar_today_outlined, 'Date',
                  sdFormatDate(session.completedAt ?? session.date)),
              SdInfoRow(Icons.timer_outlined, 'Mode', session.modeLabel),
              SdInfoRow(Icons.people_outline, 'Athletes',
                  '${session.athletes.length}'),
              SdInfoRow(Icons.repeat, 'Trials per athlete',
                  '${session.trialsCount}'),
              SdInfoRow(Icons.sort, 'Trial order',
                  session.trialMode == 'round_robin'
                      ? 'Round Robin'
                      : 'Athlete Complete'),
              if (session.location.isNotEmpty)
                SdInfoRow(Icons.location_on_outlined, 'Location',
                    session.location),
              if (session.notes.isNotEmpty)
                SdInfoRow(Icons.notes_outlined, 'Notes', session.notes),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (ranked.isNotEmpty)
          SdCard(child: PodiumSection(ranked: ranked, isYoyo: isYoyo)),
      ],
    );
  }
}

// ── Podium Section ────────────────────────────────────────────────────────────

class PodiumSection extends StatelessWidget {
  final List<AthleteResultModel> ranked;
  final bool isYoyo;

  const PodiumSection({super.key, required this.ranked, this.isYoyo = false});

  @override
  Widget build(BuildContext context) {
    final top = ranked.take(3).toList();
    final podiumOrder = <int>[];
    if (top.length >= 2) podiumOrder.add(1);
    podiumOrder.add(0);
    if (top.length >= 3) podiumOrder.add(2);

    const heights = [80.0, 100.0, 65.0];
    const colors = [sdSilver, sdGold, sdBronze];
    const labels = ['2nd', '1st', '3rd'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SdSectionTitle('Podium'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: podiumOrder.map((i) {
            if (i >= top.length) return const SizedBox(width: 90);
            final athlete = top[i];
            final displayIdx = podiumOrder.indexOf(i);
            return Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors[displayIdx].withAlpha(30),
                    child: Text(
                      athlete.fullName[0].toUpperCase(),
                      style: TextStyle(
                          color: colors[displayIdx],
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    athlete.fullName.split(' ').first,
                    style: const TextStyle(
                        color: sdText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isYoyo
                        ? (yoyoLevel(athlete) != null
                            ? 'Lv ${yoyoLevel(athlete)!.toStringAsFixed(1)}'
                            : '—')
                        : (athlete.bestTime != null
                            ? '${athlete.bestTime!.toStringAsFixed(3)}s'
                            : '—'),
                    style: TextStyle(
                        color: colors[displayIdx],
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: heights[displayIdx],
                    decoration: BoxDecoration(
                      color: colors[displayIdx].withAlpha(30),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                      border:
                          Border.all(color: colors[displayIdx].withAlpha(80)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[displayIdx],
                      style: TextStyle(
                          color: colors[displayIdx],
                          fontWeight: FontWeight.w800,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Leaderboard Tab ───────────────────────────────────────────────────────────

class LeaderboardTab extends StatelessWidget {
  final List<AthleteResultModel> ranked;
  final List<double> gateDistances;
  final bool isYoyo;
  final bool isShuttle;

  const LeaderboardTab({
    super.key,
    required this.ranked,
    this.gateDistances = const [],
    this.isYoyo = false,
    this.isShuttle = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ranked.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AthleteDetailCard(
          result: ranked[i],
          rank: i + 1,
          gateDistances: gateDistances,
          isYoyo: isYoyo,
          isShuttle: isShuttle,
        ),
      ),
    );
  }
}

// ── Athlete Detail Card ───────────────────────────────────────────────────────

class AthleteDetailCard extends StatelessWidget {
  final AthleteResultModel result;
  final int rank;
  final List<double> gateDistances;
  final bool isYoyo;
  final bool isShuttle;

  const AthleteDetailCard({
    super.key,
    required this.result,
    required this.rank,
    this.gateDistances = const [],
    this.isYoyo = false,
    this.isShuttle = false,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? sdGold
        : rank == 2
            ? sdSilver
            : rank == 3
                ? sdBronze
                : sdSubtext;

    // ── YoYo-specific computed values ─────────────────────────────────────────
    final lvl = isYoyo ? yoyoLevel(result) : null;
    final elim = isYoyo && isYoyoEliminated(result);

    // YoYo: include completed + eliminated trials; Sprint: completed + skipped + false-start
    final allTrials = isYoyo
        ? (result.trials
            .where((t) => t.status == 'completed' || t.status == 'eliminated')
            .toList()
          ..sort((a, b) => a.trialNumber.compareTo(b.trialNumber)))
        : (result.trials
            .where((t) => t.isCompleted || t.isSkipped || t.isFalseStart)
            .toList()
          ..sort((a, b) => a.trialNumber.compareTo(b.trialNumber)));

    final completedTrials = result.completedTrials; // sprint only

    // Sprint speed stats
    final bestPeakSpeed = isYoyo
        ? null
        : completedTrials
            .where((t) => t.peakSpeed != null)
            .map((t) => t.peakSpeed!)
            .fold<double?>(null, (best, v) => best == null || v > best ? v : best);
    final totalDist = gateDistances.fold(0.0, (s, d) => s + d);
    final double? avgSpeed = (!isYoyo && totalDist > 0 && result.bestTime != null && result.bestTime! > 0)
        ? totalDist / result.bestTime!
        : null;
    final hasSpeedStats = bestPeakSpeed != null || avgSpeed != null;

    // Whether there is any displayable data at all
    final hasData = isYoyo ? allTrials.isNotEmpty : completedTrials.isNotEmpty;

    return SdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Athlete header ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Text('$rank',
                    style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundColor: elim
                    ? const Color(0xFFFCA5A5)
                    : sdPrimaryLight,
                child: Text(
                  result.fullName.isNotEmpty
                      ? result.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: elim ? const Color(0xFFDC2626) : sdPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.fullName,
                        style: const TextStyle(
                            color: sdText,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    if (result.team.isNotEmpty)
                      Text(result.team,
                          style: const TextStyle(color: sdSubtext, fontSize: 11)),
                  ],
                ),
              ),
              // ── Right-side score ────────────────────────────────────────────
              if (isYoyo)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lvl != null ? 'Lv ${lvl.toStringAsFixed(1)}' : '—',
                      style: TextStyle(
                          color: rank == 1
                              ? sdGold
                              : elim
                                  ? const Color(0xFFDC2626)
                                  : sdPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17),
                    ),
                    Text(
                      elim ? 'Eliminated' : 'Survived',
                      style: TextStyle(
                          color: elim ? const Color(0xFFDC2626) : sdSuccess,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              else if (result.bestTime != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${result.bestTime!.toStringAsFixed(3)}s',
                      style: TextStyle(
                          color: rank == 1 ? sdGold : sdPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17),
                    ),
                    const Text('best',
                        style: TextStyle(color: sdSubtext, fontSize: 10)),
                  ],
                ),
            ],
          ),

          if (hasData) ...[
            const SizedBox(height: 14),
            const Divider(color: sdBorder, height: 1),
            const SizedBox(height: 10),

            if (isYoyo) ...[
              // ── YoYo stats row ──────────────────────────────────────────────
              Row(
                children: [
                  SdMiniStat(
                    label: 'Status',
                    value: elim ? 'Eliminated' : 'Survived',
                    color: elim ? const Color(0xFFDC2626) : sdSuccess,
                  ),
                  const SdVDivider(),
                  SdMiniStat(
                    label: 'Best Level',
                    value: lvl != null ? 'Lv ${lvl.toStringAsFixed(1)}' : '—',
                    color: sdPrimary,
                  ),
                  const SdVDivider(),
                  SdMiniStat(
                    label: 'Runs',
                    value: '${allTrials.length}',
                  ),
                ],
              ),
              // ── Strike summary ──────────────────────────────────────────────
              () {
                // Pull strike levels from the first trial that has them
                final strikeSource = allTrials.cast<TrialResultModel?>().firstWhere(
                      (t) => t!.firstStrikeLevel != null || t.secondStrikeLevel != null,
                      orElse: () => null,
                    );
                if (strikeSource == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFD97706), size: 14),
                        const SizedBox(width: 6),
                        const Text('Strikes:',
                            style: TextStyle(
                                color: sdSubtext,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        _StrikeChip(number: 1, level: strikeSource.firstStrikeLevel),
                        if (strikeSource.secondStrikeLevel != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              color: sdSubtext, size: 12),
                          const SizedBox(width: 8),
                          _StrikeChip(
                              number: 2,
                              level: strikeSource.secondStrikeLevel,
                              isFinal: true),
                        ],
                      ],
                    ),
                  ),
                );
              }(),
            ] else ...[
              // ── Sprint time stats row ───────────────────────────────────────
              Row(
                children: [
                  SdMiniStat(label: 'Trials', value: '${completedTrials.length}'),
                  const SdVDivider(),
                  SdMiniStat(
                      label: 'Best',
                      value: '${result.bestTime!.toStringAsFixed(3)}s'),
                  const SdVDivider(),
                  if (result.avgTime != null) ...[
                    SdMiniStat(
                        label: 'Avg',
                        value: '${result.avgTime!.toStringAsFixed(3)}s'),
                    const SdVDivider(),
                  ],
                  SdMiniStat(
                    label: 'Worst',
                    value: () {
                      final times = completedTrials.map((t) => t.totalTime!).toList();
                      return '${times.reduce((a, b) => a > b ? a : b).toStringAsFixed(3)}s';
                    }(),
                  ),
                ],
              ),

              // ── Sprint speed stats row ──────────────────────────────────────
              if (hasSpeedStats) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (bestPeakSpeed != null) ...[
                      SdMiniStat(
                        label: 'Peak Speed',
                        value: '${bestPeakSpeed.toStringAsFixed(2)} m/s',
                        sub: '${(bestPeakSpeed * 3.6).toStringAsFixed(1)} km/h',
                        color: sdPrimary,
                      ),
                    ],
                    if (bestPeakSpeed != null && avgSpeed != null)
                      const SdVDivider(),
                    if (avgSpeed != null)
                      SdMiniStat(
                        label: 'Avg Speed',
                        value: '${avgSpeed.toStringAsFixed(2)} m/s',
                        sub: '${(avgSpeed * 3.6).toStringAsFixed(1)} km/h',
                        color: const Color(0xFF7C3AED),
                      ),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 12),
            ...allTrials.map((t) => TrialRow(
                  trial: t,
                  result: result,
                  gateDistances: gateDistances,
                  isYoyo: isYoyo,
                  isShuttle: isShuttle,
                )),
          ],
        ],
      ),
    );
  }
}

// ── Trial Row ─────────────────────────────────────────────────────────────────

class TrialRow extends StatefulWidget {
  final TrialResultModel trial;
  final AthleteResultModel result;
  final List<double> gateDistances;
  final bool isYoyo;
  final bool isShuttle;

  const TrialRow({
    super.key,
    required this.trial,
    required this.result,
    this.gateDistances = const [],
    this.isYoyo = false,
    this.isShuttle = false,
  });

  @override
  State<TrialRow> createState() => _TrialRowState();
}

class _TrialRowState extends State<TrialRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.trial;
    final result = widget.result;
    final gateDistances = widget.gateDistances;
    final isYoyo = widget.isYoyo;

    // ── YoYo row ──────────────────────────────────────────────────────────────
    if (isYoyo) {
      final eliminated = t.status == 'eliminated';
      final hasLevel = t.totalTime != null;
      final level = t.totalTime;

      // Highlight the best (highest) level trial
      final allLevels = result.trials
          .where((x) => x.totalTime != null && (x.status == 'completed' || x.status == 'eliminated'))
          .map((x) => x.totalTime!)
          .toList();
      final bestLevel = allLevels.isEmpty ? null : allLevels.reduce((a, b) => a > b ? a : b);
      final isBestYoyo = hasLevel && bestLevel != null && level == bestLevel;

      final accent = isBestYoyo ? sdGold : (eliminated ? const Color(0xFFDC2626) : sdPrimary);
      final accentLight = isBestYoyo
          ? sdGold.withAlpha(20)
          : eliminated
              ? const Color(0xFFFCA5A5)
              : sdPrimaryLight;
      final accentBorder = isBestYoyo
          ? sdGold.withAlpha(80)
          : eliminated
              ? const Color(0xFFFCA5A5)
              : sdBorder;

      final hasStrikes = t.firstStrikeLevel != null || t.secondStrikeLevel != null;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isBestYoyo ? sdGold.withAlpha(10) : (eliminated ? const Color(0xFFFEF2F2) : sdSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main row ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Run badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentLight,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('Run ${t.trialNumber}',
                        style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  // Best badge
                  if (isBestYoyo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: sdGold.withAlpha(20),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: sdGold, size: 11),
                          SizedBox(width: 3),
                          Text('Best', style: TextStyle(color: sdGold, fontSize: 10, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: eliminated ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      eliminated ? 'Eliminated' : 'Survived',
                      style: TextStyle(
                          color: eliminated ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Level value
                  if (hasLevel) ...[
                    Text('Lv ', style: const TextStyle(color: sdSubtext, fontSize: 10)),
                    Text(
                      level!.toStringAsFixed(1),
                      style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ] else
                    const Text('—', style: TextStyle(color: sdSubtext, fontSize: 14)),
                ],
              ),
            ),

            // ── Strike timeline ───────────────────────────────────────────────
            if (hasStrikes) ...[
              const Divider(height: 1, color: Color(0xFFFFE4E4)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626), size: 13),
                    const SizedBox(width: 5),
                    const Text('Strikes:',
                        style: TextStyle(
                            color: sdSubtext, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    // Strike 1
                    _StrikeChip(
                      number: 1,
                      level: t.firstStrikeLevel,
                    ),
                    if (t.secondStrikeLevel != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          color: sdSubtext, size: 12),
                      const SizedBox(width: 8),
                      // Strike 2
                      _StrikeChip(
                        number: 2,
                        level: t.secondStrikeLevel,
                        isFinal: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    // ── Sprint row (original logic) ───────────────────────────────────────────
    final isBest = t.isCompleted &&
        t.totalTime != null &&
        result.bestTime != null &&
        t.totalTime == result.bestTime;

    final hasSpeedData = t.isCompleted && t.speeds.isNotEmpty;
    final segCount = t.speeds.isNotEmpty ? t.speeds.length : t.splits.length;
    final segLabels = _buildSegmentLabels(gateDistances, segCount, startFromMaster: !widget.isShuttle);

    // Average speed = total distance / total time
    double? avgSpeed;
    if (t.isCompleted && t.totalTime != null && t.totalTime! > 0) {
      final totalDist = gateDistances.fold(0.0, (s, d) => s + d);
      if (totalDist > 0) {
        avgSpeed = totalDist / t.totalTime!;
      } else if (t.speeds.isNotEmpty) {
        avgSpeed = t.speeds.fold(0.0, (s, v) => s + v) / t.speeds.length;
      }
    }

    final accent = isBest ? sdGold : sdPrimary;
    final accentLight = isBest ? sdGold.withAlpha(20) : sdPrimaryLight;
    final accentBorder = isBest ? sdGold.withAlpha(80) : sdBorder;
    final hasSegments = t.splits.isNotEmpty || hasSpeedData;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isBest ? sdGold.withAlpha(10) : sdSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tappable header ─────────────────────────────────────────────────
          InkWell(
            onTap: hasSegments ? () => setState(() => _expanded = !_expanded) : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                children: [
                  // Trial badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentLight,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('T${t.trialNumber}',
                        style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  // Best badge
                  if (isBest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: sdGold.withAlpha(20),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: sdGold, size: 11),
                          SizedBox(width: 3),
                          Text('Best', style: TextStyle(color: sdGold, fontSize: 10, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Non-completed label
                  if (!t.isCompleted)
                    Text(
                      t.isSkipped ? 'Skipped' : 'False Start',
                      style: TextStyle(
                          color: t.isSkipped ? sdSubtext : const Color(0xFFDC2626),
                          fontSize: 11,
                          fontStyle: FontStyle.italic),
                    ),
                  // Total time
                  if (t.isCompleted && t.totalTime != null) ...[
                    Text('Total', style: const TextStyle(color: sdSubtext, fontSize: 10)),
                    const SizedBox(width: 5),
                    Text(
                      '${t.totalTime!.toStringAsFixed(3)}s',
                      style: TextStyle(
                          color: accent, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ],
                  // Expand/collapse chevron
                  if (hasSegments) ...[
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: sdSubtext, size: 18),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (t.isCompleted) ...[
            // ── Peak chips — always visible ────────────────────────────────
            if (hasSpeedData) ...[
              const Divider(height: 1, color: sdBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Row(
                  children: [
                    _PeakChip(
                      icon: Icons.speed_rounded,
                      label: 'Peak Speed',
                      value: t.peakSpeed != null
                          ? '${t.peakSpeed!.toStringAsFixed(2)} m/s'
                          : '--',
                      sub: t.peakSpeed != null
                          ? '${(t.peakSpeed! * 3.6).toStringAsFixed(1)} km/h'
                          : '',
                      color: sdPrimary,
                    ),
                    const SizedBox(width: 6),
                    _PeakChip(
                      icon: Icons.directions_run_rounded,
                      label: 'Avg Speed',
                      value: avgSpeed != null
                          ? '${avgSpeed.toStringAsFixed(2)} m/s'
                          : '--',
                      sub: avgSpeed != null
                          ? '${(avgSpeed * 3.6).toStringAsFixed(1)} km/h'
                          : '',
                      color: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 6),
                    _PeakChip(
                      icon: Icons.trending_up_rounded,
                      label: 'Peak Accel',
                      value: t.peakAcceleration != null
                          ? '${t.peakAcceleration! >= 0 ? '+' : ''}${t.peakAcceleration!.toStringAsFixed(2)} m/s²'
                          : '--',
                      sub: t.peakAcceleration != null
                          ? (t.peakAcceleration! >= 0 ? 'Accelerating' : 'Decelerating')
                          : '',
                      color: t.peakAcceleration != null && t.peakAcceleration! >= 0
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
            ],

            // ── Segment table — collapsed by default ───────────────────────
            if (hasSegments && _expanded) ...[
              const Divider(height: 1, color: sdBorder),
              // Table header
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                child: Row(children: const [
                  Expanded(flex: 25, child: Text('Segment', style: TextStyle(color: sdSubtext, fontSize: 10, fontWeight: FontWeight.w600))),
                  Expanded(flex: 25, child: Text('Split', style: TextStyle(color: sdSubtext, fontSize: 10, fontWeight: FontWeight.w600))),
                  Expanded(flex: 25, child: Text('Speed', style: TextStyle(color: sdSubtext, fontSize: 10, fontWeight: FontWeight.w600))),
                  Expanded(flex: 25, child: Text('Accel', style: TextStyle(color: sdSubtext, fontSize: 10, fontWeight: FontWeight.w600))),
                ]),
              ),
              // Table rows
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  children: _buildSegmentRows(t, segLabels),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSegmentRows(TrialResultModel t, List<String> segLabels) {
    final count = t.speeds.isNotEmpty ? t.speeds.length : t.splits.length;
    final peakSpeed = t.peakSpeed;

    return List.generate(count, (i) {
      final label = i < segLabels.length ? segLabels[i] : 'G$i→G${i + 1}';
      final splitVal = i < t.splits.length ? t.splits[i] : null;
      final speedVal = i < t.speeds.length ? t.speeds[i] : null;
      final accelVal = i < t.accelerations.length ? t.accelerations[i] : null;
      final isPeak = speedVal != null && speedVal == peakSpeed;

      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isPeak ? sdPrimary.withAlpha(15) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: isPeak ? sdPrimary.withAlpha(60) : sdBorder),
        ),
        child: Row(children: [
          Expanded(flex: 25, child: Text(label,
              style: TextStyle(color: isPeak ? sdPrimary : sdText, fontSize: 11,
                  fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500))),
          Expanded(flex: 25, child: Text(
              splitVal != null ? '${splitVal.toStringAsFixed(3)}s' : '--',
              style: const TextStyle(color: sdText, fontSize: 11))),
          Expanded(flex: 25, child: Text(
              speedVal != null ? '${speedVal.toStringAsFixed(2)} m/s' : '--',
              style: TextStyle(color: isPeak ? sdPrimary : sdText, fontSize: 11,
                  fontWeight: isPeak ? FontWeight.w700 : FontWeight.normal))),
          Expanded(flex: 25, child: accelVal != null
              ? Text('${accelVal >= 0 ? '+' : ''}${accelVal.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: accelVal >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      fontSize: 11, fontWeight: FontWeight.w600))
              : const Text('--', style: TextStyle(color: sdSubtext, fontSize: 11))),
        ]),
      );
    });
  }
}

// ── Peak chip helper ──────────────────────────────────────────────────────────

class _PeakChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _PeakChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color, fontSize: 9, fontWeight: FontWeight.w600)),
                  Text(value,
                      style: TextStyle(
                          color: color, fontSize: 13, fontWeight: FontWeight.w800)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        style: const TextStyle(color: sdSubtext, fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Strike Chip ───────────────────────────────────────────────────────────────

class _StrikeChip extends StatelessWidget {
  final int number;
  final String? level;
  final bool isFinal;

  const _StrikeChip({
    required this.number,
    required this.level,
    this.isFinal = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFinal ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final bg = isFinal ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Strike number circles: ● ●
          ...List.generate(number, (i) => Padding(
            padding: EdgeInsets.only(right: i < number - 1 ? 3 : 0),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          )),
          const SizedBox(width: 5),
          Text(
            level != null ? 'Lv $level' : '—',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Charts Tab ────────────────────────────────────────────────────────────────

class ChartsTab extends StatelessWidget {
  final List<AthleteResultModel> ranked;
  final List<double> gateDistances;
  final bool isYoyo;
  final bool isShuttle;

  const ChartsTab({
    super.key,
    required this.ranked,
    this.gateDistances = const [],
    this.isYoyo = false,
    this.isShuttle = false,
  });

  @override
  Widget build(BuildContext context) {
    // ── YoYo charts ──────────────────────────────────────────────────────────
    if (isYoyo) {
      final athletesWithData = ranked
          .where((r) => yoyoLevel(r) != null)
          .toList();
      if (athletesWithData.isEmpty) {
        return const Center(
          child: Text('No YoYo data to chart.', style: TextStyle(color: sdSubtext)),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SdCard(child: YoyoLevelBarChart(athletes: athletesWithData)),
        ],
      );
    }

    // ── Sprint charts (original) ─────────────────────────────────────────────
    final athletesWithData =
        ranked.where((r) => r.completedTrials.isNotEmpty).toList();

    if (athletesWithData.isEmpty) {
      return const Center(
        child: Text('No completed trials to chart.',
            style: TextStyle(color: sdSubtext)),
      );
    }

    final hasSpeedData = athletesWithData.any(
      (r) => r.completedTrials.any((t) => t.speeds.isNotEmpty),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SdCard(child: BestTimeBarChart(athletes: athletesWithData)),
        const SizedBox(height: 16),
        if (athletesWithData.any((r) => r.completedTrials.length > 1))
          SdCard(child: TrialProgressionChart(athletes: athletesWithData)),
        if (hasSpeedData) ...[
          const SizedBox(height: 16),
          SdCard(child: SpeedProfileChart(athletes: athletesWithData, gateDistances: gateDistances, isShuttle: isShuttle)),
          const SizedBox(height: 16),
          SdCard(child: AccelerationChart(athletes: athletesWithData, gateDistances: gateDistances, isShuttle: isShuttle)),
        ],
      ],
    );
  }
}

// ── Best Time Bar Chart ───────────────────────────────────────────────────────

class BestTimeBarChart extends StatelessWidget {
  final List<AthleteResultModel> athletes;

  const BestTimeBarChart({super.key, required this.athletes});

  @override
  Widget build(BuildContext context) {
    final sorted = [...athletes]
      ..sort((a, b) => (a.bestTime ?? double.infinity)
          .compareTo(b.bestTime ?? double.infinity));

    if (sorted.isEmpty) {
      return const Center(
        child: Text('No data available', style: TextStyle(color: sdSubtext)),
      );
    }

    final best = sorted.first.bestTime ?? 0;
    final worst = sorted.last.bestTime ?? 0;
    final range = (worst - best).clamp(0.001, double.infinity);

    const rankColors = [sdGold, sdSilver, sdBronze];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SdSectionTitle('Best Time Leaderboard'),
        const SizedBox(height: 4),
        const Text(
          'Sorted fastest → slowest',
          style: TextStyle(color: sdSubtext, fontSize: 11),
        ),
        const SizedBox(height: 16),
        ...sorted.asMap().entries.map((e) {
          final rank = e.key + 1;
          final r = e.value;
          final time = r.bestTime ?? 0;
          final fill = 1.0 - ((time - best) / range) * 0.8;
          final isTop3 = rank <= 3;
          final rankColor = isTop3
              ? rankColors[rank - 1]
              : sdPrimary.withValues(alpha: 0.7);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isTop3
                        ? rankColor.withValues(alpha: 0.15)
                        : const Color(0xFFF0F4FA),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: isTop3 ? rankColor : sdSubtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.fullName,
                        style: const TextStyle(
                          color: sdText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      LayoutBuilder(builder: (ctx, cons) {
                        return Stack(
                          children: [
                            Container(
                              height: 6,
                              width: cons.maxWidth,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EDF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              height: 6,
                              width: cons.maxWidth * fill,
                              decoration: BoxDecoration(
                                color: rankColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${time.toStringAsFixed(3)}s',
                  style: TextStyle(
                    color: isTop3 ? rankColor : sdText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── YoYo Level Bar Chart ──────────────────────────────────────────────────────

class YoyoLevelBarChart extends StatelessWidget {
  final List<AthleteResultModel> athletes;

  const YoyoLevelBarChart({super.key, required this.athletes});

  @override
  Widget build(BuildContext context) {
    // Sort by highest level first (should already be ranked, but be safe)
    final sorted = [...athletes]..sort((a, b) {
        final al = yoyoLevel(a) ?? 0;
        final bl = yoyoLevel(b) ?? 0;
        return bl.compareTo(al);
      });

    if (sorted.isEmpty) {
      return const Center(
        child: Text('No data available', style: TextStyle(color: sdSubtext)),
      );
    }

    final best = yoyoLevel(sorted.first) ?? 0;
    final worst = yoyoLevel(sorted.last) ?? 0;
    final range = (best - worst).clamp(0.001, double.infinity);

    const rankColors = [sdGold, sdSilver, sdBronze];
    const eliminatedColor = Color(0xFFDC2626);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SdSectionTitle('YoYo Level Leaderboard'),
        const SizedBox(height: 4),
        const Text(
          'Sorted highest → lowest level',
          style: TextStyle(color: sdSubtext, fontSize: 11),
        ),
        const SizedBox(height: 16),
        ...sorted.asMap().entries.map((e) {
          final rank = e.key + 1;
          final r = e.value;
          final lvl = yoyoLevel(r);
          final elim = isYoyoEliminated(r);
          final fill = lvl != null && range > 0
              ? (1.0 - ((best - lvl) / range) * 0.8).clamp(0.2, 1.0)
              : 0.2;
          final isTop3 = rank <= 3;
          final rankColor = isTop3 ? rankColors[rank - 1] : sdPrimary.withValues(alpha: 0.7);
          final barColor = elim ? eliminatedColor : rankColor;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isTop3
                        ? rankColor.withValues(alpha: 0.15)
                        : const Color(0xFFF0F4FA),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: isTop3 ? rankColor : sdSubtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.fullName,
                              style: const TextStyle(
                                color: sdText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (elim) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCA5A5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Eliminated',
                                style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      LayoutBuilder(builder: (ctx, cons) {
                        return Stack(
                          children: [
                            Container(
                              height: 6,
                              width: cons.maxWidth,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EDF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              height: 6,
                              width: cons.maxWidth * fill,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  lvl != null ? 'Lv ${lvl.toStringAsFixed(1)}' : '—',
                  style: TextStyle(
                    color: isTop3 ? rankColor : sdText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Trial Progression Chart ───────────────────────────────────────────────────

class TrialProgressionChart extends StatelessWidget {
  final List<AthleteResultModel> athletes;

  const TrialProgressionChart({super.key, required this.athletes});

  @override
  Widget build(BuildContext context) {
    const lineColors = [
      sdGold,
      sdPrimary,
      sdBronze,
      Color(0xFF7C3AED),
      Color(0xFF059669),
      sdSilver,
    ];

    final maxTrials = athletes
        .map((r) => r.completedTrials.length)
        .reduce((a, b) => a > b ? a : b);
    final allTimes = athletes
        .expand((r) => r.completedTrials.map((t) => t.totalTime!))
        .toList();
    if (allTimes.isEmpty) return const SizedBox();

    final minY = allTimes.reduce((a, b) => a < b ? a : b);
    final maxY = allTimes.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final yPadding = range < 0.1 ? 0.5 : range * 0.15;
    final chartMinY = (minY - yPadding).clamp(0.0, double.infinity);
    final chartMaxY = maxY + yPadding;

    final yRange = chartMaxY - chartMinY;
    final yInterval =
        yRange <= 1 ? 0.2 : yRange <= 3 ? 0.5 : yRange <= 10 ? 1.0 : 2.0;
    final xInterval =
        maxTrials <= 10 ? 1.0 : (maxTrials / 8).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SdSectionTitle('Trial Progression'),
        const SizedBox(height: 4),
        const Text('Performance across trials',
            style: TextStyle(color: sdSubtext, fontSize: 11)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: athletes.asMap().entries.map((e) {
            final color = lineColors[e.key % lineColors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(
                  e.value.fullName.split(' ').first,
                  style: const TextStyle(color: sdText, fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: maxTrials.toDouble(),
                minY: chartMinY,
                maxY: chartMaxY,
                clipData: const FlClipData.all(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final athlete = athletes[s.barIndex];
                        return LineTooltipItem(
                          '${athlete.fullName.split(' ').first}: ${s.y.toStringAsFixed(3)}s',
                          TextStyle(
                              color:
                                  lineColors[s.barIndex % lineColors.length],
                              fontWeight: FontWeight.w600,
                              fontSize: 11),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: yInterval,
                      getTitlesWidget: (v, meta) {
                        if (v == meta.min || v == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            '${v.toStringAsFixed(1)}s',
                            style:
                                const TextStyle(color: sdSubtext, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: xInterval,
                      getTitlesWidget: (v, _) {
                        if (v != v.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'T${v.toInt()}',
                            style:
                                const TextStyle(color: sdSubtext, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: athletes.asMap().entries.map((e) {
                  final color = lineColors[e.key % lineColors.length];
                  final trials = e.value.completedTrials
                      .where((t) => t.totalTime != null)
                      .toList()
                    ..sort((a, b) => a.trialNumber.compareTo(b.trialNumber));
                  final spots = trials.asMap().entries
                      .map((en) => FlSpot(
                            (en.key + 1).toDouble(),
                            en.value.totalTime!,
                          ))
                      .toList();
                  return LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── PDF Options Sheet ─────────────────────────────────────────────────────────

class PdfOptionsSheet extends StatefulWidget {
  final TestSessionModel session;
  const PdfOptionsSheet({super.key, required this.session});

  @override
  State<PdfOptionsSheet> createState() => _PdfOptionsSheetState();
}

class _PdfOptionsSheetState extends State<PdfOptionsSheet> {
  bool _sharePending = false;
  bool _savePending = false;

  TimingGateProfileModel? get _profile {
    final s = context.read<ProfileCubit>().state;
    return s is ProfileLoaded ? s.profile : null;
  }

  Future<void> _share() async {
    setState(() => _sharePending = true);
    try {
      await SessionPdfService.generateAndShare(
        session: widget.session,
        profile: _profile,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showError('Share failed: $e');
    } finally {
      if (mounted) setState(() => _sharePending = false);
    }
  }

  Future<void> _save() async {
    setState(() => _savePending = true);
    try {
      final path = await SessionPdfService.saveToDevice(
        session: widget.session,
        profile: _profile,
      );
      if (!mounted) return;

      Navigator.of(context).pop();

      if (path != null) {
        context.read<GlobalErrorCubit>().showSuccess(
          'PDF saved! ${_shortPath(path)}',
        );
      } else {
        _showError('Could not access device storage.');
      }
    } catch (e) {
      if (mounted) _showError('Save failed: $e');
    } finally {
      if (mounted) setState(() => _savePending = false);
    }
  }

  String _shortPath(String path) {
    final idx = path.indexOf('SportsIQ');
    return idx >= 0 ? path.substring(idx) : path;
  }

  void _showError(String msg) {
    context.read<GlobalErrorCubit>().showError(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: sdBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'PDF Report',
            style: TextStyle(
              color: sdText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Session results, leaderboard and trial times in PDF',
            style: TextStyle(color: sdSubtext, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SdOptionTile(
            icon: Icons.share_outlined,
            iconColor: sdPrimary,
            title: 'Share PDF',
            subtitle: 'WhatsApp, Gmail, Drive — kahi bhi bhejo',
            isLoading: _sharePending,
            onTap: (_sharePending || _savePending) ? null : _share,
          ),
          const SizedBox(height: 12),
          SdOptionTile(
            icon: Icons.download_outlined,
            iconColor: sdSuccess,
            title: 'Save to Device',
            subtitle: 'Saved inside the SportsIQ folder in the Files app',
            isLoading: _savePending,
            onTap: (_sharePending || _savePending) ? null : _save,
          ),
        ],
      ),
    );
  }
}

// ── Option Tile ───────────────────────────────────────────────────────────────

class SdOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback? onTap;

  const SdOptionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: sdBorder),
          borderRadius: BorderRadius.circular(12),
          color: onTap == null ? const Color(0xFFF8FAFC) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: onTap == null ? sdSubtext : sdText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: sdSubtext, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!isLoading)
              const Icon(Icons.chevron_right, color: sdSubtext, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class SdCard extends StatelessWidget {
  final Widget child;
  const SdCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sdSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sdBorder),
      ),
      child: child,
    );
  }
}

class SdSectionTitle extends StatelessWidget {
  final String title;
  const SdSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            color: sdText, fontSize: 14, fontWeight: FontWeight.w700));
  }
}

class SdInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const SdInfoRow(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: sdSubtext, size: 15),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: sdSubtext, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: sdText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class SdStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const SdStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text(label,
                    style: const TextStyle(color: sdSubtext, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SdMiniStat extends StatelessWidget {
  final String label;
  final String value;
  /// Optional sub-line (e.g. "26.7 km/h")
  final String? sub;
  /// Optional value colour — defaults to sdText
  final Color? color;

  const SdMiniStat({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = color ?? sdText;
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: valueColor, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(label,
              style: const TextStyle(color: sdSubtext, fontSize: 10)),
          if (sub != null && sub!.isNotEmpty)
            Text(sub!,
                style: TextStyle(color: valueColor.withAlpha(180), fontSize: 9)),
        ],
      ),
    );
  }
}

class SdVDivider extends StatelessWidget {
  const SdVDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 28, width: 1, color: sdBorder);
  }
}

// ── Helper function ───────────────────────────────────────────────────────────

String sdFormatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

// ── Speed Profile Chart ───────────────────────────────────────────────────────

class SpeedProfileChart extends StatelessWidget {
  final List<AthleteResultModel> athletes;
  final List<double> gateDistances;
  final bool isShuttle;
  const SpeedProfileChart({
    super.key,
    required this.athletes,
    this.gateDistances = const [],
    this.isShuttle = false,
  });

  static const _barColors = [
    sdPrimary, sdGold, sdBronze, Color(0xFF7C3AED), Color(0xFF059669), sdSilver,
  ];

  @override
  Widget build(BuildContext context) {
    // Use best trial (lowest totalTime) that has speed data
    final entries = athletes
        .map((a) {
          final trial = a.completedTrials
              .where((t) => t.speeds.isNotEmpty)
              .fold<TrialResultModel?>(null, (best, t) {
            if (best == null) return t;
            return (t.totalTime ?? double.infinity) < (best.totalTime ?? double.infinity)
                ? t
                : best;
          });
          return trial != null ? MapEntry(a, trial) : null;
        })
        .whereType<MapEntry<AthleteResultModel, TrialResultModel>>()
        .toList();

    if (entries.isEmpty) return const SizedBox();

    // Cap at 6 athletes (one per colour) — more than 6 is unreadable on a line chart
    final capped = entries.take(6).toList();
    final maxSegments = capped.map((e) => e.value.speeds.length).reduce((a, b) => a > b ? a : b);
    final segLabels = _buildSegmentLabels(gateDistances, maxSegments, startFromMaster: !isShuttle);
    // Each segment gets 42 px minimum so labels never crowd
    const segPx = 42.0;
    const leftReserved = 44.0;
    final chartWidth = maxSegments * segPx;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SdSectionTitle('Speed Profile (Best Trial)'),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text('Segment speed in m/s', style: TextStyle(color: sdSubtext, fontSize: 11)),
            if (entries.length > 6) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sdGold.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Top 6 of ${entries.length}',
                    style: const TextStyle(color: sdGold, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: capped.asMap().entries.map((e) {
            final color = _barColors[e.key];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(e.value.key.fullName.split(' ').first, style: const TextStyle(color: sdText, fontSize: 11)),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final minWidth = chartWidth + leftReserved;
            final width = minWidth < constraints.maxWidth ? constraints.maxWidth : minWidth;
            return SizedBox(
          height: 220,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxSegments.toDouble(),
                  minY: 0,
                  clipData: const FlClipData.all(),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (spots) => spots.map((s) {
                        final name = capped[s.barIndex].key.fullName.split(' ').first;
                        return LineTooltipItem(
                          '$name: ${s.y.toStringAsFixed(2)} m/s',
                          TextStyle(color: _barColors[s.barIndex], fontSize: 11, fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 22,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          final label = isShuttle
                              ? (idx % 2 == 0 ? 'G1' : 'G2')
                              : (idx == 0 ? 'M' : 'G$idx');
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(label,
                                style: const TextStyle(color: sdSubtext, fontSize: 9)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: leftReserved,
                        getTitlesWidget: (v, meta) {
                          if (v == meta.min || v == meta.max) return const SizedBox.shrink();
                          return Text(v.toStringAsFixed(1), style: const TextStyle(color: sdSubtext, fontSize: 9));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) => const FlLine(color: sdBorder, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: capped.asMap().entries.map((e) {
                    final color = _barColors[e.key];
                    final speeds = e.value.value.speeds;
                    return LineChartBarData(
                      spots: speeds.asMap().entries.map((s) => FlSpot((s.key + 1).toDouble(), s.value)).toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: color),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
            );
          },
        ),
      ],
    );
  }
}

// ── Acceleration Chart ────────────────────────────────────────────────────────

class AccelerationChart extends StatelessWidget {
  final List<AthleteResultModel> athletes;
  final List<double> gateDistances;
  final bool isShuttle;
  const AccelerationChart({
    super.key,
    required this.athletes,
    this.gateDistances = const [],
    this.isShuttle = false,
  });

  static const _barColors = [
    sdPrimary, sdGold, sdBronze, Color(0xFF7C3AED), Color(0xFF059669), sdSilver,
  ];

  @override
  Widget build(BuildContext context) {
    final entries = athletes
        .map((a) {
          final trial = a.completedTrials
              .where((t) => t.accelerations.isNotEmpty)
              .fold<TrialResultModel?>(null, (best, t) {
            if (best == null) return t;
            return (t.totalTime ?? double.infinity) < (best.totalTime ?? double.infinity)
                ? t
                : best;
          });
          return trial != null ? MapEntry(a, trial) : null;
        })
        .whereType<MapEntry<AthleteResultModel, TrialResultModel>>()
        .toList();

    if (entries.isEmpty) return const SizedBox();

    // Cap at 6 athletes — more than 6 lines is unreadable
    final capped = entries.take(6).toList();
    final maxSegments = capped.map((e) => e.value.accelerations.length).reduce((a, b) => a > b ? a : b);
    final segLabels = _buildSegmentLabels(gateDistances, maxSegments, startFromMaster: !isShuttle);
    const segPx = 42.0;
    const leftReserved = 48.0;
    final chartWidth = maxSegments * segPx;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SdSectionTitle('Acceleration Profile (Best Trial)'),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text('+ = accelerating, − = decelerating',
                style: TextStyle(color: sdSubtext, fontSize: 11)),
            if (entries.length > 6) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sdGold.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Top 6 of ${entries.length}',
                    style: const TextStyle(color: sdGold, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: capped.asMap().entries.map((e) {
            final color = _barColors[e.key];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(e.value.key.fullName.split(' ').first, style: const TextStyle(color: sdText, fontSize: 11)),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final minWidth = chartWidth + leftReserved;
            final width = minWidth < constraints.maxWidth ? constraints.maxWidth : minWidth;
            return SizedBox(
          height: 220,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxSegments.toDouble(),
                  clipData: const FlClipData.all(),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (spots) => spots.map((s) {
                        final name = capped[s.barIndex].key.fullName.split(' ').first;
                        final sign = s.y >= 0 ? '+' : '';
                        return LineTooltipItem(
                          '$name: $sign${s.y.toStringAsFixed(2)} m/s²',
                          TextStyle(color: _barColors[s.barIndex], fontSize: 11, fontWeight: FontWeight.w600),
                        );
                      }).toList(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 22,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          final label = isShuttle
                              ? (idx % 2 == 0 ? 'G1' : 'G2')
                              : (idx == 0 ? 'M' : 'G$idx');
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(label,
                                style: const TextStyle(color: sdSubtext, fontSize: 9)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: leftReserved,
                        getTitlesWidget: (v, meta) {
                          if (v == meta.min || v == meta.max) return const SizedBox.shrink();
                          final sign = v >= 0 ? '+' : '';
                          return Text('$sign${v.toStringAsFixed(1)}',
                              style: const TextStyle(color: sdSubtext, fontSize: 9));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: v == 0 ? sdText.withValues(alpha: 0.3) : sdBorder,
                      strokeWidth: v == 0 ? 1 : 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: capped.asMap().entries.map((e) {
                    final color = _barColors[e.key];
                    final accels = e.value.value.accelerations;
                    return LineChartBarData(
                      spots: accels.asMap().entries.map((a) => FlSpot((a.key + 1).toDouble(), a.value)).toList(),
                      isCurved: false,
                      color: color,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: color),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
            );
          },
        ),
      ],
    );
  }
}
