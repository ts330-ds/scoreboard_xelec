import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

import 'history_data_utils.dart';

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

    final allValues = stats.expand((s) => [s.avg, s.max, s.min]).toList();
    final minY = (allValues.reduce(math.min) - 10).clamp(0, 9999).toDouble();
    final maxY = (allValues.reduce(math.max) + 10).toDouble();
    final dayFmt = DateFormat('dd/MM');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
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
              _LegendDot(color: AppColors.primary, label: 'Avg'),
              const SizedBox(width: 8),
              _LegendDot(color: AppColors.heartRed, label: 'Max'),
              const SizedBox(width: 8),
              _LegendDot(color: AppColors.vitalStress, label: 'Min'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  _lineData(
                      stats
                          .asMap()
                          .entries
                          .map((e) =>
                              FlSpot(e.key.toDouble(), e.value.avg.toDouble()))
                          .toList(),
                      AppColors.primary,
                      2.5),
                  _lineData(
                      stats
                          .asMap()
                          .entries
                          .map((e) =>
                              FlSpot(e.key.toDouble(), e.value.max.toDouble()))
                          .toList(),
                      AppColors.heartRed,
                      1.5),
                  _lineData(
                      stats
                          .asMap()
                          .entries
                          .map((e) =>
                              FlSpot(e.key.toDouble(), e.value.min.toDouble()))
                          .toList(),
                      AppColors.vitalStress,
                      1.5),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY - minY) / 4).clamp(1, 9999),
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.borderLight, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: stats.length <= 7
                          ? 1
                          : (stats.length / 5).ceilToDouble(),
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= stats.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(dayFmt.format(stats[idx].date),
                              style: const TextStyle(
                                  color: AppColors.subtext, fontSize: 8)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: ((maxY - minY) / 4).clamp(1, 9999),
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: const TextStyle(
                              color: AppColors.subtext, fontSize: 9)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(0)} bpm',
                              TextStyle(
                                  color: s.bar.color ?? AppColors.text,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineData(List<FlSpot> spots, Color color, double width) {
    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: width,
      isCurved: true,
      dotData: FlDotData(show: spots.length <= 10),
      belowBarData: BarAreaData(show: false),
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
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(color: AppColors.subtext, fontSize: 9)),
      ],
    );
  }
}
