import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/cubit/shell_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/presentation/cubit/history_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/presentation/cubit/history_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

import '../widgets/daily_trend_chart.dart';
import '../widgets/day_wise_readings_section.dart';
import '../widgets/empty_state.dart';
import '../widgets/history_data_utils.dart';
import '../widgets/peak_hours_section.dart';
import '../widgets/push_now_button.dart';
import '../widgets/range_preset_chips.dart';
import '../widgets/rr_interval_section.dart';
import '../widgets/section_label.dart';
import '../widgets/sleep_section.dart';
import '../widgets/stat_card.dart';
import '../widgets/stats_row.dart';
import '../widgets/streaming_bar.dart';
import '../widgets/sync_button.dart';
import '../widgets/sync_status_banner.dart';
import '../widgets/time_of_day_section.dart';

class AthleteHistoryScreen extends StatelessWidget {
  const AthleteHistoryScreen({super.key});

  static const int _tabIndex = 3;

  void _trySyncIfNeeded(BuildContext context) {
    if (!Platform.isAndroid) return;
    final ble = context.read<HeartBleCubit>();
    final alreadySyncing = ble.state.status.contains('yncing');
    if (ble.state.isConnected &&
        ble.state.historyHrData.isEmpty &&
        !alreadySyncing) {
      ble.syncAllHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit(),
      child: MultiBlocListener(
        listeners: [
          BlocListener<AthleteShellCubit, int>(
            listenWhen: (prev, curr) => curr == _tabIndex && prev != curr,
            listener: (ctx, _) => _trySyncIfNeeded(ctx),
          ),
          BlocListener<HeartBleCubit, HeartBleState>(
            listenWhen: (prev, curr) =>
                !prev.isConnected &&
                curr.isConnected &&
                context.read<AthleteShellCubit>().state == _tabIndex,
            listener: (ctx, _) => _trySyncIfNeeded(ctx),
          ),
        ],
        child: BlocBuilder<HeartBleCubit, HeartBleState>(
          buildWhen: (p, c) =>
              p.historyHrData != c.historyHrData ||
              p.historyRrData != c.historyRrData ||
              p.historySleep != c.historySleep ||
              p.isConnected != c.isConnected ||
              p.status != c.status,
          builder: (context, bleState) => _HistoryShell(bleState: bleState),
        ),
      ),
    );
  }
}

class _HistoryShell extends StatelessWidget {
  final HeartBleState bleState;
  const _HistoryShell({required this.bleState});

