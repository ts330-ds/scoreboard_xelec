import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

import 'sleep_from_hr.dart';

class SleepHrChart extends StatelessWidget {
  final SleepResult sleep;
  const SleepHrChart({super.key, required this.sleep});

  static const _deepColor = Color(0xFF1A237E);
  static const _lightColor = Color(0xFF5C6BC0);
  static const _remColor = Color(0xFFAB47BC);
  static const _awakeColor = Color(0xFFFF7043);

  static Color stageColor(int stage) {
    switch (stage) {
      case SleepStage.deep:
        return _deepColor;
      case SleepStage.light:
        return _lightColor;
      case SleepStage.rem:
        return _remColor;
      case SleepStage.awake:
        return _awakeColor;
      default:
        return AppColors.subtext;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('hh:mm a');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: _deepColor.withValues(alpha: 0.06),
            blurRadius: 14,
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
                const Icon(Icons.bedtime_outlined,
                    size: 16, color: _deepColor),
                const SizedBox(width: 6),
                const Text(
                  'Sleep Analysis',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  sleep.totalLabel,
                  style: const TextStyle(
                    color: _deepColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // Bed/wake time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${timeFmt.format(sleep.bedTime)} → ${timeFmt.format(sleep.wakeTime)}',
              style: TextStyle(
                color: AppColors.subtext.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Stage bar (stacked horizontal)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SleepStageBar(sleep: sleep),
          ),
          const SizedBox(height: 8),
          // Swipe hint
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.swipe_outlined,
                    size: 12,
                    color: AppColors.subtext.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text('Swipe to scroll',
                    style: TextStyle(
                        color: AppColors.subtext.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Hypnogram — scrollable chart
          SizedBox(
            height: 180,
            child: _ScrollableHypnogram(minutes: sleep.minutes),
          ),
          const SizedBox(height: 10),
          // Stage breakdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                _StageStat(
                    label: 'Deep',
                    time: sleep.deepLabel,
                    pct: sleep.deepPct,
                    color: _deepColor),
                _StageStat(
                    label: 'Light',
                    time: sleep.lightLabel,
                    pct: sleep.lightPct,
                    color: _lightColor),
                _StageStat(
                    label: 'REM',
                    time: sleep.remLabel,
                    pct: sleep.remPct,
                    color: _remColor),
                _StageStat(
                    label: 'Awake',
                    time: sleep.awakeLabel,
                    pct: sleep.awakePct,
                    color: _awakeColor),
              ].map((w) => Expanded(child: w)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stage bar (horizontal stacked) ─────────────────────────────────────────

class _SleepStageBar extends StatelessWidget {
  final SleepResult sleep;
  const _SleepStageBar({required this.sleep});

  @override
  Widget build(BuildContext context) {
    final total = sleep.totalMin;
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (sleep.deepMin > 0)
              Expanded(
                flex: sleep.deepMin,
                child: Container(color: SleepHrChart._deepColor),
              ),
            if (sleep.lightMin > 0)
              Expanded(
                flex: sleep.lightMin,
                child: Container(color: SleepHrChart._lightColor),
              ),
            if (sleep.remMin > 0)
              Expanded(
                flex: sleep.remMin,
                child: Container(color: SleepHrChart._remColor),
              ),
            if (sleep.awakeMin > 0)
              Expanded(
                flex: sleep.awakeMin,
                child: Container(color: SleepHrChart._awakeColor),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Scrollable Hypnogram using fl_chart ────────────────────────────────────

class _ScrollableHypnogram extends StatelessWidget {
  final List<SleepMinute> minutes;
  const _ScrollableHypnogram({required this.minutes});

  // Stage → y value (Awake=top=3, Deep=bottom=0)
  static double _stageY(int stage) {
    switch (stage) {
      case SleepStage.awake:
        return 3.0;
      case SleepStage.rem:
        return 2.0;
      case SleepStage.light:
        return 1.0;
      case SleepStage.deep:
        return 0.0;
      default:
        return 1.0;
    }
  }

  static String _stageLabel(double v) {
    final i = v.round();
    switch (i) {
      case 3:
        return 'Awake';
      case 2:
        return 'REM';
      case 1:
        return 'Light';
      case 0:
        return 'Deep';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (minutes.isEmpty) return const SizedBox.shrink();

    final firstMs = minutes.first.time.millisecondsSinceEpoch;

    // Build spots — each minute gets an x = minutes elapsed from start
    // Use step-wise: for each minute, add TWO spots (horizontal then vertical)
    final spots = <FlSpot>[];
    for (int i = 0; i < minutes.length; i++) {
      final x = (minutes[i].time.millisecondsSinceEpoch - firstMs) / 60000.0;
      final y = _stageY(minutes[i].stage);
      if (i > 0) {
        // Horizontal step to current x at previous y
        final prevY = _stageY(minutes[i - 1].stage);
        if (prevY != y) {
          spots.add(FlSpot(x, prevY));
        }
      }
      spots.add(FlSpot(x, y));
    }

    final maxX = spots.last.x;
    final screenWidth = MediaQuery.of(context).size.width - 32 - 50;
    const pxPerMin = 3.0;
    final chartWidth = math.max(screenWidth, maxX * pxPerMin);

    // Time label interval — show every 30 min
    const double timeInterval = 30;

    // Build colored bar annotations per stage run
    final barAnnotations = <VerticalRangeAnnotation>[];
    int runStart = 0;
    for (int i = 1; i <= minutes.length; i++) {
      if (i == minutes.length || minutes[i].stage != minutes[runStart].stage) {
        final x0 =
            (minutes[runStart].time.millisecondsSinceEpoch - firstMs) / 60000.0;
        final x1 = (minutes[i == minutes.length ? i - 1 : i]
                        .time.millisecondsSinceEpoch -
                    firstMs) /
                60000.0 +
            (i == minutes.length ? 1 : 0);
        barAnnotations.add(VerticalRangeAnnotation(
          x1: x0,
          x2: x1,
          color: SleepHrChart.stageColor(minutes[runStart].stage)
              .withValues(alpha: 0.10),
        ));
        runStart = i;
      }
    }

    return Row(
      children: [
        // Fixed y-axis
        SizedBox(
          width: 50,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: LineChart(
              LineChartData(
                minY: -0.5,
                maxY: 3.5,
                minX: 0,
                maxX: 1,
                lineBarsData: [],
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final label = _stageLabel(v);
                        if (label.isEmpty) return const SizedBox.shrink();
                        return Text(label,
                            style: TextStyle(
                                color: SleepHrChart.stageColor(v.round() == 3
                                        ? SleepStage.awake
                                        : v.round() == 2
                                            ? SleepStage.rem
                                            : v.round() == 1
                                                ? SleepStage.light
                                                : SleepStage.deep)
                                    .withValues(alpha: 0.8),
                                fontSize: 9,
                                fontWeight: FontWeight.w600));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
        ),
        // Scrollable chart
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: chartWidth,
                child: LineChart(
                  LineChartData(
                    minY: -0.5,
                    maxY: 3.5,
                    minX: -2,
                    maxX: maxX + 2,
                    clipData: const FlClipData.none(),
                    rangeAnnotations: RangeAnnotations(
                      verticalRangeAnnotations: barAnnotations,
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        color: SleepHrChart._deepColor,
                        barWidth: 2.2,
                        isCurved: false,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              SleepHrChart._awakeColor
                                  .withValues(alpha: 0.05),
                              SleepHrChart._deepColor
                                  .withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                    ],
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 1,
                      verticalInterval: timeInterval,
                      getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.borderLight, strokeWidth: 0.8),
                      getDrawingVerticalLine: (_) => FlLine(
                          color: AppColors.borderLight.withValues(alpha: 0.5),
                          strokeWidth: 0.5),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: timeInterval,
                          getTitlesWidget: (val, _) {
                            if (val < 0 || val > maxX) {
                              return const SizedBox.shrink();
                            }
                            final ms =
                                firstMs + (val * 60000).toInt();
                            final dt =
                                DateTime.fromMillisecondsSinceEpoch(ms);
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                DateFormat('HH:mm').format(dt),
                                style: const TextStyle(
                                    color: AppColors.subtext,
                                    fontSize: 9),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppColors.surface,
                        getTooltipItems: (touched) => touched.map((s) {
                          final ms =
                              firstMs + (s.x * 60000).toInt();
                          final dt =
                              DateTime.fromMillisecondsSinceEpoch(ms);
                          final stage = _stageLabel(s.y);
                          return LineTooltipItem(
                            '${DateFormat('HH:mm').format(dt)}\n$stage',
                            TextStyle(
                              color: SleepHrChart.stageColor(s.y.round() == 3
                                      ? SleepStage.awake
                                      : s.y.round() == 2
                                          ? SleepStage.rem
                                          : s.y.round() == 1
                                              ? SleepStage.light
                                              : SleepStage.deep),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stage stat tile ────────────────────────────────────────────────────────

class _StageStat extends StatelessWidget {
  final String label;
  final String time;
  final int pct;
  final Color color;
  const _StageStat({
    required this.label,
    required this.time,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.subtext,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 2),
        Text(time,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        Text('$pct%',
            style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
