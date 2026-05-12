import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import '../../domain/entity/my_athlete_entity.dart';
import '../cubit/athlete_detail_cubit.dart';
import '../cubit/athlete_detail_state.dart';
import '../cubit/athlete_health_metrics_cubit.dart';
import '../cubit/athlete_health_metrics_state.dart';

class AthleteDetailMobile extends StatelessWidget {
  final MyAthleteEntity preview;
  const AthleteDetailMobile({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteDetailCubit, AthleteDetailState>(
      builder: (context, detailState) {
        final athlete = detailState.athlete ?? preview;
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _HeroAppBar(athlete: athlete),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (detailState.status == AthleteDetailStatus.loading)
                        _LoadingBanner(),

                      _QuickStatsRow(athlete: athlete),
                      const SizedBox(height: 24),

                      // ── Health Metrics
                      _SectionHeader(
                          icon: Icons.monitor_heart_outlined,
                          title: 'Health Metrics'),
                      const SizedBox(height: 12),
                      _HealthMetricsCard(athleteId: athlete.id),
                      const SizedBox(height: 24),

                      // ── Personal Info
                      _SectionHeader(
                          icon: Icons.person_outline, title: 'Personal Info'),
                      const SizedBox(height: 12),
                      _InfoCard(items: [
                        _InfoRow('Gender', athlete.gender),
                        _InfoRow('Date of Birth', athlete.dob),
                        _InfoRow('Phone', athlete.phone),
                        _InfoRow('Status', athlete.status),
                        _InfoRow('Member Since', athlete.createdAt),
                      ]),
                      const SizedBox(height: 24),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

// ── Hero SliverAppBar ─────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  final MyAthleteEntity athlete;
  const _HeroAppBar({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final initials = athlete.name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text(athlete.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(athlete.email,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick Stats Chips ─────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final MyAthleteEntity athlete;
  const _QuickStatsRow({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final chips = <_ChipData>[];
    if (athlete.sportName != null)
      chips.add(_ChipData(Icons.sports, athlete.sportName!, AppColors.primary));
    if (athlete.gender != null)
      chips.add(_ChipData(Icons.person, athlete.gender!, AppColors.vitalBP));
    if (athlete.status != null)
      chips.add(_ChipData(
        Icons.circle,
        athlete.status!,
        athlete.status?.toLowerCase() == 'active'
            ? AppColors.success
            : AppColors.subtext,
      ));

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map((c) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(c.icon, size: 13, color: c.color),
                    const SizedBox(width: 5),
                    Text(c.label,
                        style: TextStyle(
                            color: c.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _ChipData {
  final IconData icon;
  final String label;
  final Color color;
  const _ChipData(this.icon, this.label, this.color);
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
        ],
      );
}

// ── Health Metrics Card ───────────────────────────────────────────────────────

class _HealthMetricsCard extends StatelessWidget {
  final int athleteId;
  const _HealthMetricsCard({required this.athleteId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteHealthMetricsCubit, AthleteHealthMetricsState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Date picker header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_outlined,
                        size: 16, color: AppColors.subtext),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _dateLabel(state),
                        style: const TextStyle(
                            color: AppColors.subtext, fontSize: 13),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _pickRange(context, state, athleteId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune, size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Change',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              _HealthBody(state: state, athleteId: athleteId),
            ],
          ),
        );
      },
    );
  }

  String _dateLabel(AthleteHealthMetricsState state) {
    final from = state.fromDate;
    final to = state.toDate;
    if (from == null || to == null) return 'Select a date range';
    return '${_d(from)}  →  ${_d(to)}';
  }

  String _d(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickRange(
    BuildContext context,
    AthleteHealthMetricsState state,
    int athleteId,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: (state.fromDate != null && state.toDate != null)
          ? DateTimeRange(start: state.fromDate!, end: state.toDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      context.read<AthleteHealthMetricsCubit>().fetchMetrics(
            athleteId,
            fromDate: picked.start,
            toDate: picked.end,
          );
    }
  }
}

// ── Health Body ───────────────────────────────────────────────────────────────

class _HealthBody extends StatelessWidget {
  final AthleteHealthMetricsState state;
  final int athleteId;
  const _HealthBody({required this.state, required this.athleteId});

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case AthleteHealthMetricsStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );

      case AthleteHealthMetricsStatus.error:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    color: AppColors.error, size: 32),
              ),
              const SizedBox(height: 12),
              Text(state.errorMessage ?? 'Load nahi hua',
                  style: const TextStyle(
                      color: AppColors.subtext, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  if (state.fromDate != null && state.toDate != null) {
                    context.read<AthleteHealthMetricsCubit>().fetchMetrics(
                          athleteId,
                          fromDate: state.fromDate!,
                          toDate: state.toDate!,
                        );
                  }
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        );

      case AthleteHealthMetricsStatus.loaded:
        final dailyList = (state.metrics?.raw['data'] as List?) ?? [];
        if (dailyList.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_rounded,
                      color: AppColors.subtext, size: 40),
                  SizedBox(height: 12),
                  Text('Is period mein koi data nahi mila',
                      style:
                          TextStyle(color: AppColors.subtext, fontSize: 13),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        final days =
            dailyList.map((d) => d as Map<String, dynamic>).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Heart Rate line chart (top, prominent)
              if (_hasHR(days)) ...[
                _ChartHeader(
                    icon: Icons.favorite_rounded,
                    title: 'Heart Rate Trend',
                    color: const Color(0xFFEF5350)),
                const SizedBox(height: 10),
                _HRLineChart(days: days),
                const SizedBox(height: 20),
              ],

              // ── Stress line chart
              if (_hasStress(days)) ...[
                _ChartHeader(
                    icon: Icons.psychology_outlined,
                    title: 'Stress Trend',
                    color: AppColors.vitalStress),
                const SizedBox(height: 10),
                _StressLineChart(days: days),
                const SizedBox(height: 20),
              ],

              // ── Daily breakdown
              _ChartHeader(
                  icon: Icons.calendar_today_outlined,
                  title: 'Daily Breakdown',
                  color: AppColors.primary),
              const SizedBox(height: 10),
              for (var i = 0; i < days.length; i++)
                _DailyCard(day: days[i], initiallyExpanded: i == 0),
            ],
          ),
        );

      case AthleteHealthMetricsStatus.initial:
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.date_range_outlined,
                    color: AppColors.subtext, size: 40),
                SizedBox(height: 12),
                Text('Upar se date range select karein',
                    style:
                        TextStyle(color: AppColors.subtext, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
    }
  }

  bool _hasHR(List<Map<String, dynamic>> days) => days.any((d) {
        final stats = d['aggregated_stats'] as Map<String, dynamic>? ?? {};
        return stats['heart_rate'] is Map;
      });

  bool _hasStress(List<Map<String, dynamic>> days) => days.any((d) {
        final stats = d['aggregated_stats'] as Map<String, dynamic>? ?? {};
        final v = stats['stress'];
        return v is num && v > 0;
      });
}

// ── Chart Header ──────────────────────────────────────────────────────────────

class _ChartHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _ChartHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
        ],
      );
}

// ── Heart Rate Line Chart ─────────────────────────────────────────────────────

class _HRLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  const _HRLineChart({required this.days});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFEF5350);

    final entries = <_DayEntry>[];
    for (final d in days) {
      final stats = d['aggregated_stats'] as Map<String, dynamic>? ?? {};
      final hr = stats['heart_rate'];
      if (hr is Map<String, dynamic>) {
        final avg = (hr['avg'] as num?)?.toDouble();
        final min = (hr['min'] as num?)?.toDouble();
        final max = (hr['max'] as num?)?.toDouble();
        if (avg != null) {
          entries.add(_DayEntry(
            dateStr: d['date'] as String? ?? '',
            avg: avg,
            min: min ?? avg,
            max: max ?? avg,
          ));
        }
      }
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    final avgSpots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.avg))
        .toList();
    final maxSpots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.max))
        .toList();
    final minSpots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.min))
        .toList();

    final allVals = entries.expand((e) => [e.min, e.max]);
    final maxY = (allVals.reduce(math.max) + 15).roundToDouble();
    final minY = (allVals.reduce(math.min) - 15).clamp(0.0, double.infinity);

    final overallAvg = entries.map((e) => e.avg).reduce((a, b) => a + b) /
        entries.length;
    final overallMin = entries.map((e) => e.min).reduce(math.min);
    final overallMax = entries.map((e) => e.max).reduce(math.max);

    return _VitalChartCard(
      color: color,
      avgLabel: '${overallAvg.toStringAsFixed(0)} bpm avg',
      statsRow: '↓ ${overallMin.toStringAsFixed(0)}   avg ${overallAvg.toStringAsFixed(0)}   ↑ ${overallMax.toStringAsFixed(0)}',
      unit: 'bpm',
      chart: _buildChart(avgSpots, maxSpots, minSpots, minY, maxY, color,
          entries.map((e) => e.dateStr).toList()),
    );
  }

  Widget _buildChart(
    List<FlSpot> avg,
    List<FlSpot> max,
    List<FlSpot> min,
    double minY,
    double maxY,
    Color color,
    List<String> dates,
  ) {
    return SizedBox(
      height: 160,
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
              horizontalInterval: 20,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: AppColors.borderLight, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  interval: 20,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: const TextStyle(
                          color: AppColors.subtext, fontSize: 10)),
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: dates.length > 10
                      ? (dates.length / 6).ceilToDouble()
                      : 1,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= dates.length || i.toDouble() != v) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _shortDate(dates[i]),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.subtext,
                            fontSize: 9,
                            height: 1.2),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              // max (faded)
              LineChartBarData(
                spots: max,
                isCurved: true,
                curveSmoothness: 0.3,
                color: color.withValues(alpha: 0.25),
                barWidth: 1.5,
                dotData: const FlDotData(show: false),
                dashArray: [4, 4],
              ),
              // avg (solid, prominent)
              LineChartBarData(
                spots: avg,
                isCurved: true,
                curveSmoothness: 0.35,
                color: color,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, index) => FlDotCirclePainter(
                    radius: index == avg.length - 1 ? 5 : 2.5,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
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
              // min (faded)
              LineChartBarData(
                spots: min,
                isCurved: true,
                curveSmoothness: 0.3,
                color: color.withValues(alpha: 0.25),
                barWidth: 1.5,
                dotData: const FlDotData(show: false),
                dashArray: [4, 4],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDate(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      // 2-line label: "Wed\n8 May"
      return '${wd[d.weekday - 1]}\n${d.day} ${mo[d.month - 1]}';
    } catch (_) {
      return '';
    }
  }
}

