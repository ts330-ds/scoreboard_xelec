import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../../domain/entity/coach_task_result_entity.dart';
import '../cubit/coach_task_result_cubit.dart';
import '../cubit/coach_task_result_state.dart';

// Helper: elapsed seconds → "M:SS" or "H:MM:SS"
String _fmtElapsed(int totalSeconds) {
  if (totalSeconds < 0) totalSeconds = 0;
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

// Helper: anchor + offsetSeconds → "HH:MM" (local time)
String _fmtClock(DateTime anchor, int offsetSeconds) {
  final dt = anchor.add(Duration(seconds: offsetSeconds)).toLocal();
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _fmtClockSec(DateTime anchor, int offsetSeconds) {
  final dt = anchor.add(Duration(seconds: offsetSeconds)).toLocal();
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

class CoachTaskResultScreen extends StatelessWidget {
  final int taskId;
  final String athleteName;
  final String taskName;

  const CoachTaskResultScreen({
    super.key,
    required this.taskId,
    required this.athleteName,
    required this.taskName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CoachTaskResultCubit(
        taskId: taskId,
        getTaskResult: sl(),
      )..load(),
      child: _CoachTaskResultBody(
        athleteName: athleteName,
        taskName: taskName,
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _CoachTaskResultBody extends StatelessWidget {
  final String athleteName;
  final String taskName;

  const _CoachTaskResultBody(
      {required this.athleteName, required this.taskName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(athleteName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text(taskName,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Done',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<CoachTaskResultCubit, CoachTaskResultState>(
        builder: (context, state) {
          if (state.status == CoachTaskResultStatus.loading ||
              state.status == CoachTaskResultStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == CoachTaskResultStatus.error) {
            return _ErrorView(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => context.read<CoachTaskResultCubit>().load(),
            );
          }

          final sessions = state.result?.sessions ?? [];
          if (sessions.isEmpty) {
            return const _EmptyView();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            itemCount: sessions.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(
                  bottom: i < sessions.length - 1 ? 24 : 0),
              child: _SessionView(
                session: sessions[i],
                sessionNumber: sessions.length > 1 ? i + 1 : null,
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

// ── Session View ──────────────────────────────────────────────────────────────

class _SessionView extends StatelessWidget {
  final CoachTaskResultSession session;
  final int? sessionNumber;

  const _SessionView({required this.session, this.sessionNumber});

  @override
  Widget build(BuildContext context) {
    final hasChart = session.rawData.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sessionNumber != null) ...[
          Text('Session $sessionNumber',
              style: const TextStyle(
                  color: AppColors.subtext,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 10),
        ],

        // ── 1. Heart Rate chart (top, prominent)
        if (hasChart) ...[
          _SectionHeader(
              icon: Icons.favorite_rounded, title: 'Heart Rate'),
          const SizedBox(height: 10),
          _HeartRateHeroCard(session: session),
          const SizedBox(height: 16),
        ] else ...[
          _HeartRateSummaryCard(stats: session.stats.heartRate),
          const SizedBox(height: 16),
        ],

        // ── 2. Heart Rate Zones distribution
        if (hasChart) ...[
          _HrZonesCard(
            spots: ([...session.rawData]
                  ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt)))
                .map((p) => FlSpot(
                      p.recordedAt
                          .difference(session.startedAt)
                          .inSeconds
                          .toDouble(),
                      p.heartRate.toDouble(),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // ── 3. Session info
        _SessionInfoCard(session: session),
        const SizedBox(height: 16),

        // ── 4. HRV chart
        Builder(builder: (context) {
          // Anchor x-axis to session.startedAt so labels show clock time
          final sorted = [...session.rawData]
            ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
          if (sorted.isEmpty) return const SizedBox.shrink();
          final anchor = session.startedAt;
          final hrvSpots = <FlSpot>[];
          for (final p in sorted) {
            final v = p.sugarLevel;
            if (v == null || v <= 0) continue;
            hrvSpots.add(FlSpot(
              p.recordedAt.difference(anchor).inSeconds.toDouble(),
              v,
            ));
          }
          if (!hasChart || hrvSpots.length < 2) {
            return const SizedBox.shrink();
          }
          final sessionSpan = session.duration.inSeconds.toDouble();
          final lastX = hrvSpots.last.x;
          final totalSec = sessionSpan > 0 ? sessionSpan : lastX;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                  icon: Icons.monitor_heart_outlined,
                  title: 'HRV (RMSSD)'),
              const SizedBox(height: 10),
              _HrvLineChart(
                spots: hrvSpots,
                statRange: session.stats.sugar,
                totalSeconds: totalSec,
                anchor: anchor,
              ),
            ],
          );
        }),

      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
        ],
      );
}

// ── Heart Rate Hero Card (chart + stats) ─────────────────────────────────────

class _HeartRateHeroCard extends StatelessWidget {
  final CoachTaskResultSession session;
  const _HeartRateHeroCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final stats = session.stats.heartRate;
    // Sort raw_data by recorded_at (oldest first) — entity reverses but be safe
    final sorted = [...session.rawData]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    // Anchor x-axis to session.startedAt so labels show real clock time
    final anchor = session.startedAt;
    final spots = sorted
        .map((p) => FlSpot(
              p.recordedAt.difference(anchor).inSeconds.toDouble(),
              p.heartRate.toDouble(),
            ))
        .toList();

    final bpms = sorted.map((p) => p.heartRate).toList();
    final maxBpm = bpms.reduce(math.max);
    final minBpm = bpms.reduce(math.min);
    final maxY = (maxBpm + 20).toDouble();
    final minY = ((minBpm - 20).clamp(0, 999)).toDouble();
    final sessionSpan = session.duration.inSeconds.toDouble();
    final lastX = spots.isNotEmpty ? spots.last.x : 0.0;
    final double maxX =
        (sessionSpan > 0 ? sessionSpan : lastX).clamp(1.0, double.infinity);
    final double minX = spots.isNotEmpty && spots.first.x < 0 ? spots.first.x : 0.0;
    final double tickInterval = (maxX - minX) / 4;

    final avgBpm = stats.avg;

    Color zoneColor(double bpm) {
      if (bpm < 60) return AppColors.primary;
      if (bpm < 100) return AppColors.success;
      if (bpm < 140) return AppColors.warning;
      return AppColors.error;
    }

    String zoneLabel(double bpm) {
      if (bpm < 60) return 'Resting';
      if (bpm < 100) return 'Normal';
      if (bpm < 140) return 'Moderate';
      return 'High Intensity';
    }

    final color = zoneColor(avgBpm);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top band
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: color),
                      const SizedBox(width: 5),
                      Text(zoneLabel(avgBpm),
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.favorite_rounded, color: color, size: 16),
                const SizedBox(width: 4),
                Text('Heart Rate',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // ── Avg BPM display
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stats.avg.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 68,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('BPM avg',
                      style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // ── Chart
          SizedBox(
            height: 160,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 16, 8),
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.borderLight,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 20,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt()}',
                          style: const TextStyle(
                              color: AppColors.subtext, fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: tickInterval,
                        getTitlesWidget: (v, _) {
                          if (v < minX || v > maxX) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _fmtClock(anchor, v.toInt()),
                              style: const TextStyle(
                                  color: AppColors.subtext, fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.text,
                      getTooltipItems: (spots) => spots
                          .map((s) => LineTooltipItem(
                                '${s.y.toInt()} bpm  •  ${_fmtClockSec(anchor, s.x.toInt())}',
                                const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ))
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: color,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.2),
                            color.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Divider
          Divider(height: 1, color: AppColors.border),

          // ── Min / Avg / Max / Readings
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Row(
              children: [
                _BpmStat(
                  label: 'Min',
                  value: stats.min.toStringAsFixed(0),
                  color: AppColors.primary,
                ),
                _Divider(),
                _BpmStat(
                  label: 'Avg',
                  value: stats.avg.toStringAsFixed(0),
                  color: AppColors.success,
                ),
                _Divider(),
                _BpmStat(
                  label: 'Max',
                  value: stats.max.toStringAsFixed(0),
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BpmStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BpmStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 10)),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.border);
}

// ── Fallback when no raw_data ─────────────────────────────────────────────────

class _HeartRateSummaryCard extends StatelessWidget {
  final StatRange stats;
  const _HeartRateSummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
                label: 'Min BPM',
                value: stats.min.toStringAsFixed(0),
                color: AppColors.primary),
            _StatItem(
                label: 'Avg BPM',
                value: stats.avg.toStringAsFixed(0),
                color: AppColors.success),
            _StatItem(
                label: 'Max BPM',
                value: stats.max.toStringAsFixed(0),
                color: AppColors.error),
          ],
        ),
      );
}

// ── Session Info Card ─────────────────────────────────────────────────────────

class _SessionInfoCard extends StatelessWidget {
  final CoachTaskResultSession session;
  const _SessionInfoCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dur = session.duration;
    final durStr =
        '${dur.inMinutes}m ${dur.inSeconds.remainder(60)}s';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoItem(
              icon: Icons.play_circle_outline,
              label: 'Started',
              value: _fmt(session.startedAt),
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: _InfoItem(
              icon: Icons.stop_circle_outlined,
              label: 'Ended',
              value: _fmt(session.endedAt),
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: _InfoItem(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: durStr,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.subtext, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      );
}

// ── Stat Item ─────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.subtext, fontSize: 11)),
        ],
      );
}

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                color: AppColors.subtext, size: 52),
            SizedBox(height: 16),
            Text('No result found',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('This task has no recorded session',
                style:
                    TextStyle(color: AppColors.subtext, fontSize: 13)),
          ],
        ),
      );
}

// ── HR Zones Card ────────────────────────────────────────────────────────────

class _HrZonesCard extends StatelessWidget {
  final List<FlSpot> spots;
  const _HrZonesCard({required this.spots});

  // Zones based on absolute HR thresholds (age agnostic)
  // Z1 Resting (<100), Z2 Fat Burn (100-120), Z3 Cardio (120-140),
  // Z4 Peak (140-160), Z5 Max (>=160)
  static const _zones = [
    (label: 'Resting', color: Color(0xFF66BB6A), min: 0, max: 100),
    (label: 'Fat Burn', color: Color(0xFF9CCC65), min: 100, max: 120),
    (label: 'Cardio', color: Color(0xFFFFA726), min: 120, max: 140),
    (label: 'Peak', color: Color(0xFFFB8C00), min: 140, max: 160),
    (label: 'Max', color: Color(0xFFEF5350), min: 160, max: 999),
  ];

  @override
  Widget build(BuildContext context) {
    final counts = List<int>.filled(_zones.length, 0);
    for (final s in spots) {
      for (var i = 0; i < _zones.length; i++) {
        if (s.y >= _zones[i].min && s.y < _zones[i].max) {
          counts[i]++;
          break;
        }
      }
    }
    final total = counts.fold<int>(0, (a, b) => a + b);
    final dominant = total == 0
        ? 0
        : counts.indexOf(counts.reduce((a, b) => a > b ? a : b));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _zones[dominant].color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.bar_chart,
                  color: _zones[dominant].color, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Heart Rate Zones',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            if (total > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _zones[dominant].color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mostly ${_zones[dominant].label}',
                  style: TextStyle(
                      color: _zones[dominant].color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ]),

          const SizedBox(height: 16),

          // Stacked bar
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: List.generate(_zones.length, (i) {
                  if (counts[i] == 0) return const SizedBox.shrink();
                  return Expanded(
                    flex: counts[i],
                    child: Container(height: 14, color: _zones[i].color),
                  );
                }),
              ),
            )
          else
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

          const SizedBox(height: 16),

          // Legend rows
          for (var i = 0; i < _zones.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ZoneRow(
                color: _zones[i].color,
                label: _zones[i].label,
                range: i == _zones.length - 1
                    ? '${_zones[i].min}+'
                    : '${_zones[i].min}–${_zones[i].max - 1}',
                seconds: counts[i],
                pct: total == 0 ? 0 : counts[i] / total,
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final Color color;
  final String label, range;
  final int seconds;
  final double pct;
  const _ZoneRow({
    required this.color,
    required this.label,
    required this.range,
    required this.seconds,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 70,
        child: Text(label,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
      SizedBox(
        width: 64,
        child: Text('$range bpm',
            style: const TextStyle(color: AppColors.subtext, fontSize: 11)),
      ),
      const Spacer(),
      Text(_fmtElapsed(seconds),
          style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700)),
      const SizedBox(width: 10),
      SizedBox(
        width: 38,
        child: Text('${(pct * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}

// ── HRV Line Chart (ECG style) ────────────────────────────────────────────────

const _kHrvColor = Color(0xFF40C4FF);

class _HrvLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final StatRange statRange;
  final double totalSeconds;
  final DateTime anchor;

  const _HrvLineChart({
    required this.spots,
    required this.statRange,
    required this.totalSeconds,
    required this.anchor,
  });

  @override
  Widget build(BuildContext context) {
    final ys = spots.map((s) => s.y);
    final maxVal = ys.reduce(math.max);
    final minVal = ys.reduce(math.min);
    final range = maxVal - minVal;
    final padding = range < 5 ? 5.0 : range * 0.2;
    final maxY = maxVal + padding;
    final minY = (minVal - padding).clamp(0.0, double.infinity);
    final double maxX = totalSeconds > 0
        ? totalSeconds
        : (spots.isNotEmpty ? spots.last.x : 1.0);
    final double tickInterval = maxX / 4;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kHrvColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: _kHrvColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Text(
                  '${statRange.avg.toStringAsFixed(1)} ms',
                  style: const TextStyle(
                      color: _kHrvColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 6),
                const Text('avg RMSSD',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                Text(
                  'min ${statRange.min.toStringAsFixed(1)}  max ${statRange.max.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // Chart
          SizedBox(
            height: 130,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (val, _) => Text(
                          val.toStringAsFixed(0),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: tickInterval,
                        getTitlesWidget: (v, _) {
                          if (v < 0 || v > maxX) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _fmtClock(anchor, v.toInt()),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: _kHrvColor,
                      barWidth: 1.8,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                      shadow: Shadow(
                          color: _kHrvColor.withValues(alpha: 0.4),
                          blurRadius: 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    color: AppColors.error, size: 40),
              ),
              const SizedBox(height: 20),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
}