  @override
  Widget build(BuildContext context) {
    final syncing = bleState.status.contains('yncing');
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Heart Rate History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SyncButton(
              isSyncing: syncing,
              onTap: Platform.isAndroid
                  ? () => context
                      .read<HeartBleCubit>()
                      .syncAllHistory(force: true)
                  : null,
            ),
          ),
        ],
      ),
      body: !Platform.isAndroid
          ? const _IosPlaceholder()
          : Column(
              children: [
                if (syncing) StreamingBar(count: bleState.historyHrData.length),
                Expanded(child: _HistoryBody(bleState: bleState)),
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

class _HistoryBody extends StatelessWidget {
  final HeartBleState bleState;
  const _HistoryBody({required this.bleState});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, hState) {
        final ble = context.read<HeartBleCubit>();
        final meta = ble.historyMeta;

        // ── Data pipeline ───────────────────────────────────────────────
        final deduped = dedupeHrData(bleState.historyHrData).toList()
          ..sort((a, b) {
            final sa = (a['stamp'] as num?)?.toInt() ?? 0;
            final sb = (b['stamp'] as num?)?.toInt() ?? 0;
            return sb.compareTo(sa);
          });

        final win = hState.effectiveWindow();
        final filtered = filterByDateRange(deduped, win.from, win.to);

        final hrs = filtered
            .map((r) => (r['heartRate'] as num?)?.toInt() ?? 0)
            .where((v) => v > 0)
            .toList();
        final avg = hrs.isEmpty
            ? 0
            : (hrs.reduce((a, b) => a + b) / hrs.length).round();
        final max = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a > b ? a : b);
        final min = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a < b ? a : b);

        final timeSlots = timeOfDayAggregates(filtered);
        final dailyStats = dailyAggregates(filtered);
        final peak = peakHourDetection(filtered);
        final dateGroups = groupByDate(filtered);

        final hasAnyData = bleState.historyHrData.isNotEmpty ||
            bleState.historyRrData.isNotEmpty ||
            bleState.historySleep.isNotEmpty;

        if (!hasAnyData) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SyncStatusBanner(
                  meta: meta,
                  onTap: bleState.isConnected
                      ? () => ble.syncAllHistory(force: true)
                      : null,
                ),
              ),
              const HistoryEmptyState(
                icon: Icons.favorite,
                color: AppColors.heartRed,
                message:
                    'No heart rate history yet.\nTap ⟳ above or the sync button to fetch from device.',
              ),
            ],
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Sync status banner ──────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: SyncStatusBanner(
                  meta: meta,
                  onTap: bleState.isConnected
                      ? () => ble.syncAllHistory(force: true)
                      : null,
                ),
              ),
            ),
            // ── Range preset chips ──────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(
                child: RangePresetChips(
                  selected: hState.preset,
                  customFrom: hState.customFrom,
                  customTo: hState.customTo,
                  onSelect: (p) =>
                      context.read<HistoryCubit>().selectPreset(p),
                  onCustomTap: () => _pickCustomRange(context, hState),
                  canFetch: bleState.isConnected,
                  onFetchFromDevice: () => _fetchRangeFromDevice(context),
                ),
              ),
            ),
            // ── Push Now button (debug) ────────────────────────────────
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(child: PushNowButton()),
            ),
            // ── Summary stats ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: StatsRow(children: [
                  StatCard('Avg', '$avg', 'bpm', AppColors.primary),
                  StatCard('Max', '$max', 'bpm', AppColors.heartRed),
                  StatCard('Min', '$min', 'bpm', AppColors.vitalStress),
                  StatCard('Readings', '${filtered.length}', '',
                      AppColors.vitalBP),
                ]),
              ),
            ),
            // ── Time of Day ────────────────────────────────────────────
            if (filtered.isNotEmpty)
              _section(
                'TIME OF DAY ANALYSIS',
                TimeOfDaySection(slots: timeSlots),
              ),
            // ── Daily trends ───────────────────────────────────────────
            if (dailyStats.length >= 2)
              _section(
                'DAILY TRENDS',
                DailyTrendChart(stats: dailyStats),
              ),
            // ── Peak hours ─────────────────────────────────────────────
            if (peak.peakAvg > 0)
              _section(
                'PEAK HEART RATE HOURS',
                PeakHoursSection(
                  peakHour: peak.peakHour,
                  peakAvg: peak.peakAvg,
                  hourlyAvg: peak.hourlyAvg,
                ),
              ),
            // ── Day-wise readings ──────────────────────────────────────
            if (dateGroups.isNotEmpty)
              _section(
                'ALL READINGS',
                DayWiseReadingsSection(dateGroups: dateGroups),
              ),
            // ── RR Interval ────────────────────────────────────────────
            _section(
              'RR INTERVAL HISTORY',
              RrIntervalSection(rrData: bleState.historyRrData),
            ),
            // ── Sleep ──────────────────────────────────────────────────
            _section(
              'SLEEP HISTORY',
              SleepSection(
                sleepData: bleState.historySleep,
                fromDate: win.from,
                toDate: win.to,
              ),
              bottomPadding: 32,
            ),
          ],
        );
      },
    );
  }

  SliverPadding _section(String label, Widget child, {double bottomPadding = 0}) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPadding),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(label),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomRange(
      BuildContext context, HistoryState hState) async {
    final cubit = context.read<HistoryCubit>();
    final initialRange = hState.customFrom != null && hState.customTo != null
        ? DateTimeRange(start: hState.customFrom!, end: hState.customTo!)
        : null;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      cubit
        ..setCustomFrom(picked.start)
        ..setCustomTo(picked.end);
    }
  }

  Future<void> _fetchRangeFromDevice(BuildContext context) async {
    final hState = context.read<HistoryCubit>().state;
    final ble = context.read<HeartBleCubit>();
    final win = hState.effectiveWindow();

    if (win.from == null && win.to == null) {
      // "All" preset → full sync
      await ble.syncAllHistory(force: true);
    } else {
      final from = win.from ?? DateTime(2020);
      final to = win.to ?? DateTime.now();
      await ble.syncHistoryRange(from: from, to: to);
    }
  }
}