// ── Stress Line Chart ─────────────────────────────────────────────────────────

class _StressLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  const _StressLineChart({required this.days});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF26A69A);

    final entries = <_SimpleEntry>[];
    for (final d in days) {
      final stats = d['aggregated_stats'] as Map<String, dynamic>? ?? {};
      final v = stats['stress'];
      if (v is num && v > 0) {
        entries.add(_SimpleEntry(
          dateStr: d['date'] as String? ?? '',
          avg: v.toDouble(),
          min: v.toDouble(),
          max: v.toDouble(),
        ));
      }
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    return _SimpleLineChartCard(entries: entries, color: color, unit: '');
  }
}

// ── Reusable simple line chart card ──────────────────────────────────────────

class _SimpleLineChartCard extends StatelessWidget {
  final List<_SimpleEntry> entries;
  final Color color;
  final String unit;
  const _SimpleLineChartCard(
      {required this.entries, required this.color, required this.unit});

  @override
  Widget build(BuildContext context) {
    final spots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.avg))
        .toList();

    final vals = entries.map((e) => e.avg);
    final maxV = vals.reduce(math.max);
    final minV = vals.reduce(math.min);
    final range = maxV - minV;
    final pad = range < 5 ? 5.0 : range * 0.25;
    final maxY = maxV + pad;
    final minY = (minV - pad).clamp(0.0, double.infinity);

    final overallAvg =
        entries.map((e) => e.avg).reduce((a, b) => a + b) / entries.length;
    final overallMin = entries.map((e) => e.min).reduce(math.min);
    final overallMax = entries.map((e) => e.max).reduce(math.max);

    return _VitalChartCard(
      color: color,
      avgLabel:
          '${overallAvg.toStringAsFixed(1)}$unit avg',
      statsRow:
          '↓ ${overallMin.toStringAsFixed(1)}$unit   avg ${overallAvg.toStringAsFixed(1)}$unit   ↑ ${overallMax.toStringAsFixed(1)}$unit',
      unit: unit,
      chart: SizedBox(
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
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppColors.borderLight, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(0),
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
                    reservedSize: 34,
                    interval: entries.length > 10
                        ? (entries.length / 6).ceilToDouble()
                        : 1,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= entries.length || i.toDouble() != v) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _shortDate(entries[i].dateStr),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.subtext,
                              fontSize: 9,
                              height: 1.2),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: color,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, index) => FlDotCirclePainter(
                      radius: index == spots.length - 1 ? 5 : 2.5,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
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
    );
  }

  String _shortDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const m = ['J','F','M','A','M','J','J','A','S','O','N','D'];
      return '${d.day}${m[d.month - 1]}';
    } catch (_) {
      return '';
    }
  }
}

