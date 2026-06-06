import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';

import 'history_data_utils.dart';

class StreamingBar extends StatelessWidget {
  final List<Map<dynamic, dynamic>> hrData;
  const StreamingBar({super.key, required this.hrData});

  _RangeSummary _compute() {
    if (hrData.isEmpty) return _RangeSummary.empty();
    int oldest = 0x7fffffffffffffff;
    int newest = 0;
    final days = <String>{};
    for (final r in hrData) {
      final s = (r['stamp'] as num?)?.toInt() ?? 0;
      if (s <= 0) continue;
      if (s < oldest) oldest = s;
      if (s > newest) newest = s;
      final dt = stampToDateTime(s);
      days.add('${dt.year}-${dt.month}-${dt.day}');
    }
    if (oldest == 0x7fffffffffffffff) return _RangeSummary.empty();
    return _RangeSummary(
      count: hrData.length,
      dayCount: days.length,
      oldest: stampToDateTime(oldest),
      newest: stampToDateTime(newest),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _compute();
    return Container(
      width: double.infinity,
      color: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: spinner + summary ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: s.isEmpty
                      ? const Text(
                          'Syncing from device…',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        )
                      : Text(
                          '${s.count} readings · ${s.dayCount} day${s.dayCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),
          // ── Date range chip ─────────────────────────────────────────────
          if (!s.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _DateRangeChip(oldest: s.oldest!, newest: s.newest!),
            ),
        ],
      ),
    );
  }
}

class _RangeSummary {
  final int count;
  final int dayCount;
  final DateTime? oldest;
  final DateTime? newest;
  const _RangeSummary(
      {required this.count,
      required this.dayCount,
      required this.oldest,
      required this.newest});
  factory _RangeSummary.empty() =>
      const _RangeSummary(count: 0, dayCount: 0, oldest: null, newest: null);
  bool get isEmpty => oldest == null;
}

class _DateRangeChip extends StatelessWidget {
  final DateTime oldest;
  final DateTime newest;
  const _DateRangeChip({required this.oldest, required this.newest});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final timeFmt = DateFormat('HH:mm');
    final sameDay = oldest.year == newest.year &&
        oldest.month == newest.month &&
        oldest.day == newest.day;

    final fromLabel = sameDay
        ? '${dateFmt.format(oldest)} ${timeFmt.format(oldest)}'
        : dateFmt.format(oldest);
    final toLabel = sameDay
        ? timeFmt.format(newest)
        : dateFmt.format(newest);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range_outlined,
              size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            '$fromLabel  →  $toLabel',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
