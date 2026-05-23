import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

import 'history_data_utils.dart';
import 'stat_card.dart';
import 'stats_row.dart';

class RrIntervalSection extends StatelessWidget {
  final List<Map<dynamic, dynamic>> rrData;
  const RrIntervalSection({super.key, required this.rrData});

  @override
  Widget build(BuildContext context) {
    if (rrData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.timeline,
                color: AppColors.subtext.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No RR interval history.\nTap ⟳ to sync from device.',
                style: TextStyle(
                    color: AppColors.subtext, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    final values = rrData
        .map((r) => (r['value'] as num?)?.toInt() ?? 0)
        .where((v) => v > 0)
        .toList();
    final avg = values.isEmpty
        ? 0
        : (values.reduce((a, b) => a + b) / values.length).round();
    final max = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final min = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);

    final sorted = rrData.toList()
      ..sort((a, b) {
        final sa = (a['stamp'] as num?)?.toInt() ?? 0;
        final sb = (b['stamp'] as num?)?.toInt() ?? 0;
        return sb.compareTo(sa);
      });
    final preview = sorted.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatsRow(children: [
          StatCard('Avg', '$avg', '', AppColors.primary),
          StatCard('Max', '$max', '', AppColors.heartRed),
          StatCard('Min', '$min', '', AppColors.vitalStress),
          StatCard('Samples', '${rrData.length}', '', AppColors.vitalBP),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Latest ${preview.length} of ${rrData.length} samples',
                style: const TextStyle(
                  color: AppColors.subtext,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ...preview.map((r) {
                final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
                final v = (r['value'] as num?)?.toInt() ?? 0;
                return _RrRow(stamp: stamp, value: v);
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _RrRow extends StatelessWidget {
  final int stamp;
  final int value;
  const _RrRow({required this.stamp, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.access_time_outlined,
              size: 13, color: AppColors.subtext.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(_fmtTime(stamp),
              style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
          const Spacer(),
          const Icon(Icons.timeline, color: AppColors.primary, size: 13),
          const SizedBox(width: 4),
          Text('$value',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _fmtTime(int stamp) {
    if (stamp <= 0) return '—';
    final dt = stampToDateTime(stamp);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${pad2(dt.hour)}:${pad2(dt.minute)}:${pad2(dt.second)}';
  }
}