// ── Vital Chart Card (container used by all charts) ───────────────────────────

class _VitalChartCard extends StatelessWidget {
  final Color color;
  final String avgLabel;
  final String statsRow;
  final String unit;
  final Widget chart;
  const _VitalChartCard({
    required this.color,
    required this.avgLabel,
    required this.statsRow,
    required this.unit,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Text(avgLabel,
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(statsRow,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 10)),
              ],
            ),
          ),
          chart,
        ],
      ),
    );
  }
}

// ── Daily Card ────────────────────────────────────────────────────────────────

class _DailyCard extends StatefulWidget {
  final Map<String, dynamic> day;
  final bool initiallyExpanded;
  const _DailyCard({required this.day, this.initiallyExpanded = false});

  @override
  State<_DailyCard> createState() => _DailyCardState();
}

class _DailyCardState extends State<_DailyCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final dateStr = day['date'] as String? ?? '';
    final stats = day['aggregated_stats'] as Map<String, dynamic>? ?? {};

    double? toDouble(dynamic v) =>
        v == null ? null : v is num ? v.toDouble() : double.tryParse(v.toString());
    int? toInt(dynamic v) =>
        v == null ? null : v is num ? v.toInt() : int.tryParse(v.toString());

    Map<String, dynamic>? asMap(String key) {
      final v = stats[key];
      return v is Map<String, dynamic> ? v : null;
    }

    final heartRate = asMap('heart_rate');
    final spo2 = asMap('spo2');
    final bodyTemp = asMap('body_temp');
    final hrv = asMap('hrv');
    final sleep = asMap('sleep');
    final steps = toInt(stats['steps']);
    final calories = toDouble(stats['calories']);
    final stress = toInt(stats['stress']);
    final sleepMinutes =
        stats['sleep'] is num ? (stats['sleep'] as num).toInt() : null;

    final hasAny = heartRate != null ||
        spo2 != null ||
        bodyTemp != null ||
        hrv != null ||
        sleep != null ||
        sleepMinutes != null ||
        steps != null ||
        calories != null ||
        stress != null;

    final hrAvg = heartRate != null ? toDouble(heartRate['avg']) : null;
    final hrMin = heartRate != null ? toDouble(heartRate['min']) : null;
    final hrMax = heartRate != null ? toDouble(heartRate['max']) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tappable header: date + at-a-glance HR + expand chevron
          InkWell(
            onTap: hasAny ? () => setState(() => _expanded = !_expanded) : null,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: _expanded || !hasAny
                      ? Radius.zero
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(_fmtDate(dateStr),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (hrAvg != null && hrAvg > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEF5350).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite,
                                  size: 11, color: Color(0xFFEF5350)),
                              const SizedBox(width: 4),
                              Text('${hrAvg.toStringAsFixed(0)} bpm',
                                  style: const TextStyle(
                                      color: Color(0xFFEF5350),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      if (hasAny) ...[
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.keyboard_arrow_down,
                              size: 18, color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                  if (hrAvg != null && hrMin != null && hrMax != null && hrMax > hrMin) ...[
                    const SizedBox(height: 8),
                    _HrRangeBar(min: hrMin, avg: hrAvg, max: hrMax),
                  ],
                ],
              ),
            ),
          ),

          // Expandable body
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : _ExpandedBody(
                    heartRate: heartRate,
                    spo2: spo2,
                    bodyTemp: bodyTemp,
                    hrv: hrv,
                    sleep: sleep,
                    steps: steps,
                    calories: calories,
                    stress: stress,
                    sleepMinutes: sleepMinutes,
                    hasAny: hasAny,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Inline HR range bar shown in collapsed header ────────────────────────────

class _HrRangeBar extends StatelessWidget {
  final double min, avg, max;
  const _HrRangeBar({required this.min, required this.avg, required this.max});

  @override
  Widget build(BuildContext context) {
    // Bar's domain pinned to [min, max] for the day. Avg marker position
    // shows where the average falls within that range.
    final span = max - min;
    final pct = span > 0 ? ((avg - min) / span).clamp(0.0, 1.0) : 0.5;
    const trackColor = Color(0xFFFCD9D9);
    const fillColor = Color(0xFFEF5350);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(min.toStringAsFixed(0),
                  style: const TextStyle(
                      color: AppColors.subtext, fontSize: 10)),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Positioned(
                    left: ((w - 64) * pct).clamp(0.0, w - 64) - 5,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 18,
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(max.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppColors.subtext, fontSize: 10)),
            ),
          ],
        );
      },
    );
  }
}

