import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

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

class IndiviHistoryMobile extends StatelessWidget {
  const IndiviHistoryMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HeartBleCubit, HeartBleState>(
      buildWhen: (p, c) =>
          p.historyHrData != c.historyHrData ||
          p.isConnected   != c.isConnected   ||
          p.status        != c.status,
      builder: (context, state) => _HistoryShell(state: state),
    );
  }
}

class _HistoryShell extends StatelessWidget {
  final HeartBleState state;
  const _HistoryShell({required this.state});

  @override
  Widget build(BuildContext context) {
    final syncing = state.status.contains('yncing');
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(state: state),
            if (syncing) _StreamingBar(count: state.historyHrData.length),
            Expanded(child: _HeartRateTab(state: state)),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final HeartBleState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: const Icon(Icons.history, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Heart Rate History',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              Text('Synced heart rate data',
                  style: TextStyle(
                      color: AppColors.subtext, fontSize: 11, height: 1.3)),
            ],
          ),
          const Spacer(),
          _SyncButton(isSyncing: state.status.contains('yncing')),
        ],
      ),
    );
  }
}

// ─── Sync button ──────────────────────────────────────────────────────────────

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
          ? () => context.read<HeartBleCubit>().syncAllHistory(force: true)
          : null,
      child: Tooltip(
        message: connected
            ? 'Sync history from device'
            : 'Connect a device first',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: connected
                ? AppColors.primaryLight
                : AppColors.surfaceAlt,
            border: Border.all(
                color: connected
                    ? AppColors.primary.withOpacity(0.35)
                    : AppColors.border),
          ),
          child: RotationTransition(
            turns: _spin,
            child: Icon(Icons.sync,
                color: connected ? AppColors.primary : AppColors.textHint, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─── Streaming progress bar ───────────────────────────────────────────────────

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
            width: 14, height: 14,
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            'Streaming… $count readings received',
            style: const TextStyle(
                color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Heart Rate Tab ───────────────────────────────────────────────────────────

class _HeartRateTab extends StatelessWidget {
  final HeartBleState state;
  const _HeartRateTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final data = _dedupeHrData(state.historyHrData).toList()
      ..sort((a, b) {
        final sa = (a['stamp'] as num?)?.toInt() ?? 0;
        final sb = (b['stamp'] as num?)?.toInt() ?? 0;
        return sb.compareTo(sa);
      });
    if (data.isEmpty) {
      return _EmptyState(
        icon: Icons.favorite,
        color: AppColors.heartRed,
        message: 'No heart rate history.\nTap \u27f3 to sync from device.',
      );
    }

    final hrs = data
        .map((r) => (r['heartRate'] as num?)?.toInt() ?? 0)
        .where((v) => v > 0)
        .toList();
    final avg =
        hrs.isEmpty ? 0 : (hrs.reduce((a, b) => a + b) / hrs.length).round();
    final max =
        hrs.isEmpty ? 0 : hrs.reduce((a, b) => a > b ? a : b);
    final min =
        hrs.isEmpty ? 0 : hrs.reduce((a, b) => a < b ? a : b);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatsRow(children: [
                  _StatCard('Avg',      '$avg',          'bpm', AppColors.heartRed),
                  _StatCard('Max',      '$max',          'bpm', AppColors.heartRed),
                  _StatCard('Min',      '$min',          'bpm', AppColors.heartRed),
                  _StatCard('Readings', '${data.length}', '',   AppColors.heartRed),
                ]),
                const SizedBox(height: 14),
                _HrLineChart(data: data),
                const SizedBox(height: 14),
                _SectionLabel('READINGS (${data.length})'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final r = data[i];
                final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
                final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
                return _HrRow(index: i + 1, stamp: stamp, bpm: hr);
              },
              childCount: data.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── HR line chart ────────────────────────────────────────────────────────────

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
            color: AppColors.surface, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border)),
        child: const Center(
            child: Text('No chart data',
                style: TextStyle(color: AppColors.subtext))),
      );
    }

    final ys   = spots.map((s) => s.y).toList();
    final minY = (ys.reduce((a, b) => a < b ? a : b) - 5).clamp(0.0, 9999.0);
    final maxY =  ys.reduce((a, b) => a > b ? a : b) + 10;

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
                  color: AppColors.heartRed.withOpacity(0.08)),
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
                  final stamp = (pts[idx]['stamp'] as num?)?.toInt() ?? 0;
                  if (stamp <= 0) return const SizedBox.shrink();
                  final ms = stamp > 9999999999 ? stamp : stamp * 1000;
                  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
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

// ─── HR list row ──────────────────────────────────────────────────────────────

class _HrRow extends StatelessWidget {
  final int index;
  final int stamp;
  final int bpm;
  const _HrRow({required this.index, required this.stamp, required this.bpm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight)),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
                color: AppColors.heartRed.withOpacity(0.10),
                shape: BoxShape.circle),
            child: Center(
              child: Text('$index',
                  style: const TextStyle(
                      color: AppColors.heartRed,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Text(_fmtStamp(stamp),
              style:
                  const TextStyle(color: AppColors.subtext, fontSize: 12)),
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
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

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
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.7),
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
                    color: color.withOpacity(0.8), fontSize: 9)),
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
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.subtext,
                    fontSize: 13,
                    height: 1.6)),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtStamp(int stamp) {
  if (stamp <= 0) return '\u2014';
  final ms = stamp > 9999999999 ? stamp : stamp * 1000;
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final isToday =
      dt.year == now.year && dt.month == now.month && dt.day == now.day;
  final dateStr =
      isToday ? 'Today' : '${_p(dt.day)}/${_p(dt.month)}/${dt.year}';
  return '$dateStr  ${_p(dt.hour)}:${_p(dt.minute)}';
}

String _p(int n) => n.toString().padLeft(2, '0');
