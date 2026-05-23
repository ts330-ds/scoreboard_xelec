import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/data/repository/history_repository.dart';

import 'history_data_utils.dart';

/// Persistent banner that surfaces:
///   • when the last successful sync happened
///   • the date range of stored data
///   • total record count
///
/// Color coded:
///   green  — synced within last hour
///   amber  — synced > 1 hour but ≤ 1 day ago
///   red    — never synced / > 1 day ago
class SyncStatusBanner extends StatelessWidget {
  final HistorySyncMeta meta;
  final VoidCallback? onTap;
  const SyncStatusBanner({super.key, required this.meta, this.onTap});

  ({Color bg, Color fg, IconData icon, String label}) _statusVisual() {
    final last = meta.latestSyncMs;
    if (last == 0) {
      return (
        bg: AppColors.errorBg,
        fg: AppColors.error,
        icon: Icons.cloud_off_outlined,
        label: 'Never synced',
      );
    }
    final ageMin =
        (DateTime.now().millisecondsSinceEpoch - last) ~/ (1000 * 60);
    if (ageMin < 60) {
      return (
        bg: AppColors.successBg,
        fg: AppColors.success,
        icon: Icons.cloud_done_outlined,
        label: fmtLastSync(last),
      );
    }
    if (ageMin < 60 * 24) {
      return (
        bg: AppColors.warningBg,
        fg: AppColors.warning,
        icon: Icons.cloud_sync_outlined,
        label: fmtLastSync(last),
      );
    }
    return (
      bg: AppColors.errorBg,
      fg: AppColors.error,
      icon: Icons.cloud_off_outlined,
      label: fmtLastSync(last),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _statusVisual();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: v.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: v.fg.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: v.fg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(v.icon, color: v.fg, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAST SYNC',
                      style: TextStyle(
                        color: v.fg.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      v.label,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.refresh, color: v.fg, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
