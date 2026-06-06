import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

import 'history_data_utils.dart';

const Color _hrColor = AppColors.heartRed;

class DailyTrendChart extends StatefulWidget {
  final List<DailyStats> stats;
  const DailyTrendChart({super.key, required this.stats});

  @override
  State<DailyTrendChart> createState() => _DailyTrendChartState();
}

class _DailyTrendChartState extends State<DailyTrendChart> {
  bool _show30 = false;

  @override
  Widget build(BuildContext context) {
    final allStats = widget.stats;
    final maxDays = _show30 ? 30 : 7;
    final stats = allStats.length > maxDays
        ? allStats.sublist(allStats.length - maxDays)
        : allStats;

    if (stats.isEmpty) return const SizedBox.shrink();

    final allValues = stats.expand((s) => [s.avg, s.max, s.min]);
    final dataMax = allValues.reduce(math.max).toDouble();
    final dataMin = allValues.reduce(math.min).toDouble();

    final yFloor = ((dataMin - 4) / 2).floor() * 2.0;
    final yCeil = ((dataMax + 4) / 2).ceil() * 2.0;
    const double yInterval = 2;

    final avgSpots = <FlSpot>[];
    final maxSpots = <FlSpot>[];
    final minSpots = <FlSpot>[];
    for (var i = 0; i < stats.length; i++) {
      avgSpots.add(FlSpot(i.toDouble(), stats[i].avg.toDouble()));
      maxSpots.add(FlSpot(i.toDouble(), stats[i].max.toDouble()));
      minSpots.add(FlSpot(i.toDouble(), stats[i].min.toDouble()));
    }

    final screenWidth = MediaQuery.of(context).size.width - 72;
    const pxPerDay = 50.0;
    final calculatedWidth = stats.length * pxPerDay;
    final chartWidth = math.max(calculatedWidth, screenWidth);

    final double labelInterval;
    if (stats.length <= 10) {
      labelInterval = 1;
    } else if (stats.length <= 20) {
      labelInterval = 2;
    } else {
      labelInterval = (stats.length / 8).ceilToDouble();
    }

    final dayFmt = DateFormat('dd/MM');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: _hrColor.withValues(alpha: 0.06),
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
              children: [
                _ChipToggle(
                    label: '7 Days',
                    selected: !_show30,
                    onTap: () => setState(() => _show30 = false)),
                const SizedBox(width: 8),
                _ChipToggle(
                    label: '30 Days',
                    selected: _show30,
                    onTap: () => setState(() => _show30 = true)),
                const Spacer(),
                _LegendDot(color: _hrColor, label: 'Avg', solid: true),
                const SizedBox(width: 10),
                _LegendDot(
                    color: _hrColor.withValues(alpha: 0.5),
                    label: 'Min / Max',
                    solid: false),
              ],
            ),
          ),
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
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Fixed y-axis
                SizedBox(
                  width: 40,
                  child: LineChart(
                    LineChartData(
                      minY: yFloor,
                      maxY: yCeil,
                      minX: 0,
                      maxX: 1,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: yInterval,
                            getTitlesWidget: (v, _) => Text(
                                v.toStringAsFixed(0),
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
                            reservedSize: 32,
                            getTitlesWidget: (_, __) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      lineTouchData: const LineTouchData(enabled: false),
                    ),
                  ),
                ),
                // Scrollable chart
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
                            minY: yFloor,
                            maxY: yCeil,
                            minX: -0.3,
                            maxX: (stats.length - 1).toDouble() + 0.3,
                            clipData: const FlClipData.none(),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: yInterval,
                              verticalInterval: labelInterval,
                              getDrawingHorizontalLine: (_) => FlLine(
                                  color: AppColors.borderLight,
                                  strokeWidth: 1),
                              getDrawingVerticalLine: (_) => FlLine(
                                  color: AppColors.borderLight
                                      .withValues(alpha: 0.5),
                                  strokeWidth: 0.5),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: labelInterval,
                                  getTitlesWidget: (v, _) {
                                    final i = v.toInt();
                                    if (i < 0 ||
                                        i >= stats.length ||
                                        i.toDouble() != v) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(top: 4),
                                      child: Text(
                                        dayFmt.format(stats[i].date),
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
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => AppColors.surface,
                                getTooltipItems: (touched) =>
                                    touched.map((s) {
                                  final i = s.spotIndex;
                                  if (i < 0 || i >= stats.length) {
                                    return null;
                                  }
                                  final e = stats[i];
                                  return LineTooltipItem(
                                    '${e.avg} bpm\n↓${e.min} ↑${e.max}',
                                    const TextStyle(
                                        color: _hrColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11),
                                  );
                                }).toList(),
                              ),
                            ),
                            lineBarsData: [
                              // Max — dashed
                              LineChartBarData(
                                spots: maxSpots,
                                isCurved: true,
                                curveSmoothness: 0.3,
                                color: _hrColor.withValues(alpha: 0.25),
                                barWidth: 1.5,
                                dotData: const FlDotData(show: false),
                                dashArray: [4, 4],
                              ),
                              // Avg — main line with gradient fill
                              LineChartBarData(
                                spots: avgSpots,
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: _hrColor,
                                barWidth: 2.6,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (s, _, __, index) =>
                                      FlDotCirclePainter(
                                    radius:
                                        index == avgSpots.length - 1
                                            ? 5
                                            : 2.6,
                                    color: _hrColor,
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
                                      _hrColor.withValues(alpha: 0.18),
                                      _hrColor.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              // Min — dashed
                              LineChartBarData(
                                spots: minSpots,
                                isCurved: true,
                                curveSmoothness: 0.3,
                                color: _hrColor.withValues(alpha: 0.25),
                                barWidth: 1.5,
                                dotData: const FlDotData(show: false),
                                dashArray: [4, 4],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _LegendDot(color: _hrColor, label: 'Avg', solid: true),
                const SizedBox(width: 14),
                _LegendDot(
                    color: _hrColor.withValues(alpha: 0.6),
                    label: 'Min / Max',
                    solid: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipToggle(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppColors.subtext,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool solid;
  const _LegendDot(
      {required this.color, required this.label, required this.solid});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: solid ? color : null,
            borderRadius: BorderRadius.circular(2),
            border: solid ? null : Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: AppColors.subtext, fontSize: 9)),
      ],
    );
  }
}
