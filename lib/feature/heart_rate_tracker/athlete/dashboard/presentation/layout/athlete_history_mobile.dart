import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/cubit/shell_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _DailyStats {
  final DateTime date;
  final int avg;
  final int max;
  final int min;
  final int count;
  const _DailyStats({
    required this.date,
    required this.avg,
    required this.max,
    required this.min,
    required this.count,
  });
}

class _TimeSlotStats {
  final String label;
  final String timeRange;
  final IconData icon;
  final Color color;
  final int avgHr;
  final int count;
  const _TimeSlotStats({
    required this.label,
    required this.timeRange,
    required this.icon,
    required this.color,
    required this.avgHr,
    required this.count,
  });
}


// ═══════════════════════════════════════════════════════════════════════════════
// DATA PROCESSING HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

DateTime _stampToDateTime(int stamp) {
  final ms = stamp > 9999999999 ? stamp : stamp * 1000;
  return DateTime.fromMillisecondsSinceEpoch(ms);
}

List<Map<dynamic, dynamic>> _dedupeHrData(List<Map<dynamic, dynamic>> data) {
  if (data.isEmpty) return data;
  final seenStamps = <int>{};
  final uniqueByStamp = data.where((r) {
    final s = (r['stamp'] as num?)?.toInt() ?? 0;
    if (s <= 0) return true;
    return seenStamps.add(s);
  }).toList();

  final result = <Map<dynamic, dynamic>>[uniqueByStamp.first];
  for (int i = 1; i < uniqueByStamp.length; i++) {
    final prev = (result.last['heartRate'] as num?)?.toInt() ?? -1;
    final curr = (uniqueByStamp[i]['heartRate'] as num?)?.toInt() ?? -1;
    if (curr != prev) result.add(uniqueByStamp[i]);
  }
  return result;
}

List<Map<dynamic, dynamic>> _filterByDateRange(
  List<Map<dynamic, dynamic>> data,
  DateTime? from,
  DateTime? to,
) {
  if (from == null && to == null) return data;
  return data.where((r) {
    final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
    if (stamp <= 0) return false;
    final dt = _stampToDateTime(stamp);
    if (from != null && dt.isBefore(DateTime(from.year, from.month, from.day))) {
      return false;
    }
    if (to != null &&
        dt.isAfter(
            DateTime(to.year, to.month, to.day, 23, 59, 59))) {
      return false;
    }
    return true;
  }).toList();
}

/// Groups readings by date label: "Today", "Yesterday", or "03 Apr 2024"
Map<String, List<Map<dynamic, dynamic>>> _groupByDate(
    List<Map<dynamic, dynamic>> data) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final fmt = DateFormat('dd MMM yyyy');

  final grouped = <String, List<Map<dynamic, dynamic>>>{};
  for (final r in data) {
    final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
    if (stamp <= 0) continue;
    final dt = _stampToDateTime(stamp);
    final dtDay = DateTime(dt.year, dt.month, dt.day);

    String label;
    if (dtDay == today) {
      label = 'Today';
    } else if (dtDay == yesterday) {
      label = 'Yesterday';
    } else {
      label = fmt.format(dt);
    }
    grouped.putIfAbsent(label, () => []).add(r);
  }
  return grouped;
}

