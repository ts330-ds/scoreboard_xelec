import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

import '../widgets/empty_state.dart';
import '../widgets/history_data_utils.dart';
import '../widgets/last_push_info.dart';
import '../widgets/push_now_button.dart';
import '../widgets/sleep_from_hr.dart';
import '../widgets/sleep_hr_chart.dart';
import '../widgets/polling_status_banner.dart';
import '../widgets/sync_button.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class AthleteHistoryScreen extends StatelessWidget {
  const AthleteHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HeartBleCubit, HeartBleState>(
      buildWhen: (p, c) =>
          p.historyHrData != c.historyHrData ||
          p.historyRrData != c.historyRrData ||
          p.historySleep != c.historySleep ||
          p.isConnected != c.isConnected ||
          p.status != c.status,
      builder: (context, bleState) => _HistoryShell(bleState: bleState),
    );
  }
}

// ─── Shell ────────────────────────────────────────────────────────────────────

class _HistoryShell extends StatefulWidget {
  final HeartBleState bleState;
  const _HistoryShell({required this.bleState});

  @override
  State<_HistoryShell> createState() => _HistoryShellState();
}

class _HistoryShellState extends State<_HistoryShell> {
  final _lastPushKey = GlobalKey<LastPushInfoState>();
  int _selectedDateIdx = 0;

  bool get _syncing {
    final s = widget.bleState.status.toLowerCase();
    return s.contains('syncing') || s.contains('yncing');
  }

