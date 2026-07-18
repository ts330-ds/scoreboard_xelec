import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/home_heart_rate/presentation/screen/history_records_screen.dart';

import '../../../history/presentation/widgets/empty_state.dart';
import '../../../history/presentation/widgets/last_push_info.dart';
import '../../../history/presentation/widgets/polling_status_banner.dart';
import '../../../history/presentation/widgets/push_now_button.dart';
import '../../../history/presentation/widgets/sleep_from_hr.dart'
    show SleepResult;
import '../../../history/presentation/widgets/sleep_hr_chart.dart';
import '../../../history/presentation/widgets/sync_button.dart';
import '../../data/repository/history_sql_repository_impl.dart';
import '../../domain/entity/daily_hr_summary.dart';
import '../cubit/history_sql_cubit.dart';
import '../cubit/history_sql_state.dart';
import '../widgets/hr_scrollable_chart.dart';

/// SQLite-backed History tab. Drop-in replacement for [AthleteHistoryScreen].
/// Reads tabs/stats from a GROUP BY and per-day data from indexed range scans,
/// instead of loading the whole Hive box and grouping in Dart.
class AthleteHistorySqlScreen extends StatelessWidget {
  const AthleteHistorySqlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistorySqlCubit(HistorySqlRepositoryImpl.instance),
      child: const _HistorySqlShell(),
    );
  }
}

class _HistorySqlShell extends StatefulWidget {
  const _HistorySqlShell();

  @override
  State<_HistorySqlShell> createState() => _HistorySqlShellState();
}

