import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final allBest = ranked
        .map((r) => r.bestTime)
        .where((t) => t != null)
        .cast<double>()
        .toList();
    final overallBest =
        allBest.isEmpty ? null : allBest.reduce((a, b) => a < b ? a : b);
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
                label: 'Best Time',
                value: overallBest != null
                    ? '${overallBest.toStringAsFixed(3)}s'
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
          SdCard(child: PodiumSection(ranked: ranked)),
      ],
    );
  }
}

// ── Podium Section ────────────────────────────────────────────────────────────

class PodiumSection extends StatelessWidget {
  final List<AthleteResultModel> ranked;

  const PodiumSection({super.key, required this.ranked});

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
                    athlete.bestTime != null
                        ? '${athlete.bestTime!.toStringAsFixed(3)}s'
                        : '—',
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

  const LeaderboardTab({super.key, required this.ranked});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ranked.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AthleteDetailCard(result: ranked[i], rank: i + 1),
      ),
    );
  }
}

// ── Athlete Detail Card ───────────────────────────────────────────────────────

class AthleteDetailCard extends StatelessWidget {
  final AthleteResultModel result;
  final int rank;

  const AthleteDetailCard(
      {super.key, required this.result, required this.rank});

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? sdGold
        : rank == 2
            ? sdSilver
            : rank == 3
                ? sdBronze
                : sdSubtext;

    final completedTrials = result.completedTrials;
    final allTrials = result.trials
        .where((t) => t.isCompleted || t.isSkipped || t.isFalseStart)
        .toList()
      ..sort((a, b) => a.trialNumber.compareTo(b.trialNumber));

    return SdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                backgroundColor: sdPrimaryLight,
                child: Text(
                  result.fullName.isNotEmpty
                      ? result.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: sdPrimary,
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
                          style:
                              const TextStyle(color: sdSubtext, fontSize: 11)),
                  ],
                ),
              ),
              if (result.bestTime != null)
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
          if (completedTrials.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: sdBorder, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                SdMiniStat(
                    label: 'Trials', value: '${completedTrials.length}'),
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
                    final times =
                        completedTrials.map((t) => t.totalTime!).toList();
                    final worst =
                        times.reduce((a, b) => a > b ? a : b);
                    return '${worst.toStringAsFixed(3)}s';
                  }(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...allTrials.map((t) => TrialRow(trial: t, result: result)),
          ],
        ],
      ),
    );
  }
}

// ── Trial Row ─────────────────────────────────────────────────────────────────

class TrialRow extends StatelessWidget {
  final TrialResultModel trial;
  final AthleteResultModel result;

  const TrialRow({super.key, required this.trial, required this.result});

  @override
  Widget build(BuildContext context) {
    final t = trial;
    final isBest = t.isCompleted &&
        t.totalTime != null &&
        result.bestTime != null &&
        t.totalTime == result.bestTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isBest ? sdGold.withAlpha(15) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isBest ? sdGold.withAlpha(80) : sdBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isBest ? sdGold.withAlpha(30) : sdPrimaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('T${t.trialNumber}',
                style: TextStyle(
                    color: isBest ? sdGold : sdPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: t.isCompleted
                ? Column(
                    spacing: 6,
                    children: [
                      if (t.splits.isNotEmpty)
                        ...t.splits.asMap().entries.map((e) => Text(
                              'G${e.key + 1}→G${e.key + 2}: ${e.value.toStringAsFixed(3)}s',
                              style: const TextStyle(
                                  color: sdSubtext, fontSize: 11, fontWeight: FontWeight.bold),
                            )),
                    ],
                  )
                : Text(
                    t.isSkipped ? 'Skipped' : 'False Start',
                    style: const TextStyle(
                        color: sdSubtext,
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                  ),
          ),
          if (t.isCompleted && t.totalTime != null)
            Row(
              children: [
                Text(
                  '${t.totalTime!.toStringAsFixed(3)}s',
                  style: TextStyle(
                    color: isBest ? sdGold : sdText,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (isBest) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, color: sdGold, size: 14),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

// ── Charts Tab ────────────────────────────────────────────────────────────────

class ChartsTab extends StatelessWidget {
  final List<AthleteResultModel> ranked;

  const ChartsTab({super.key, required this.ranked});

  @override
  Widget build(BuildContext context) {
    final athletesWithData =
        ranked.where((r) => r.completedTrials.isNotEmpty).toList();

    if (athletesWithData.isEmpty) {
      return const Center(
        child: Text('No completed trials to chart.',
            style: TextStyle(color: sdSubtext)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SdCard(child: BestTimeBarChart(athletes: athletesWithData)),
        const SizedBox(height: 16),
        if (athletesWithData.any((r) => r.completedTrials.length > 1))
          SdCard(child: TrialProgressionChart(athletes: athletesWithData)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: sdSuccess,
            duration: const Duration(seconds: 4),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PDF saved!',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  _shortPath(path),
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
      ),
    );
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
            'Session results, leaderboard aur trial times PDF mein',
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
            subtitle: 'Files app mein SportsIQ folder ke andar save hoga',
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
  const SdMiniStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: sdText, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(label,
              style: const TextStyle(color: sdSubtext, fontSize: 10)),
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
