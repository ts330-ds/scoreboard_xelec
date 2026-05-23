import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

import 'history_data_utils.dart';
import 'stat_card.dart';
import 'stats_row.dart';

class SleepSection extends StatelessWidget {
  final List<Map<dynamic, dynamic>> sleepData;
  final DateTime? fromDate;
  final DateTime? toDate;
  const SleepSection({
    super.key,
    required this.sleepData,
    required this.fromDate,
    required this.toDate,
  });

  List<MapEntry<int, int>> _sortedStageEntries(Map<int, int> m) {
    final entries = m.entries.toList()
      ..sort((a, b) {
        int rank(int k) => k == 1
            ? 0
            : k == 2
                ? 1
                : k == 3
                    ? 2
                    : k == 4
                        ? 3
                        : 4 + k;
        return rank(a.key).compareTo(rank(b.key));
      });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    if (sleepData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.bedtime_outlined,
                color: AppColors.subtext.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No sleep history.\nTap ⟳ to sync from device.',
                style: TextStyle(
                    color: AppColors.subtext, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    final sessions = sleepData
        .map(parseSleepSession)
        .whereType<SleepSession>()
        .where((s) {
          if (fromDate != null &&
              s.start.isBefore(DateTime(
                  fromDate!.year, fromDate!.month, fromDate!.day))) {
            return false;
          }
          if (toDate != null &&
              s.start.isAfter(DateTime(
                  toDate!.year, toDate!.month, toDate!.day, 23, 59, 59))) {
            return false;
          }
          return true;
        })
        .toList()
      ..sort((a, b) => b.start.compareTo(a.start));

    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'No sleep sessions in this date range.',
          style: TextStyle(color: AppColors.subtext, fontSize: 12),
        ),
      );
    }

    final totalMin = sessions.fold<int>(0, (sum, s) => sum + s.totalMin);
    final avgMin = (totalMin / sessions.length).round();
    final stageTotals = <int, int>{};
    for (final s in sessions) {
      s.stageMinutes.forEach((k, v) {
        stageTotals[k] = (stageTotals[k] ?? 0) + v;
      });
    }
    final longest =
        sessions.fold<int>(0, (m, s) => s.totalMin > m ? s.totalMin : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatsRow(children: [
          StatCard('Sessions', '${sessions.length}', '', AppColors.primary),
          StatCard('Total', fmtDuration(totalMin), '', AppColors.vitalBP),
          StatCard('Avg', fmtDuration(avgMin), '', AppColors.heartRed),
          StatCard('Longest', fmtDuration(longest), '', AppColors.vitalStress),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stage breakdown',
                style: TextStyle(
                    color: AppColors.subtext,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              ..._sortedStageEntries(stageTotals).map((e) {
                final pct = totalMin == 0 ? 0.0 : e.value / totalMin;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: sleepStageColor(e.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: Text(
                          sleepStageLabel(e.key),
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceAlt,
                            valueColor: AlwaysStoppedAnimation(
                                sleepStageColor(e.key)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${fmtDuration(e.value)} · ${(pct * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: AppColors.subtext, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
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
                '${sessions.length} session${sessions.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    color: AppColors.subtext,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...sessions.map((s) => _SleepSessionRow(session: s)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SleepSessionRow extends StatelessWidget {
  final SleepSession session;
  const _SleepSessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM');
    final timeFmt = DateFormat('HH:mm');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bedtime_outlined,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '${dateFmt.format(session.start)} · ${timeFmt.format(session.start)} → ${timeFmt.format(session.end)}',
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                fmtDuration(session.totalMin),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: session.actions
                    .map((a) => Expanded(
                          child: Container(color: sleepStageColor(a)),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