class _HistorySqlShellState extends State<_HistorySqlShell> {
  final _lastPushKey = GlobalKey<LastPushInfoState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Seed SQLite from whatever the BLE cubit already has in memory.
      _ingestFrom(context.read<HeartBleCubit>().state);
      // History tab open: refresh "last synced" from the server (source of
      // truth) and update the LastPushInfo card.
      _refreshLastSynced();
    });
  }

  Future<void> _refreshLastSynced() async {
    final cubit = context.read<HeartBleCubit>();
    await cubit.refreshServerWatermark();
    if (!mounted) return;
    _lastPushKey.currentState?.reload();
  }

  void _ingestFrom(HeartBleState s) {
    if (!mounted) return;
    context.read<HistorySqlCubit>().refresh(
          s.historyHrData,
          s.historyRrData,
          s.historySleep,
        );
  }

  bool _isSyncing(HeartBleState s) {
    final t = s.status.toLowerCase();
    return t.contains('syncing');
  }

  void _onSyncTap(HeartBleState s) {
    if (!Platform.isAndroid) return;
    if (_isSyncing(s)) return;
    if (!s.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device is not connected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<HeartBleCubit>().syncNewFromDevice();
  }

  bool _guardConnected(HeartBleState s) {
    if (!s.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device is not connected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _onShutdownTap(HeartBleState s) async {
    if (!_guardConnected(s)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Shutdown device?'),
        content: const Text(
          'The band will power off and disconnect. You will need to '
          'turn it back on manually to reconnect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Shutdown'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<HeartBleCubit>().shutdownDevice();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shutdown command sent'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onRestoreTap(HeartBleState s) async {
    if (!_guardConnected(s)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Factory reset device?'),
        content: const Text(
          'This will ERASE all settings and stored history on the band. '
          'This cannot be undone.\n\nMake sure any data you need has already '
          'been synced and pushed to the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.heartRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Factory reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<HeartBleCubit>().restoreDevice();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Factory reset command sent'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HeartBleCubit, HeartBleState>(
      listenWhen: (p, c) =>
          p.historyHrData != c.historyHrData ||
          p.historyRrData != c.historyRrData ||
          p.historySleep != c.historySleep,
      listener: (_, s) => _ingestFrom(s),
      child: BlocBuilder<HeartBleCubit, HeartBleState>(
        buildWhen: (p, c) =>
            p.status != c.status ||
            p.isConnected != c.isConnected ||
            p.historyHrData.length != c.historyHrData.length,
        builder: (context, bleState) {
          final syncing = _isSyncing(bleState);
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              title: const Text('Device History'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                if (Platform.isAndroid)
                  IconButton(
                    tooltip: 'View session records',
                    icon: const Icon(Icons.folder_copy_outlined,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context)
                        .push(HistoryRecordsScreen.route(context)),
                  ),
                if (Platform.isAndroid)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SyncButton(
                      isSyncing: syncing,
                      onTap: syncing ? null : () => _onSyncTap(bleState),
                    ),
                  ),
                if (Platform.isAndroid)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    tooltip: 'Device actions',
                    onSelected: (value) {
                      if (value == 'shutdown') {
                        _onShutdownTap(bleState);
                      } else if (value == 'restore') {
                        _onRestoreTap(bleState);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'shutdown',
                        child: Row(
                          children: [
                            Icon(Icons.power_settings_new,
                                size: 18, color: AppColors.text),
                            SizedBox(width: 10),
                            Text('Shutdown device'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.restart_alt,
                                size: 18, color: AppColors.heartRed),
                            SizedBox(width: 10),
                            Text('Factory reset',
                                style: TextStyle(color: AppColors.heartRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            body: !Platform.isAndroid
                ? const _IosPlaceholder()
                : Column(
                    children: [
                      if (syncing)
                        Container(
                          width: double.infinity,
                          color: AppColors.primaryLight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                    color: AppColors.primary, strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Syncing… ${bleState.historyHrData.length} readings',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: LastPushInfo(key: _lastPushKey),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: PushNowButton(
                          // After a push the server advances → re-pull truth.
                          onPushComplete: _refreshLastSynced,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: PollingStatusBanner(),
                      ),
                      Expanded(child: _SqlContent(syncing: syncing)),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// ─── SQL-driven content ───────────────────────────────────────────────────────

class _SqlContent extends StatelessWidget {
  final bool syncing;
  const _SqlContent({required this.syncing});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistorySqlCubit, HistorySqlState>(
      builder: (context, state) {
        if (state.summaries.isEmpty) {
          if (state.loading || syncing) {
            return HistoryEmptyState(
              icon: Icons.show_chart_rounded,
              color: AppColors.primary,
              message: syncing
                  ? 'Receiving data from device…'
                  : 'Loading…',
            );
          }
          return const HistoryEmptyState(
            icon: Icons.show_chart_rounded,
            color: AppColors.primary,
            message:
                'No heart rate history yet.\nTap sync to fetch from device.',
          );
        }

        return Column(
          children: [
            const SizedBox(height: 12),
            _DateTabs(
              summaries: state.summaries,
              selectedIdx: state.selectedIdx,
              onTap: (i) => context.read<HistorySqlCubit>().selectDay(i),
            ),
            Expanded(
              child: _DayDetail(
                summary: state.selected,
                readings: state.dayReadings,
                sleep: state.sleep,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Date tabs ─────────────────────────────────────────────────────────────────

class _DateTabs extends StatelessWidget {
  final List<DailyHrSummary> summaries;
  final int selectedIdx;
  final ValueChanged<int> onTap;
  const _DateTabs({
    required this.summaries,
    required this.selectedIdx,
    required this.onTap,
  });

  String _label(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: summaries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == selectedIdx;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                _label(summaries[i].date),
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.subtext,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Day detail ────────────────────────────────────────────────────────────────

class _DayDetail extends StatelessWidget {
  final DailyHrSummary? summary;
  final List<Map<dynamic, dynamic>> readings;
  final SleepResult? sleep;
  const _DayDetail({
    required this.summary,
    required this.readings,
    required this.sleep,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final sleepResult = sleep;
    if (s == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No data available for this day',
              style: TextStyle(color: AppColors.subtext, fontSize: 13)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatTile(
                label: 'AVG',
                value: '${s.avg}',
                color: AppColors.primary,
                icon: Icons.favorite,
              ),
              const SizedBox(width: 10),
              _StatTile(
                label: 'MAX',
                value: '${s.max}',
                color: AppColors.heartRed,
                icon: Icons.arrow_upward_rounded,
              ),
              const SizedBox(width: 10),
              _StatTile(
                label: 'MIN',
                value: '${s.min}',
                color: AppColors.vitalStress,
                icon: Icons.arrow_downward_rounded,
              ),
            ].map((w) => Expanded(child: w)).toList(),
          ),
          const SizedBox(height: 16),
          HrScrollableChart(readings: readings, emphasizeYGrid: true),
          if (sleepResult != null) ...[
            const SizedBox(height: 16),
            SleepHrChart(sleep: sleepResult),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'bpm',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.6),
                      fontSize: 10,
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

class _IosPlaceholder extends StatelessWidget {
  const _IosPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const HistoryEmptyState(
      icon: Icons.phone_iphone,
      color: AppColors.subtext,
      message:
          'History sync is currently available on Android only.\nComing soon to iOS.',
    );
  }
}
