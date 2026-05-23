import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

import 'history_data_utils.dart';
import 'stat_card.dart';

class DayWiseReadingsSection extends StatefulWidget {
  final Map<String, List<Map<dynamic, dynamic>>> dateGroups;
  const DayWiseReadingsSection({super.key, required this.dateGroups});

  @override
  State<DayWiseReadingsSection> createState() => _DayWiseReadingsSectionState();
}

class _DayWiseReadingsSectionState extends State<DayWiseReadingsSection> {
  late String _selectedLabel;

  @override
  void initState() {
    super.initState();
    _selectedLabel = widget.dateGroups.keys.first;
  }

  @override
  void didUpdateWidget(DayWiseReadingsSection old) {
    super.didUpdateWidget(old);
    if (!widget.dateGroups.containsKey(_selectedLabel)) {
      _selectedLabel = widget.dateGroups.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = widget.dateGroups.keys.toList();
    final selectedData = widget.dateGroups[_selectedLabel] ?? [];

    final sortedData = selectedData.toList()
      ..sort((a, b) {
        final sa = (a['stamp'] as num?)?.toInt() ?? 0;
        final sb = (b['stamp'] as num?)?.toInt() ?? 0;
        return sa.compareTo(sb);
      });

    final hrs = sortedData
        .map((r) => (r['heartRate'] as num?)?.toInt() ?? 0)
        .where((v) => v > 0)
        .toList();
    final avg =
        hrs.isEmpty ? 0 : (hrs.reduce((a, b) => a + b) / hrs.length).round();
    final max = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a > b ? a : b);
    final min = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final label = dates[i];
              final isSelected = label == _selectedLabel;
              return GestureDetector(
                onTap: () => setState(() => _selectedLabel = label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.subtext,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            StatCard('Avg', '$avg', 'bpm', AppColors.primary),
            const SizedBox(width: 8),
            StatCard('Max', '$max', 'bpm', AppColors.heartRed),
            const SizedBox(width: 8),
            StatCard('Min', '$min', 'bpm', AppColors.vitalStress),
            const SizedBox(width: 8),
            StatCard('Total', '${sortedData.length}', '', AppColors.vitalBP),
          ].map((w) => Expanded(child: w)).toList(),
        ),
        const SizedBox(height: 14),
        _DayLineChart(data: sortedData),
      ],
    );
  }
}

class _DayLineChart extends StatelessWidget {
  final List<Map<dynamic, dynamic>> data;
  const _DayLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data
        .asMap()
        .entries
        .map((e) {
          final y = (e.value['heartRate'] as num?)?.toDouble() ?? 0;
          return FlSpot(e.key.toDouble(), y);
        })
        .where((s) => s.y > 0)
        .toList();

    if (spots.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('No data for this day',
              style: TextStyle(color: AppColors.subtext, fontSize: 13)),
        ),
      );
    }

    final ys = spots.map((s) => s.y).toList();
    final minY = (ys.reduce((a, b) => a < b ? a : b) - 5).clamp(0.0, 9999.0);
    final maxY = ys.reduce((a, b) => a > b ? a : b) + 10;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(4, 14, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: AppColors.heartRed,
              barWidth: 2,
              isCurved: true,
              dotData: FlDotData(show: data.length <= 30),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.heartRed.withValues(alpha: 0.07),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 4).clamp(1, 9999),
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.borderLight, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: ((maxY - minY) / 4).clamp(1, 9999),
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(
                      color: AppColors.subtext, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: data.length <= 1
                    ? 1
                    : (data.length / 4).ceilToDouble(),
                getTitlesWidget: (val, _) {
                  final idx = val.toInt().clamp(0, data.length - 1);
                  final stamp =
                      (data[idx]['stamp'] as num?)?.toInt() ?? 0;
                  if (stamp <= 0) return const SizedBox.shrink();
                  final dt = stampToDateTime(stamp);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${pad2(dt.hour)}:${pad2(dt.minute)}',
                      style: const TextStyle(
                          color: AppColors.subtext, fontSize: 8),
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
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.x.toInt().clamp(0, data.length - 1);
                final stamp = (data[idx]['stamp'] as num?)?.toInt() ?? 0;
                final dt = stampToDateTime(stamp);
                return LineTooltipItem(
                  '${pad2(dt.hour)}:${pad2(dt.minute)}\n${s.y.toStringAsFixed(0)} bpm',
                  const TextStyle(
                      color: AppColors.heartRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
