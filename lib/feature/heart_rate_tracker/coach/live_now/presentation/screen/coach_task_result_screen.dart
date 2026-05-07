import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../../domain/entity/coach_task_result_entity.dart';
import '../cubit/coach_task_result_cubit.dart';
import '../cubit/coach_task_result_state.dart';

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
              message: state.errorMessage ?? 'Kuch galat ho gaya',
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

        // ── 2. Session info
        _SessionInfoCard(session: session),
        const SizedBox(height: 16),

        // ── 3. HRV chart
        Builder(builder: (context) {
          final hrvPoints = session.rawData
              .where((p) => p.sugarLevel != null && p.sugarLevel! > 0)
              .map((p) => p.sugarLevel!)
              .toList();
          if (!hasChart || hrvPoints.length < 2) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                  icon: Icons.monitor_heart_outlined,
                  title: 'HRV (RMSSD)'),
              const SizedBox(height: 10),
              _HrvLineChart(
                hrvPoints: hrvPoints,
                statRange: session.stats.sugar,
              ),
            ],
          );
        }),

        // ── 4. SpO2 chart
        if (hasChart &&
            session.rawData.any((p) => p.spo2 != null)) ...[
          const SizedBox(height: 16),
          _SectionHeader(
              icon: Icons.water_drop_rounded, title: 'SpO2'),
          const SizedBox(height: 10),
          _VitalLineChart(
            points: session.rawData.map((p) => p.spo2 ?? 0).toList(),
            color: AppColors.vitalOxygen,
            unit: '%',
            statRange: session.stats.spo2,
          ),
        ],

        // ── 5. Stress chart
        if (hasChart &&
            session.rawData.any((p) => p.stressLevel != null)) ...[
          const SizedBox(height: 16),
          _SectionHeader(
              icon: Icons.psychology_outlined, title: 'Stress Level'),
          const SizedBox(height: 10),
          _VitalLineChart(
            points: session.rawData.map((p) => p.stressLevel ?? 0).toList(),
            color: AppColors.vitalStress,
            unit: '',
            statRange: session.stats.stress,
          ),
        ],
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
    final bpms = session.rawData.map((p) => p.heartRate).toList();
    final spots = bpms
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    final maxBpm = bpms.reduce(math.max);
    final minBpm = bpms.reduce(math.min);
    final maxY = (maxBpm + 20).toDouble();
    final minY = ((minBpm - 20).clamp(0, 999)).toDouble();

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
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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
                _Divider(),
                _BpmStat(
                  label: 'Readings',
                  value: '${bpms.length}',
                  color: AppColors.subtext,
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

// ── Vital Line Chart (SpO2, Stress, etc.) ────────────────────────────────────

class _VitalLineChart extends StatelessWidget {
  final List<double> points;
  final Color color;
  final String unit;
  final StatRange statRange;

  const _VitalLineChart({
    required this.points,
    required this.color,
    required this.unit,
    required this.statRange,
  });

  @override
  Widget build(BuildContext context) {
    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final maxVal = points.reduce(math.max);
    final minVal = points.reduce(math.min);
    final range = maxVal - minVal;
    final padding = range < 5 ? 5.0 : range * 0.2;
    final maxY = maxVal + padding;
    final minY = (minVal - padding).clamp(0.0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Text(
                  '${statRange.avg.toStringAsFixed(1)}$unit',
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 6),
                Text('avg',
                    style: const TextStyle(
                        color: AppColors.subtext, fontSize: 12)),
                const Spacer(),
                Text(
                  'min ${statRange.min.toStringAsFixed(1)}$unit  max ${statRange.max.toStringAsFixed(1)}$unit',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ),
          ),

          // ── Chart
          SizedBox(
            height: 120,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
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
                        getTitlesWidget: (val, _) => Text(
                          val.toStringAsFixed(0),
                          style: const TextStyle(
                              color: AppColors.subtext, fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: color,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.18),
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
        ],
      ),
    );
  }
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
            Text('Koi result nahi mila',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Is task ka koi recorded session nahi hai',
                style:
                    TextStyle(color: AppColors.subtext, fontSize: 13)),
          ],
        ),
      );
}

// ── HRV Line Chart (ECG style) ────────────────────────────────────────────────

const _kHrvColor = Color(0xFF40C4FF);

class _HrvLineChart extends StatelessWidget {
  final List<double> hrvPoints;
  final StatRange statRange;

  const _HrvLineChart({required this.hrvPoints, required this.statRange});

  @override
  Widget build(BuildContext context) {
    final spots = hrvPoints
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final maxVal = hrvPoints.reduce(math.max);
    final minVal = hrvPoints.reduce(math.min);
    final range = maxVal - minVal;
    final padding = range < 5 ? 5.0 : range * 0.2;
    final maxY = maxVal + padding;
    final minY = (minVal - padding).clamp(0.0, double.infinity);

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
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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
