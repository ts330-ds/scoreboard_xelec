import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

import '../../../history/presentation/widgets/history_data_utils.dart'
    show pad2;

/// Scrollable HR line chart (fixed y-axis, time on x-axis, newest on the left).
/// Behaviour mirrors the original Hive screen's chart, but is fed per-day
/// readings fetched from SQLite.
class HrScrollableChart extends StatelessWidget {
  final List<Map<dynamic, dynamic>> readings;
  const HrScrollableChart({super.key, required this.readings});

  static const _gapThresholdMin = 5.0;
  static const _segmentGapMin = 2.0;

  ({
    List<List<FlSpot>> segments,
    List<int> segmentStartMs,
    List<double> segmentDurations,
    double maxX,
    double minY,
    double maxY,
  }) _buildSpots() {
    if (readings.isEmpty) {
      return (segments: [], segmentStartMs: [], segmentDurations: [], maxX: 0, minY: 0, maxY: 100);
    }

    final rawPoints = <({int ms, double hr})>[];
    for (final r in readings) {
      final s = (r['stamp'] as num?)?.toInt() ?? 0;
      final hr = (r['heartRate'] as num?)?.toDouble() ?? 0;
      if (s <= 0 || hr <= 0) continue;
      final ms = s > 9999999999 ? s : s * 1000;
      rawPoints.add((ms: ms, hr: hr));
    }

    if (rawPoints.isEmpty) {
      return (segments: [], segmentStartMs: [], segmentDurations: [], maxX: 0, minY: 0, maxY: 100);
    }

    final rawSegments = <List<({int ms, double hr})>>[];
    var current = <({int ms, double hr})>[rawPoints.first];
    for (int i = 1; i < rawPoints.length; i++) {
      final gapMin = (rawPoints[i].ms - rawPoints[i - 1].ms) / 60000.0;
      if (gapMin > _gapThresholdMin) {
        rawSegments.add(current);
        current = [];
      }
      current.add(rawPoints[i]);
    }
    rawSegments.add(current);

    final segments = <List<FlSpot>>[];
    final segmentStartMs = <int>[];
    final segmentDurations = <double>[];
    double xOffset = 0;

    // Latest segment first — reverse order so newest data is on left
    for (int si = rawSegments.length - 1; si >= 0; si--) {
      final seg = rawSegments[si];
      if (seg.isEmpty) continue;
      final segFirstMs = seg.first.ms;
      segmentStartMs.add(segFirstMs);
      final segDuration = (seg.last.ms - segFirstMs) / 60000.0;
      segmentDurations.add(segDuration);
      final spots = seg.map((p) {
        final localMin = (p.ms - segFirstMs) / 60000.0;
        return FlSpot(xOffset + (segDuration - localMin), p.hr);
      }).toList()
        ..sort((a, b) => a.x.compareTo(b.x));
      segments.add(spots);
      xOffset += segDuration + _segmentGapMin;
    }

    final allY = segments.expand((s) => s.map((p) => p.y)).toList();
    final rawMin = allY.reduce(math.min);
    final rawMax = allY.reduce(math.max);
    final minY = ((rawMin - 4) / 8).floor() * 8.0;
    final maxY = ((rawMax + 4) / 8).ceil() * 8.0;
    final maxX = xOffset > _segmentGapMin ? xOffset - _segmentGapMin : 0.0;

    return (
      segments: segments,
      segmentStartMs: segmentStartMs,
      segmentDurations: segmentDurations,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  int _xToMs(
    double x,
    List<List<FlSpot>> segments,
    List<int> segmentStartMs,
    List<double> segmentDurations,
  ) {
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.isEmpty) continue;
      if (x >= seg.first.x && x <= seg.last.x) {
        final localMin = x - seg.first.x;
        final realMin = segmentDurations[i] - localMin;
        return segmentStartMs[i] + (realMin * 60000).toInt();
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('No data', style: TextStyle(color: AppColors.subtext)),
        ),
      );
    }