// ── Expanded body of daily card ──────────────────────────────────────────────

class _ExpandedBody extends StatelessWidget {
  final Map<String, dynamic>? heartRate, spo2, bodyTemp, hrv, sleep;
  final int? steps, stress, sleepMinutes;
  final double? calories;
  final bool hasAny;

  const _ExpandedBody({
    required this.heartRate,
    required this.spo2,
    required this.bodyTemp,
    required this.hrv,
    required this.sleep,
    required this.steps,
    required this.calories,
    required this.stress,
    required this.sleepMinutes,
    required this.hasAny,
  });

  double? _toDouble(dynamic v) =>
      v == null ? null : v is num ? v.toDouble() : double.tryParse(v.toString());

  @override
  Widget build(BuildContext context) {
    final heartRate = this.heartRate;
    final spo2 = this.spo2;
    final bodyTemp = this.bodyTemp;
    final hrv = this.hrv;
    final sleep = this.sleep;
    final steps = this.steps;
    final calories = this.calories;
    final stress = this.stress;
    final sleepMinutes = this.sleepMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasAny)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('Koi vital data nahi mila',
                  style:
                      TextStyle(color: AppColors.subtext, fontSize: 12)),
            )
          else
            Padding(
              padding: const EdgeInsets.all(10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tileW = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (heartRate != null)
                        _VitalTile(
                          width: tileW,
                          icon: Icons.favorite,
                          label: 'Heart Rate',
                          avg: _toDouble(heartRate['avg']) ?? 0,
                          min: _toDouble(heartRate['min']) ?? 0,
                          max: _toDouble(heartRate['max']) ?? 0,
                          unit: 'bpm',
                          color: const Color(0xFFEF5350),
                        ),
                      if (spo2 != null)
                        _VitalTile(
                          width: tileW,
                          icon: Icons.bloodtype,
                          label: 'SpO2',
                          avg: _toDouble(spo2['avg']) ?? 0,
                          min: _toDouble(spo2['min']) ?? 0,
                          max: _toDouble(spo2['max']) ?? 0,
                          unit: '%',
                          color: const Color(0xFF5C6BC0),
                        ),
                      if (bodyTemp != null)
                        _VitalTile(
                          width: tileW,
                          icon: Icons.thermostat,
                          label: 'Body Temp',
                          avg: _toDouble(bodyTemp['avg']) ?? 0,
                          min: _toDouble(bodyTemp['min']) ?? 0,
                          max: _toDouble(bodyTemp['max']) ?? 0,
                          unit: '°C',
                          color: const Color(0xFFD97706),
                        ),
                      if (hrv != null)
                        _VitalTile(
                          width: tileW,
                          icon: Icons.monitor_heart_outlined,
                          label: 'HRV',
                          avg: _toDouble(hrv['avg']) ?? 0,
                          min: _toDouble(hrv['min']) ?? 0,
                          max: _toDouble(hrv['max']) ?? 0,
                          unit: 'ms',
                          color: AppColors.primary,
                        ),
                      if (steps != null)
                        _SimpleTile(
                          width: tileW,
                          icon: Icons.directions_walk,
                          label: 'Steps',
                          value: '$steps',
                          color: AppColors.primary,
                        ),
                      if (calories != null)
                        _SimpleTile(
                          width: tileW,
                          icon: Icons.local_fire_department,
                          label: 'Calories',
                          value: calories.toStringAsFixed(0),
                          color: const Color(0xFFE65100),
                        ),
                      if (stress != null)
                        _SimpleTile(
                          width: tileW,
                          icon: Icons.psychology,
                          label: 'Stress',
                          value: '$stress',
                          color: const Color(0xFF26A69A),
                        ),
                      if (sleep != null)
                        _SleepTile(width: tileW, sleep: sleep),
                      if (sleepMinutes != null && sleep == null)
                        _SimpleTile(
                          width: tileW,
                          icon: Icons.bedtime_outlined,
                          label: 'Sleep',
                          value: _fmtSleep(sleepMinutes),
                          color: const Color(0xFF7B1FA2),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
    );
  }
}