List<_DailyStats> _dailyAggregates(List<Map<dynamic, dynamic>> data) {
  final byDay = <String, List<int>>{};
  final dayDates = <String, DateTime>{};

  for (final r in data) {
    final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
    final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
    if (stamp <= 0 || hr <= 0) continue;
    final dt = _stampToDateTime(stamp);
    final key = '${dt.year}-${dt.month}-${dt.day}';
    byDay.putIfAbsent(key, () => []).add(hr);
    dayDates.putIfAbsent(key, () => DateTime(dt.year, dt.month, dt.day));
  }

  final result = byDay.entries.map((e) {
    final hrs = e.value;
    final avg = (hrs.reduce((a, b) => a + b) / hrs.length).round();
    final max = hrs.reduce((a, b) => a > b ? a : b);
    final min = hrs.reduce((a, b) => a < b ? a : b);
    return _DailyStats(
        date: dayDates[e.key]!, avg: avg, max: max, min: min, count: hrs.length);
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return result;
}

List<_TimeSlotStats> _timeOfDayAggregates(List<Map<dynamic, dynamic>> data) {
  // Buckets: Morning 5-11, Afternoon 12-16, Evening 17-20, Night 21-4
  final buckets = <String, List<int>>{
    'Morning': [],
    'Afternoon': [],
    'Evening': [],
    'Night': [],
  };

  for (final r in data) {
    final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
    final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
    if (stamp <= 0 || hr <= 0) continue;
    final hour = _stampToDateTime(stamp).hour;
    if (hour >= 5 && hour <= 11) {
      buckets['Morning']!.add(hr);
    } else if (hour >= 12 && hour <= 16) {
      buckets['Afternoon']!.add(hr);
    } else if (hour >= 17 && hour <= 20) {
      buckets['Evening']!.add(hr);
    } else {
      buckets['Night']!.add(hr);
    }
  }

  int avg(List<int> list) =>
      list.isEmpty ? 0 : (list.reduce((a, b) => a + b) / list.length).round();

  return [
    _TimeSlotStats(
        label: 'Morning',
        timeRange: '5 AM – 12 PM',
        icon: Icons.wb_sunny_outlined,
        color: AppColors.warning,
        avgHr: avg(buckets['Morning']!),
        count: buckets['Morning']!.length),
    _TimeSlotStats(
        label: 'Afternoon',
        timeRange: '12 PM – 5 PM',
        icon: Icons.light_mode_outlined,
        color: AppColors.heartRed,
        avgHr: avg(buckets['Afternoon']!),
        count: buckets['Afternoon']!.length),
    _TimeSlotStats(
        label: 'Evening',
        timeRange: '5 PM – 9 PM',
        icon: Icons.nights_stay_outlined,
        color: AppColors.vitalBP,
        avgHr: avg(buckets['Evening']!),
        count: buckets['Evening']!.length),
    _TimeSlotStats(
        label: 'Night',
        timeRange: '9 PM – 5 AM',
        icon: Icons.dark_mode_outlined,
        color: AppColors.vitalStress,
        avgHr: avg(buckets['Night']!),
        count: buckets['Night']!.length),
  ];
}


/// Returns {hour: int, avgHr: int} for the hour-of-day with highest avg HR
/// plus a list of 24 avg-HR values for the mini bar chart.
({int peakHour, int peakAvg, List<int> hourlyAvg}) _peakHourDetection(
    List<Map<dynamic, dynamic>> data) {
  final buckets = List.generate(24, (_) => <int>[]);

  for (final r in data) {
    final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
    final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
    if (stamp <= 0 || hr <= 0) continue;
    buckets[_stampToDateTime(stamp).hour].add(hr);
  }

  final hourlyAvg = buckets
      .map((list) =>
          list.isEmpty ? 0 : (list.reduce((a, b) => a + b) / list.length).round())
      .toList();

  int peakHour = 0;
  int peakAvg = 0;
  for (int h = 0; h < 24; h++) {
    if (hourlyAvg[h] > peakAvg) {
      peakAvg = hourlyAvg[h];
      peakHour = h;
    }
  }

  return (peakHour: peakHour, peakAvg: peakAvg, hourlyAvg: hourlyAvg);
}


String _formatHour(int hour) {
  if (hour == 0) return '12 AM';
  if (hour < 12) return '$hour AM';
  if (hour == 12) return '12 PM';
  return '${hour - 12} PM';
}

String _p(int n) => n.toString().padLeft(2, '0');


// ═══════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class AthleteHistoryMobile extends StatelessWidget {
  const AthleteHistoryMobile({super.key});

  static const int _tabIndex = 3;

  void _trySyncIfNeeded(BuildContext context) {
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
    return MultiBlocListener(
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
            p.isConnected != c.isConnected ||
            p.status != c.status,
        builder: (context, state) => _HistoryShell(state: state),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHELL (AppBar + Sync + Body)
// ═══════════════════════════════════════════════════════════════════════════════

class _HistoryShell extends StatelessWidget {
  final HeartBleState state;
  const _HistoryShell({required this.state});

  @override
  Widget build(BuildContext context) {
    final syncing = state.status.contains('yncing');
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
            child: _SyncButton(isSyncing: syncing),
          ),
        ],
      ),
      body: Column(
        children: [
          if (syncing) _StreamingBar(count: state.historyHrData.length),
          Expanded(child: _HeartRateTab(state: state)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SYNC BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _SyncButton extends StatefulWidget {
  final bool isSyncing;
  const _SyncButton({required this.isSyncing});

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.isSyncing) _spin.repeat();
  }

  @override
  void didUpdateWidget(_SyncButton old) {
    super.didUpdateWidget(old);
    if (widget.isSyncing && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.isSyncing && _spin.isAnimating) {
      _spin.stop();
      _spin.reset();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected =
        context.select<HeartBleCubit, bool>((c) => c.state.isConnected);
    return GestureDetector(
      onTap: connected
          ? () => context.read<HeartBleCubit>().syncAllHistory()
          : null,
      child: Tooltip(
        message:
            connected ? 'Sync history from device' : 'Connect a device first',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: connected ? 0.20 : 0.10),
            border: Border.all(
                color:
                    Colors.white.withValues(alpha: connected ? 0.50 : 0.20)),
          ),
          child: RotationTransition(
            turns: _spin,
            child: Icon(Icons.sync,
                color: connected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.40),
                size: 18),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STREAMING BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _StreamingBar extends StatelessWidget {
  final int count;
  const _StreamingBar({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primaryLight,
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            'Streaming\u2026 $count readings received',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HEART RATE TAB (StatefulWidget for date filter)
// ═══════════════════════════════════════════════════════════════════════════════

class _HeartRateTab extends StatefulWidget {
  final HeartBleState state;
  const _HeartRateTab({required this.state});

  @override
  State<_HeartRateTab> createState() => _HeartRateTabState();
}

class _HeartRateTabState extends State<_HeartRateTab> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    // ── Prepare data pipeline ─────────────────────────────────────────────
    final deduped = _dedupeHrData(widget.state.historyHrData).toList()
      ..sort((a, b) {
        final sa = (a['stamp'] as num?)?.toInt() ?? 0;
        final sb = (b['stamp'] as num?)?.toInt() ?? 0;
        return sb.compareTo(sa); // newest first
      });

    if (deduped.isEmpty) {
      return const _EmptyState(
        icon: Icons.favorite,
        color: AppColors.heartRed,
        message: 'No heart rate history.\nTap \u27f3 to sync from device.',
      );
    }

    final filtered = _filterByDateRange(deduped, _fromDate, _toDate);

    // ── Compute aggregates ────────────────────────────────────────────────
    final hrs = filtered
        .map((r) => (r['heartRate'] as num?)?.toInt() ?? 0)
        .where((v) => v > 0)
        .toList();
    final avg =
        hrs.isEmpty ? 0 : (hrs.reduce((a, b) => a + b) / hrs.length).round();
    final max = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a > b ? a : b);
    final min = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a < b ? a : b);

    final timeSlots = _timeOfDayAggregates(filtered);
    final dailyStats = _dailyAggregates(filtered);
    final peak = _peakHourDetection(filtered);
    final dateGroups = _groupByDate(filtered);


    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── 1. Summary Stats ──────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatsRow(children: [
                  _StatCard('Avg', '$avg', 'bpm', AppColors.primary),
                  _StatCard('Max', '$max', 'bpm', AppColors.heartRed),
                  _StatCard('Min', '$min', 'bpm', AppColors.vitalStress),
                  _StatCard('Readings', '${filtered.length}', '',
                      AppColors.vitalBP),
                ]),
              ],
            ),
          ),
        ),

        // ── 2. Date Range Filter ──────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('DATE RANGE FILTER'),
                const SizedBox(height: 10),
                _DateRangeFilter(
                  fromDate: _fromDate,
                  toDate: _toDate,
                  onFromChanged: (d) => setState(() => _fromDate = d),
                  onToChanged: (d) => setState(() => _toDate = d),
                  onClear: () => setState(() {
                    _fromDate = null;
                    _toDate = null;
                  }),
                ),
              ],
            ),
          ),
        ),

        // ── 3. Time of Day Analysis ───────────────────────────────────────
        if (filtered.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('TIME OF DAY ANALYSIS'),
                  const SizedBox(height: 10),
                  _TimeOfDaySection(slots: timeSlots),
                ],
              ),
            ),
          ),

        // ── 4. Daily Trends Chart ─────────────────────────────────────────
        if (dailyStats.length >= 2)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('DAILY TRENDS'),
                  const SizedBox(height: 10),
                  _DailyTrendChart(stats: dailyStats),
                ],
              ),
            ),
          ),

        // ── 5. Peak Hours ─────────────────────────────────────────────────
        if (peak.peakAvg > 0)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('PEAK HEART RATE HOURS'),
                  const SizedBox(height: 10),
                  _PeakHoursSection(
                    peakHour: peak.peakHour,
                    peakAvg: peak.peakAvg,
                    hourlyAvg: peak.hourlyAvg,
                  ),
                ],
              ),
            ),
          ),

        // ── 7. HR Over Time Chart ─────────────────────────────────────────
       /* if (filtered.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('HR OVER TIME'),
                  const SizedBox(height: 10),
                  _HrLineChart(data: filtered),
                ],
              ),
            ),
          ),*/

        // ── 8. Day-wise Readings Chart + List ────────────────────────────
        if (dateGroups.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('ALL READINGS'),
                  const SizedBox(height: 10),
                  _DayWiseSection(dateGroups: dateGroups),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: DATE RANGE FILTER
// ═══════════════════════════════════════════════════════════════════════════════

class _DateRangeFilter extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateTime?> onFromChanged;
  final ValueChanged<DateTime?> onToChanged;
  final VoidCallback onClear;

  const _DateRangeFilter({
    required this.fromDate,
    required this.toDate,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onClear,
  });

  Future<void> _pick(BuildContext context, DateTime? initial,
      ValueChanged<DateTime?> onChange) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
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
    if (picked != null) onChange(picked);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final hasFilter = fromDate != null || toDate != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pick(context, fromDate, onFromChanged),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        fromDate != null ? fmt.format(fromDate!) : 'From',
                        style: TextStyle(
                          color: fromDate != null
                              ? AppColors.text
                              : AppColors.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 12, color: AppColors.subtext),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _pick(context, toDate, onToChanged),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        toDate != null ? fmt.format(toDate!) : 'To',
                        style: TextStyle(
                          color: toDate != null
                              ? AppColors.text
                              : AppColors.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasFilter)
            GestureDetector(
              onTap: onClear,
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close, size: 14, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: TIME OF DAY ANALYSIS
// ═══════════════════════════════════════════════════════════════════════════════

class _TimeOfDaySection extends StatelessWidget {
  final List<_TimeSlotStats> slots;
  const _TimeOfDaySection({required this.slots});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: slots.map((s) => _TimeSlotCard(slot: s)).toList(),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final _TimeSlotStats slot;
  const _TimeSlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: slot.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(slot.icon, color: slot.color, size: 18),
              const SizedBox(width: 6),
              Text(slot.label,
                  style: TextStyle(
                      color: slot.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                slot.avgHr > 0 ? '${slot.avgHr}' : '--',
                style: TextStyle(
                    color: slot.avgHr > 0 ? AppColors.text : AppColors.textHint,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('bpm',
                    style: TextStyle(
                        color: slot.color.withValues(alpha: 0.7), fontSize: 10)),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(slot.timeRange,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 9)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: DAILY TREND CHART
// ═══════════════════════════════════════════════════════════════════════════════

class _DailyTrendChart extends StatefulWidget {
  final List<_DailyStats> stats;
  const _DailyTrendChart({required this.stats});

  @override
  State<_DailyTrendChart> createState() => _DailyTrendChartState();
}

class _DailyTrendChartState extends State<_DailyTrendChart> {
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
          // Toggle
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
              // Legend
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
                  _lineData(stats.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.avg.toDouble()))
                      .toList(), AppColors.primary, 2.5),
                  _lineData(stats.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.max.toDouble()))
                      .toList(), AppColors.heartRed, 1.5),
                  _lineData(stats.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.min.toDouble()))
                      .toList(), AppColors.vitalStress, 1.5),
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

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: PEAK HOURS
// ═══════════════════════════════════════════════════════════════════════════════

class _PeakHoursSection extends StatelessWidget {
  final int peakHour;
  final int peakAvg;
  final List<int> hourlyAvg;
  const _PeakHoursSection({
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
          // Peak info card
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
                        '${_formatHour(peakHour)} – ${_formatHour((peakHour + 1) % 24)}',
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
          // 24-hour mini bar chart
          SizedBox(
            height: 80,
            child: BarChart(
              BarChartData(
                maxY: (hourlyAvg.reduce(math.max) + 10).toDouble(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    getTooltipItem: (group, gIdx, rod, rIdx) => BarTooltipItem(
                      '${_formatHour(group.x)}\n${rod.toY.toInt()} bpm',
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

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: HR OVER TIME LINE CHART
// ═══════════════════════════════════════════════════════════════════════════════

class _HrLineChart extends StatelessWidget {
  final List<Map<dynamic, dynamic>> data;
  const _HrLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final pts = data.length > 100 ? data.sublist(data.length - 100) : data;
    final spots = pts
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
        height: 180,
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: const Center(
            child: Text('No chart data',
                style: TextStyle(color: AppColors.subtext))),
      );
    }

    final ys = spots.map((s) => s.y).toList();
    final minY = (ys.reduce((a, b) => a < b ? a : b) - 5).clamp(0.0, 9999.0);
    final maxY = ys.reduce((a, b) => a > b ? a : b) + 10;

    return Container(
      height: 190,
      padding: const EdgeInsets.fromLTRB(4, 12, 12, 8),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
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
              dotData: FlDotData(show: pts.length <= 25),
              belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.heartRed.withValues(alpha: 0.08)),
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
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: pts.length <= 1
                    ? 1
                    : (pts.length / 4).ceilToDouble(),
                getTitlesWidget: (val, _) {
                  final idx = val.toInt().clamp(0, pts.length - 1);
                  final stamp =
                      (pts[idx]['stamp'] as num?)?.toInt() ?? 0;
                  if (stamp <= 0) return const SizedBox.shrink();
                  final dt = _stampToDateTime(stamp);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_p(dt.hour)}:${_p(dt.minute)}',
                      style: const TextStyle(
                          color: AppColors.subtext, fontSize: 8),
                    ),
                  );
                },
              ),
            ),
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
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.toStringAsFixed(0)} bpm',
                        const TextStyle(
                            color: AppColors.heartRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION: DAY-WISE READINGS CHART
// ═══════════════════════════════════════════════════════════════════════════════

class _DayWiseSection extends StatefulWidget {
  final Map<String, List<Map<dynamic, dynamic>>> dateGroups;
  const _DayWiseSection({required this.dateGroups});

  @override
  State<_DayWiseSection> createState() => _DayWiseSectionState();
}

class _DayWiseSectionState extends State<_DayWiseSection> {
  late String _selectedLabel;

  @override
  void initState() {
    super.initState();
    _selectedLabel = widget.dateGroups.keys.first;
  }

  @override
  void didUpdateWidget(_DayWiseSection old) {
    super.didUpdateWidget(old);
    // agar selected label ab exist nahi karta (filter change) to reset
    if (!widget.dateGroups.containsKey(_selectedLabel)) {
      _selectedLabel = widget.dateGroups.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = widget.dateGroups.keys.toList();
    final selectedData = widget.dateGroups[_selectedLabel] ?? [];

    // selected day ke readings sort by stamp ascending (for chart)
    final sortedData = selectedData.toList()
      ..sort((a, b) {
        final sa = (a['stamp'] as num?)?.toInt() ?? 0;
        final sb = (b['stamp'] as num?)?.toInt() ?? 0;
        return sa.compareTo(sb);
      });

    // stats for selected day
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
        // ── Date Chips (horizontal scroll) ───────────────────────────────
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.subtext,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // ── Stats bar for selected day ────────────────────────────────────
        Row(
          children: [
            _StatCard('Avg', '$avg', 'bpm', AppColors.primary),
            const SizedBox(width: 8),
            _StatCard('Max', '$max', 'bpm', AppColors.heartRed),
            const SizedBox(width: 8),
            _StatCard('Min', '$min', 'bpm', AppColors.vitalStress),
            const SizedBox(width: 8),
            _StatCard('Total', '${sortedData.length}', '', AppColors.vitalBP),
          ].map((w) => Expanded(child: w)).toList(),
        ),

        const SizedBox(height: 14),

        // ── Line Chart for selected day ───────────────────────────────────
        _DayLineChart(data: sortedData),

        const SizedBox(height: 14),

        // ── Readings list for selected day ────────────────────────────────
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedData.reversed.toList().length,
          itemBuilder: (ctx, i) {
            final r = sortedData.reversed.toList()[i];
            final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
            final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
            return _HrRow(stamp: stamp, bpm: hr);
          },
        ),
      ],
    );
  }
}

// ─── Day Line Chart ───────────────────────────────────────────────────────────

class _DayLineChart extends StatelessWidget {
  final List<Map<dynamic, dynamic>> data;
  const _DayLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) {
      final y = (e.value['heartRate'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), y);
    }).where((s) => s.y > 0).toList();

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
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
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
                  final dt = _stampToDateTime(stamp);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_p(dt.hour)}:${_p(dt.minute)}',
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
              getTooltipItems: (spots) => spots
                  .map((s) {
                    final idx = s.x.toInt().clamp(0, data.length - 1);
                    final stamp =
                        (data[idx]['stamp'] as num?)?.toInt() ?? 0;
                    final dt = _stampToDateTime(stamp);
                    return LineTooltipItem(
                      '${_p(dt.hour)}:${_p(dt.minute)}\n${s.y.toStringAsFixed(0)} bpm',
                      const TextStyle(
                          color: AppColors.heartRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _HrRow extends StatelessWidget {
  final int stamp;
  final int bpm;
  const _HrRow({required this.stamp, required this.bpm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight)),
      child: Row(
        children: [
          Icon(Icons.access_time_outlined,
              size: 14, color: AppColors.subtext.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(_fmtTime(stamp),
              style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
          const Spacer(),
          const Icon(Icons.favorite, color: AppColors.heartRed, size: 13),
          const SizedBox(width: 4),
          Text('$bpm bpm',
              style: const TextStyle(
                  color: AppColors.heartRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _fmtTime(int stamp) {
    if (stamp <= 0) return '\u2014';
    final dt = _stampToDateTime(stamp);
    return '${_p(dt.hour)}:${_p(dt.minute)}:${_p(dt.second)}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final List<Widget> children;
  const _StatsRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 8)])
          .toList()
        ..removeLast(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _StatCard(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          if (unit.isNotEmpty)
            Text(unit,
                style: TextStyle(
                    color: color.withValues(alpha: 0.8), fontSize: 9)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: AppColors.subtext,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600));
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _EmptyState(
      {required this.icon, required this.color, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 13, height: 1.6)),
          ],
        ),
      ),
    );
  }
}