    final data = _buildSpots();
    if (data.segments.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width - 32 - 42;
    final chartWidth = math.max(screenWidth, data.maxX * 40.0);
    const double yInterval = 8;
    final yLabelCount = ((data.maxY - data.minY) / yInterval).ceil() + 1;
    const double pxPerLabel = 18.0;
    final chartHeight = math.max(220.0, yLabelCount * pxPerLabel);

    // One x-axis label roughly every ~64px so dense days don't overlap.
    final span = data.maxX <= 0 ? 1.0 : data.maxX;
    final approxLabels = chartWidth / 64.0;
    final xInterval = math.max(1.0, (span / math.max(1.0, approxLabels)));

    final gapAnnotations = <VerticalRangeAnnotation>[];
    for (int i = 0; i < data.segments.length - 1; i++) {
      final gapStart = data.segments[i].last.x;
      final gapEnd = data.segments[i + 1].first.x;
      gapAnnotations.add(VerticalRangeAnnotation(
        x1: gapStart,
        x2: gapEnd,
        color: AppColors.subtext.withValues(alpha: 0.07),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.heartRed.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: const [
                Icon(Icons.show_chart_rounded,
                    size: 14, color: AppColors.heartRed),
                SizedBox(width: 6),
                Text(
                  'Heart Rate',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.swipe_outlined,
                    size: 12, color: AppColors.subtext.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text('Swipe to scroll',
                    style: TextStyle(
                        color: AppColors.subtext.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            height: chartHeight,
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 26),
                    child: LineChart(
                      LineChartData(
                        minY: data.minY,
                        maxY: data.maxY,
                        minX: 0,
                        maxX: 1,
                        lineBarsData: const [],
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                              interval: yInterval,
                              getTitlesWidget: (v, _) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  '${v.toInt()}',
                                  style: const TextStyle(
                                    color: AppColors.subtext,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        lineTouchData: const LineTouchData(enabled: false),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: chartWidth,
                        child: LineChart(
                          LineChartData(
                            minY: data.minY,
                            maxY: data.maxY,
                            minX: -0.5,
                            maxX: data.maxX + 0.5,
                            clipData: const FlClipData.none(),
                            rangeAnnotations: RangeAnnotations(
                              verticalRangeAnnotations: gapAnnotations,
                            ),
                            lineBarsData: data.segments
                                .map((seg) => LineChartBarData(
                                      spots: seg,
                                      color: AppColors.heartRed,
                                      barWidth: 2.2,
                                      isCurved: true,
                                      curveSmoothness: 0.2,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            AppColors.heartRed
                                                .withValues(alpha: 0.18),
                                            AppColors.heartRed
                                                .withValues(alpha: 0.0),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              verticalInterval: xInterval,
                              horizontalInterval: yInterval,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.borderLight,
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (_) => FlLine(
                                color: AppColors.borderLight
                                    .withValues(alpha: 0.5),
                                strokeWidth: 0.5,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: xInterval,
                                  getTitlesWidget: (val, _) {
                                    final ms = _xToMs(
                                      val,
                                      data.segments,
                                      data.segmentStartMs,
                                      data.segmentDurations,
                                    );
                                    if (ms == 0) {
                                      return const SizedBox.shrink();
                                    }
                                    final dt = DateTime
                                        .fromMillisecondsSinceEpoch(ms);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '${pad2(dt.hour)}:${pad2(dt.minute)}',
                                        style: const TextStyle(
                                          color: AppColors.subtext,
                                          fontSize: 8,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => AppColors.surface,
                                getTooltipItems: (touchedSpots) =>
                                    touchedSpots.map((s) {
                                  final ms = _xToMs(
                                    s.x,
                                    data.segments,
                                    data.segmentStartMs,
                                    data.segmentDurations,
                                  );
                                  final dt = DateTime
                                      .fromMillisecondsSinceEpoch(ms);
                                  return LineTooltipItem(
                                    '${pad2(dt.hour)}:${pad2(dt.minute)}:${pad2(dt.second)}\n${s.y.toStringAsFixed(0)} bpm',
                                    const TextStyle(
                                      color: AppColors.heartRed,
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
            ),
          ),
        ],
      ),
    );
  }
}