String _fmtDate(String raw) {
  try {
    final d = DateTime.parse(raw);
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  } catch (_) {
    return raw;
  }
}

String _fmtSleep(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

// ── Vital Tile ────────────────────────────────────────────────────────────────

class _VitalTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final double avg, min, max;
  final String unit;
  final Color color;

  const _VitalTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.avg,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(avg.toStringAsFixed(1),
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(children: [
            _MiniChip(
                text: '↓ ${min.toStringAsFixed(0)}', color: color),
            const SizedBox(width: 4),
            _MiniChip(
                text: '↑ ${max.toStringAsFixed(0)}', color: color),
          ]),
        ],
      ),
    );
  }
}

// ── Simple Tile ───────────────────────────────────────────────────────────────

class _SimpleTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label, value;
  final Color color;

  const _SimpleTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1)),
        ],
      ),
    );
  }
}

// ── Sleep Tile ────────────────────────────────────────────────────────────────

class _SleepTile extends StatelessWidget {
  final double width;
  final Map<String, dynamic> sleep;
  const _SleepTile({required this.width, required this.sleep});

  String _fmtMin(num? minutes) {
    if (minutes == null) return '--';
    final h = minutes.toInt() ~/ 60;
    final m = minutes.toInt() % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF7B1FA2);
    final total = sleep['total_duration_minutes'] as num? ??
        sleep['total_sleep_minutes'] as num? ??
        sleep['duration_minutes'] as num? ??
        sleep['total'] as num?;
    final deep =
        sleep['deep_sleep_minutes'] as num? ?? sleep['deep'] as num?;
    final light =
        sleep['light_sleep_minutes'] as num? ?? sleep['light'] as num?;

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bedtime_outlined, size: 13, color: color),
            const SizedBox(width: 5),
            const Text('Sleep',
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(_fmtMin(total),
              style: const TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1)),
          if (deep != null || light != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              if (deep != null)
                _MiniChip(text: 'Deep ${_fmtMin(deep)}', color: color),
              if (deep != null && light != null) const SizedBox(width: 4),
              if (light != null)
                _MiniChip(text: 'Light ${_fmtMin(light)}', color: color),
            ]),
          ],
        ],
      ),
    );
  }
}

// ── Mini Chip ─────────────────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final visible = items.where((i) => i.value != null).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(visible.length, (i) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(visible[i].label,
                          style: const TextStyle(
                              color: AppColors.subtext, fontSize: 13)),
                    ),
                    Expanded(
                      child: Text(visible[i].value!,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              if (i < visible.length - 1)
                const Divider(height: 1, color: AppColors.borderLight),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String? value;
  const _InfoRow(this.label, this.value);
}

// ── Loading Banner ────────────────────────────────────────────────────────────

class _LoadingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
          SizedBox(width: 10),
          Text('Loading full details...',
              style: TextStyle(color: AppColors.primary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _DayEntry {
  final String dateStr;
  final double avg, min, max;
  const _DayEntry(
      {required this.dateStr,
      required this.avg,
      required this.min,
      required this.max});
}

class _SimpleEntry {
  final String dateStr;
  final double avg, min, max;
  const _SimpleEntry(
      {required this.dateStr,
      required this.avg,
      required this.min,
      required this.max});
}
