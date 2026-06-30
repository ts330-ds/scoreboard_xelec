import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/service/socket/history_watermark_store.dart';

import 'history_data_utils.dart';

class LastPushInfo extends StatefulWidget {
  const LastPushInfo({super.key});

  @override
  State<LastPushInfo> createState() => LastPushInfoState();
}

class LastPushInfoState extends State<LastPushInfo> {
  // Server is the source of truth — these mirror the /last_timestamp API.
  int _serverLastMs = 0;
  int _checkedAtMs = 0;
  int _lastHrStamp = 0;
  int _lastRrStamp = 0;
  int _lastSleepUtc = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final wm = await HistoryWatermarkStore.create();
    if (!mounted) return;
    setState(() {
      _serverLastMs = wm.serverLastStampMs;
      _checkedAtMs = wm.serverCheckedAtMs;
      _lastHrStamp = wm.lastHrStamp;
      _lastRrStamp = wm.lastRrStamp;
      _lastSleepUtc = wm.lastSleepUtc;
      _loaded = true;
    });
  }

  ({Color bg, Color fg, IconData icon}) _visual() {
    if (_serverLastMs == 0) {
      // Reached server but it has no data → neutral; never reached → error.
      return _checkedAtMs > 0
          ? (
              bg: AppColors.warningBg,
              fg: AppColors.warning,
              icon: Icons.cloud_queue_outlined,
            )
          : (
              bg: AppColors.errorBg,
              fg: AppColors.error,
              icon: Icons.cloud_off_outlined,
            );
    }
    final ageMin =
        (DateTime.now().millisecondsSinceEpoch - _serverLastMs) ~/ (1000 * 60);
    if (ageMin < 60) {
      return (
        bg: AppColors.successBg,
        fg: AppColors.success,
        icon: Icons.cloud_done_outlined,
      );
    }
    if (ageMin < 60 * 24) {
      return (
        bg: AppColors.warningBg,
        fg: AppColors.warning,
        icon: Icons.cloud_sync_outlined,
      );
    }
    return (
      bg: AppColors.errorBg,
      fg: AppColors.error,
      icon: Icons.cloud_off_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final v = _visual();
    final pushLabel = _serverLastMs > 0
        ? fmtLastSync(_serverLastMs)
        : (_checkedAtMs > 0 ? 'No data on server yet' : 'Never synced');

    final parts = <String>[];
    if (_lastHrStamp > 0) parts.add('HR');
    if (_lastRrStamp > 0) parts.add('RR');
    if (_lastSleepUtc > 0) parts.add('Sleep');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: v.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: v.fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: v.fg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(v.icon, color: v.fg, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST SYNCED',
                  style: TextStyle(
                    color: v.fg.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pushLabel,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (parts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Synced: ${parts.join(' · ')}',
                    style: TextStyle(
                      color: v.fg.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