  void _onSyncTap() {
    if (!Platform.isAndroid) return;
    if (_syncing) return;
    if (!widget.bleState.isConnected) {
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

  // ── Group all HR data by date (newest first) ──────────────────────────────

  List<_DayGroup> _buildDayGroups() {
    final raw = widget.bleState.historyHrData;
    if (raw.isEmpty) return [];
    final all = dedupeHrData(raw);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateFmt = DateFormat('dd MMM');

    final grouped = <String, List<Map<dynamic, dynamic>>>{};
    final dateKeys = <String, DateTime>{};

    for (final r in all) {
      final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
      if (stamp <= 0) continue;
      final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
      if (hr <= 0) continue;
      final dt = stampToDateTime(stamp);
      final dtDay = DateTime(dt.year, dt.month, dt.day);
      String label;
      if (dtDay == today) {
        label = 'Today';
      } else if (dtDay == yesterday) {
        label = 'Yesterday';
      } else {
        label = dateFmt.format(dt);
      }
      grouped.putIfAbsent(label, () => []).add(r);
      dateKeys.putIfAbsent(label, () => dtDay);
    }

    // Sort: newest date first
    final sortedLabels = grouped.keys.toList()
      ..sort((a, b) => dateKeys[b]!.compareTo(dateKeys[a]!));

    return sortedLabels.map((label) {
      final readings = grouped[label]!
        ..sort((a, b) {
          final sa = (a['stamp'] as num?)?.toInt() ?? 0;
          final sb = (b['stamp'] as num?)?.toInt() ?? 0;
          return sa.compareTo(sb); // chronological for chart
        });
      final hrs = readings
          .map((r) => (r['heartRate'] as num?)?.toInt() ?? 0)
          .where((v) => v > 0)
          .toList();
      if (hrs.isEmpty) return null;
      return _DayGroup(
        label: label,
        date: dateKeys[label]!,
        readings: readings,
        avg: (hrs.reduce((a, b) => a + b) / hrs.length).round(),
        max: hrs.reduce((a, b) => a > b ? a : b),
        min: hrs.reduce((a, b) => a < b ? a : b),
        count: readings.length,
      );
    }).whereType<_DayGroup>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final dayGroups = _buildDayGroups();

    // Clamp selected index
    if (_selectedDateIdx >= dayGroups.length) {
      _selectedDateIdx = dayGroups.isEmpty ? 0 : dayGroups.length - 1;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Device History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (Platform.isAndroid)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SyncButton(
                isSyncing: _syncing,
                onTap: _syncing ? null : _onSyncTap,
              ),
            ),
        ],
      ),
      body: !Platform.isAndroid
          ? const _IosPlaceholder()
          : Column(
              children: [
                // ── Syncing indicator ──────────────────────────────────
                if (_syncing)
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
                          'Syncing… ${widget.bleState.historyHrData.length} readings',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                // ── Last push info + Push button ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: LastPushInfo(key: _lastPushKey),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: PushNowButton(
                    onPushComplete: () =>
                        _lastPushKey.currentState?.reload(),
                  ),
                ),
                // ── V3 Polling status banner ─────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: PollingStatusBanner(),
                ),
                // ── Content ───────────────────────────────────────────
                Expanded(
                  child: dayGroups.isEmpty
                      ? HistoryEmptyState(
                          icon: Icons.show_chart_rounded,
                          color: AppColors.primary,
                          message: _syncing
                              ? 'Receiving data from device…'
                              : 'No heart rate history yet.\nTap sync to fetch from device.',
                        )
                      : Column(
                          children: [
                            // ── Date tabs ─────────────────────────────
                            const SizedBox(height: 12),
                            _DateTabs(
                              groups: dayGroups,
                              selectedIdx: _selectedDateIdx,
                              onTap: (i) {
                                setState(() => _selectedDateIdx = i);
                              },
                            ),
                            // ── Day detail ────────────────────────────
                            Expanded(
                              child: _DayDetail(
                                group: dayGroups[_selectedDateIdx],
                                allHrData: dedupeHrData(widget.bleState.historyHrData),
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

// ─── Day group model ─────────────────────────────────────────────────────────

class _DayGroup {
  final String label;
  final DateTime date;
  final List<Map<dynamic, dynamic>> readings;
  final int avg;
  final int max;
  final int min;
  final int count;
  const _DayGroup({
    required this.label,
    required this.date,
    required this.readings,
    required this.avg,
    required this.max,
    required this.min,
    required this.count,
  });
}

// ─── Scrollable date tabs ────────────────────────────────────────────────────

class _DateTabs extends StatelessWidget {
  final List<_DayGroup> groups;
  final int selectedIdx;
  final ValueChanged<int> onTap;
  const _DateTabs({
    required this.groups,
    required this.selectedIdx,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = groups[i];
          final selected = i == selectedIdx;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                g.label,
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

// ─── Day detail (stats + chart) ──────────────────────────────────────────────

class _DayDetail extends StatelessWidget {
  final _DayGroup group;
  final List<Map<dynamic, dynamic>> allHrData;
  const _DayDetail({required this.group, required this.allHrData});

  @override
  Widget build(BuildContext context) {
    final hasHrData = group.readings.isNotEmpty;
    final sleepResult = hasHrData ? detectSleepFromHr(allHrData, group.date) : null;

    if (!hasHrData && sleepResult == null) {
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
          if (hasHrData) ...[
            // ── Stats row ──────────────────────────────────────────────
            Row(
              children: [
                _StatTile(
                  label: 'AVG',
                  value: '${group.avg}',
                  unit: 'bpm',
                  color: AppColors.primary,
                  icon: Icons.favorite,
                ),
                const SizedBox(width: 10),
                _StatTile(
                  label: 'MAX',
                  value: '${group.max}',
                  unit: 'bpm',
                  color: AppColors.heartRed,
                  icon: Icons.arrow_upward_rounded,
                ),
                const SizedBox(width: 10),
                _StatTile(
                  label: 'MIN',
                  value: '${group.min}',
                  unit: 'bpm',
                  color: AppColors.vitalStress,
                  icon: Icons.arrow_downward_rounded,
                ),
              ].map((w) => Expanded(child: w)).toList(),
            ),
            const SizedBox(height: 16),
            // ── Heart rate line chart (scrollable x-axis) ──────────────
            _HrScrollableChart(readings: group.readings),
          ],
          // ── Sleep chart (derived from overnight HR) ────────────────
          if (sleepResult != null) ...[
            const SizedBox(height: 16),
            SleepHrChart(sleep: sleepResult),
          ],
        ],
      ),
    );
  }
}

// ─── Stat tile ───────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
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
                    unit,
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

// ─── Scrollable HR line chart (fixed y-axis, per-minute x-axis) ──────────────

class _HrScrollableChart extends StatelessWidget {
  final List<Map<dynamic, dynamic>> readings;
  const _HrScrollableChart({required this.readings});

  static const _gapThresholdMin = 5.0;
  static const _segmentGapMin = 2.0;

  ({
    List<List<FlSpot>> segments,
    List<int> segmentStartMs,
    List<double> segmentDurations,
    double maxX,
    double minY,
    double maxY,
  }) _buildSpots() {
    if (readings.isEmpty) {
      return (segments: [], segmentStartMs: [], segmentDurations: [], maxX: 0, minY: 0, maxY: 100);
    }

    final rawPoints = <({int ms, double hr})>[];
    for (final r in readings) {
      final s = (r['stamp'] as num?)?.toInt() ?? 0;
      final hr = (r['heartRate'] as num?)?.toDouble() ?? 0;
      if (s <= 0 || hr <= 0) continue;
      final ms = s > 9999999999 ? s : s * 1000;
      rawPoints.add((ms: ms, hr: hr));
    }

    if (rawPoints.isEmpty) {
      return (segments: [], segmentStartMs: [], segmentDurations: [], maxX: 0, minY: 0, maxY: 100);
    }

    final rawSegments = <List<({int ms, double hr})>>[];
    var current = <({int ms, double hr})>[rawPoints.first];
    for (int i = 1; i < rawPoints.length; i++) {
      final gapMin = (rawPoints[i].ms - rawPoints[i - 1].ms) / 60000.0;
      if (gapMin > _gapThresholdMin) {
        rawSegments.add(current);
        current = [];
      }
      current.add(rawPoints[i]);
    }
    rawSegments.add(current);

    final segments = <List<FlSpot>>[];
    final segmentStartMs = <int>[];
    final segmentDurations = <double>[];
    double xOffset = 0;

    // Latest segment first — reverse order so newest data is on left
    for (int si = rawSegments.length - 1; si >= 0; si--) {
      final seg = rawSegments[si];
      if (seg.isEmpty) continue;
      final segFirstMs = seg.first.ms;
      segmentStartMs.add(segFirstMs);
      final segDuration = (seg.last.ms - segFirstMs) / 60000.0;
      segmentDurations.add(segDuration);
      // Reverse within segment: latest reading at lower x
      final spots = seg.map((p) {
        final localMin = (p.ms - segFirstMs) / 60000.0;
        return FlSpot(xOffset + (segDuration - localMin), p.hr);
      }).toList()
        ..sort((a, b) => a.x.compareTo(b.x));
      segments.add(spots);
      xOffset += segDuration + _segmentGapMin;
    }

    final allY = segments.expand((s) => s.map((p) => p.y)).toList();
    final rawMin = allY.reduce(math.min);
    final rawMax = allY.reduce(math.max);
    final minY = ((rawMin - 4) / 8).floor() * 8.0;
    final maxY = ((rawMax + 4) / 8).ceil() * 8.0;
    final maxX = xOffset > _segmentGapMin ? xOffset - _segmentGapMin : 0.0;

    return (
      segments: segments,
      segmentStartMs: segmentStartMs,
      segmentDurations: segmentDurations,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  int _xToMs(
    double x,
    List<List<FlSpot>> segments,
    List<int> segmentStartMs,
    List<double> segmentDurations,
  ) {
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.isEmpty) continue;
      if (x >= seg.first.x && x <= seg.last.x) {
        final localMin = x - seg.first.x;
        // x is reversed: 0 = latest, duration = oldest within segment
        final realMin = segmentDurations[i] - localMin;
        return segmentStartMs[i] + (realMin * 60000).toInt();
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('No data', style: TextStyle(color: AppColors.subtext)),
        ),
      );
    }

    final data = _buildSpots();
    if (data.segments.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width - 32 - 42;
    final chartWidth = math.max(screenWidth, data.maxX * 40.0);
    const double yInterval = 8;
    final yLabelCount = ((data.maxY - data.minY) / yInterval).ceil() + 1;
    const double pxPerLabel = 18.0;
    final chartHeight = math.max(220.0, yLabelCount * pxPerLabel);

    final gapAnnotations = <VerticalRangeAnnotation>[];
    for (int i = 0; i < data.segments.length - 1; i++) {
      final gapStart = data.segments[i].last.x;
      final gapEnd = data.segments[i + 1].first.x;
      gapAnnotations.add(VerticalRangeAnnotation(
        x1: gapStart,
        x2: gapEnd,
        color: AppColors.subtext.withValues(alpha: 0.07),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.heartRed.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                const Icon(Icons.show_chart_rounded,
                    size: 14, color: AppColors.heartRed),
                const SizedBox(width: 6),
                const Text(
                  'Heart Rate',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.swipe_outlined,
                    size: 12,
                    color: AppColors.subtext.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text('Swipe to scroll',
                    style: TextStyle(
                        color: AppColors.subtext.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            height: chartHeight,
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 26),
                    child: LineChart(
                      LineChartData(
                        minY: data.minY,
                        maxY: data.maxY,
                        minX: 0,
                        maxX: 1,
                        lineBarsData: [],
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                              interval: yInterval,
                              getTitlesWidget: (v, _) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  '${v.toInt()}',
                                  style: const TextStyle(
                                    color: AppColors.subtext,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        lineTouchData:
                            const LineTouchData(enabled: false),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: chartWidth,
                        child: LineChart(
                          LineChartData(
                            minY: data.minY,
                            maxY: data.maxY,
                            minX: -0.5,
                            maxX: data.maxX + 0.5,
                            clipData: const FlClipData.none(),
                            rangeAnnotations: RangeAnnotations(
                              verticalRangeAnnotations: gapAnnotations,
                            ),
                            lineBarsData: data.segments.map((seg) =>
                              LineChartBarData(
                                spots: seg,
                                color: AppColors.heartRed,
                                barWidth: 2.2,
                                isCurved: true,
                                curveSmoothness: 0.2,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.heartRed.withValues(alpha: 0.18),
                                      AppColors.heartRed.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ).toList(),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              verticalInterval: 1,
                              horizontalInterval: yInterval,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.borderLight,
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (_) => FlLine(
                                color: AppColors.borderLight
                                    .withValues(alpha: 0.5),
                                strokeWidth: 0.5,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 1,
                                  getTitlesWidget: (val, _) {
                                    final ms = _xToMs(
                                      val,
                                      data.segments,
                                      data.segmentStartMs,
                                      data.segmentDurations,
                                    );
                                    if (ms == 0) {
                                      return const SizedBox.shrink();
                                    }
                                    final dt = DateTime
                                        .fromMillisecondsSinceEpoch(ms);
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '${pad2(dt.hour)}:${pad2(dt.minute)}',
                                        style: const TextStyle(
                                          color: AppColors.subtext,
                                          fontSize: 8,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) =>
                                    AppColors.surface,
                                getTooltipItems: (touchedSpots) =>
                                    touchedSpots.map((s) {
                                  final ms = _xToMs(
                                    s.x,
                                    data.segments,
                                    data.segmentStartMs,
                                    data.segmentDurations,
                                  );
                                  final dt = DateTime
                                      .fromMillisecondsSinceEpoch(ms);
                                  return LineTooltipItem(
                                    '${pad2(dt.hour)}:${pad2(dt.minute)}:${pad2(dt.second)}\n${s.y.toStringAsFixed(0)} bpm',
                                    const TextStyle(
                                      color: AppColors.heartRed,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
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

// ─── iOS placeholder ────────────────────────────────────────────────────────

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
