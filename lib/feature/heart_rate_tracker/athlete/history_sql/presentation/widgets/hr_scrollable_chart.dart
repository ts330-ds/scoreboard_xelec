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
  // Card ka background — default surface (white). Activity task-result screen
  // ise light-blue tint se use karta hai; history tab default rakhta hai.
  final Color backgroundColor;
  // Jab true ho, y-axis ki horizontal guide-lines (har [yInterval]=8 bpm pe)
  // darker/clear dikhti hain — history HR chart isse on rakhta hai taaki value
  // padhna aasan ho. Baaki charts (activity result) default faint rakhte hain.
  final bool emphasizeYGrid;
  const HrScrollableChart({
    super.key,
    required this.readings,
    this.backgroundColor = AppColors.surface,
    this.emphasizeYGrid = false,
  });

  static const _gapThresholdMin = 5.0;
  static const _segmentGapMin = 2.0;
  // Dense 1-reading/sec data ko curve pe smooth dikhane ke liye ~15s ke buckets
  // me average karke downsample karte hain — warna itne paas-paas points par
  // spline curve spiky lagti hai (curve dikhti hi nahi). Display-only — MAX/MIN/
  // AVG tiles alag stats se aate hain, in numbers pe koi asar nahi.
  static const _downsampleBucketMs = 15000;
  // Y-axis sub-line spacing (major 8-line ke beech ki halki minor lines).
  static const _ySubInterval = 2.0;

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
      final raw = rawSegments[si];
      if (raw.isEmpty) continue;
      final seg = _downsample(raw);
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
    // Y-ticks 8 ke multiples pe — taaki 8-gap labels clean (56, 64, 72…) rahen.
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

  /// Dense per-second readings ko ~15s buckets me average karke kam points
  /// banata hai — taaki curved line visibly smooth dikhe (spiky nahi). Chhote
  /// segments (4 se kam points) jaise ke taise return hote hain.
  List<({int ms, double hr})> _downsample(List<({int ms, double hr})> pts) {
    if (pts.length < 4) return pts;
    final out = <({int ms, double hr})>[];
    int bucketStartMs = pts.first.ms;
    int firstMs = pts.first.ms;
    int lastMs = pts.first.ms;
    double sum = 0;
    int n = 0;
    for (final p in pts) {
      if (p.ms - bucketStartMs >= _downsampleBucketMs && n > 0) {
        out.add((ms: (firstMs + lastMs) ~/ 2, hr: sum / n));
        bucketStartMs = p.ms;
        firstMs = p.ms;
        sum = 0;
        n = 0;
      }
      sum += p.hr;
      lastMs = p.ms;
      n++;
    }
    if (n > 0) out.add((ms: (firstMs + lastMs) ~/ 2, hr: sum / n));
    return out;
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
          color: backgroundColor,
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

    // X-axis unit = minutes → har 2 min pe label + vertical gridline.
    const double xInterval = 2.0;

    // Segment ke beech ke gap ko ab shaded band ki jagah DOTTED line se dikhate
    // hain — pichle segment ke aakhri point se agle segment ke pehle point tak
    // ek dashed connector, taaki user ko missing-data window clearly samajh aaye.
    final gapConnectors = <LineChartBarData>[];
    for (int i = 0; i < data.segments.length - 1; i++) {
      final gapStart = data.segments[i].last;
      final gapEnd = data.segments[i + 1].first;
      gapConnectors.add(LineChartBarData(
        spots: [gapStart, gapEnd],
        color: AppColors.heartRed.withValues(alpha: 0.45),
        barWidth: 1.6,
        isCurved: false,
        dashArray: const [4, 4],
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
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
                            lineBarsData: [
                              ...gapConnectors,
                              ...data.segments
                                .map((seg) => LineChartBarData(
                                      spots: seg,
                                      color: AppColors.heartRed,
                                      barWidth: 2.2,
                                      isCurved: true,
                                      // Zyada smooth/curvy line — 0.2 thodi
                                      // sharp lag rahi thi. Overshoot guard se
                                      // peaks band ke actual max/min se bahar
                                      // nahi jaati.
                                      curveSmoothness: 0.4,
                                      preventCurveOverShooting: true,
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
                                    )),
                            ],
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              verticalInterval: xInterval,
                              // History pe sub-lines: interval chhota (2) rakho;
                              // 8-ke-multiple = major (darker), beech wali = sub
                              // (halki). Baaki charts sirf 8-interval single line.
                              horizontalInterval:
                                  emphasizeYGrid ? _ySubInterval : yInterval,
                              getDrawingHorizontalLine: (value) {
                                if (!emphasizeYGrid) {
                                  return const FlLine(
                                    color: AppColors.borderLight,
                                    strokeWidth: 1,
                                  );
                                }
                                final isMajor =
                                    value.round() % yInterval.toInt() == 0;
                                return isMajor
                                    ? const FlLine(
                                        color: AppColors.border,
                                        strokeWidth: 1.2,
                                      )
                                    : FlLine(
                                        color: AppColors.borderLight
                                            .withValues(alpha: 0.45),
                                        strokeWidth: 0.5,
                                      );
                              },
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
