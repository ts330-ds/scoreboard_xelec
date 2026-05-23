import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

import 'history_data_utils.dart';

class PeakHoursSection extends StatelessWidget {
  final int peakHour;
  final int peakAvg;
  final List<int> hourlyAvg;
  const PeakHoursSection({
    super.key,
    required this.peakHour,
    required this.peakAvg,
    required this.hourlyAvg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.heartRed.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.heartRed.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.heartRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.schedule,
                      color: AppColors.heartRed, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Peak Hour',
                          style: TextStyle(
                              color: AppColors.subtext, fontSize: 11)),
                      Text(
                        '${formatHour(peakHour)} – ${formatHour((peakHour + 1) % 24)}',
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$peakAvg',
                        style: const TextStyle(
                            color: AppColors.heartRed,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const Text('avg bpm',
                        style:
                            TextStyle(color: AppColors.subtext, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: BarChart(
              BarChartData(
                maxY: (hourlyAvg.reduce(math.max) + 10).toDouble(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    getTooltipItem: (group, gIdx, rod, rIdx) => BarTooltipItem(
                      '${formatHour(group.x)}\n${rod.toY.toInt()} bpm',
                      const TextStyle(
                          color: AppColors.text,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
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
                      reservedSize: 16,
                      interval: 6,
                      getTitlesWidget: (val, _) {
                        final h = val.toInt();
                        if (h % 6 != 0) return const SizedBox.shrink();
                        return Text('${h}h',
                            style: const TextStyle(
                                color: AppColors.subtext, fontSize: 8));
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(24, (h) {
                  final isPeak = h == peakHour;
                  return BarChartGroupData(
                    x: h,
                    barRods: [
                      BarChartRodData(
                        toY: hourlyAvg[h].toDouble(),
                        color: isPeak
                            ? AppColors.heartRed
                            : AppColors.primary.withValues(alpha: 0.25),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
