import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

// ── Colors ────────────────────────────────────────────────────────────────────
const _kHrvColor    = AppColors.primary;
const _kRrColor     = Color(0xFF26A69A);
const _kBg          = AppColors.bg;
const _kEcgBg       = Color(0xFF0A1628);   // ECG dark navy background
const _kEcgRr       = Color(0xFF00E676);   // ECG bright green — RR intervals
const _kEcgHrv      = Color(0xFF40C4FF);   // ECG cyan-blue — RMSSD
const _kEcgGrid     = Color(0xFF1A3A2A);   // ECG dark green grid
const _kEcgGridMajor = Color(0xFF1F4D35);  // ECG major grid

class AthleteHrvDetailScreen extends StatelessWidget {
  const AthleteHrvDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('HRV & RR Intervals',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<HeartBleCubit, HeartBleState>(
        buildWhen: (p, c) =>
            p.hrv != c.hrv ||
            p.rrBuffer != c.rrBuffer ||
            p.historyRrData != c.historyRrData ||
            p.historyHrData != c.historyHrData,
        builder: (context, state) => _HrvBody(state: state),
      ),
    );
  }
}

// ── Main Body ─────────────────────────────────────────────────────────────────
class _HrvBody extends StatelessWidget {
  final HeartBleState state;
  const _HrvBody({required this.state});

  // Compute per-minute RMSSD from RR buffer
  double _rmssd(List<int> rr) {
    if (rr.length < 2) return 0.0;
    double sumSq = 0;
    for (int i = 1; i < rr.length; i++) {
      final d = (rr[i] - rr[i - 1]).toDouble();
      sumSq += d * d;
    }
    return math.sqrt(sumSq / (rr.length - 1));
  }

  // Build (index, rrMs) points from historyRrData
  List<({int idx, double rrMs})> _rrPoints() {
    final list = state.historyRrData;
    if (list.isEmpty) return [];
    return list.asMap().entries.map((e) {
      final rr = (e.value['rr'] as num?)?.toDouble() ??
          (e.value['rrInterval'] as num?)?.toDouble() ??
          (e.value['value'] as num?)?.toDouble() ?? 0.0;
      return (idx: e.key, rrMs: rr);
    }).where((p) => p.rrMs > 0).toList();
  }

  // Build sliding-window RMSSD from historyRrData
  List<({int idx, double rmssd})> _historicalRmssd() {
    final list = state.historyRrData;
    if (list.length < 10) return [];
    const window = 10;
    final result = <({int idx, double rmssd})>[];
    for (int i = window; i <= list.length; i++) {
      final slice = list.sublist(i - window, i)
          .map((e) =>
              (e['rr'] as num?)?.toInt() ??
              (e['rrInterval'] as num?)?.toInt() ??
              (e['value'] as num?)?.toInt() ?? 0)
          .where((v) => v > 0)
          .toList();
      if (slice.length >= 2) {
        result.add((idx: i - 1, rmssd: _rmssd(slice)));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final liveRmssd    = state.hrv;
    final rrBuffer     = state.rrBuffer;
    final rrPoints     = _rrPoints();
    final rmssdHistory = _historicalRmssd();

    final hasLive    = liveRmssd > 0 || rrBuffer.isNotEmpty;
    final hasHistory = rrPoints.isNotEmpty;

    if (!hasLive && !hasHistory) {
      return _EmptyState(isConnected: state.isConnected);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Live HRV summary card ──────────────────────────────────────────
        if (hasLive) ...[
          _SectionLabel('LIVE HRV'),
          const SizedBox(height: 10),
          _LiveHrvCard(hrv: liveRmssd, rrBuffer: rrBuffer),
          const SizedBox(height: 24),
        ],

        // ── Live RR Buffer chart ───────────────────────────────────────────
        if (rrBuffer.length >= 3) ...[
          _SectionLabel('LIVE RR INTERVALS  (last ${rrBuffer.length} beats)'),
          const SizedBox(height: 10),
          _RrLineChart(
            points: rrBuffer
                .asMap()
                .entries
                .map((e) => (idx: e.key, rrMs: e.value.toDouble()))
                .toList(),
            color: _kRrColor,
            height: 180,
          ),
          const SizedBox(height: 8),
          _RrStats(values: rrBuffer.map((v) => v.toDouble()).toList()),
          const SizedBox(height: 24),
        ],

        // ── Historical RR chart ────────────────────────────────────────────
        if (rrPoints.length >= 3) ...[
          _SectionLabel('HISTORICAL RR INTERVALS  (${rrPoints.length} samples)'),
          const SizedBox(height: 10),
          _RrLineChart(
            points: rrPoints,
            color: _kRrColor,
            height: 200,
          ),
          const SizedBox(height: 8),
          _RrStats(values: rrPoints.map((p) => p.rrMs).toList()),
          const SizedBox(height: 24),
        ],

        // ── RMSSD history chart ────────────────────────────────────────────
        if (rmssdHistory.length >= 3) ...[
          _SectionLabel('HRV (RMSSD) OVER TIME'),
          const SizedBox(height: 10),
          _RmssdLineChart(points: rmssdHistory),
          const SizedBox(height: 8),
          _RmssdStats(values: rmssdHistory.map((p) => p.rmssd).toList()),
          const SizedBox(height: 24),
        ],

        // ── Interpretation card ────────────────────────────────────────────
        if (liveRmssd > 0) ...[
          _SectionLabel('INTERPRETATION'),
          const SizedBox(height: 10),
          _InterpretationCard(hrv: liveRmssd),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

// ── Live HRV Summary Card ─────────────────────────────────────────────────────
class _LiveHrvCard extends StatelessWidget {
  final double hrv;
  final List<int> rrBuffer;
  const _LiveHrvCard({required this.hrv, required this.rrBuffer});

  (String, Color) _zone(double v) {
    if (v >= 50) return ('Excellent', AppColors.success);
    if (v >= 30) return ('Good',      const Color(0xFF26A69A));
    if (v >= 20) return ('Fair',      AppColors.warning);
    return ('Low', AppColors.error);
  }

  @override
  Widget build(BuildContext context) {
    final (label, color) = _zone(hrv);
    final avgRr = rrBuffer.isEmpty
        ? 0.0
        : rrBuffer.reduce((a, b) => a + b) / rrBuffer.length;
    final bpm = avgRr > 0 ? (60000 / avgRr).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kHrvColor.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: _kHrvColor.withValues(alpha: 0.07), blurRadius: 10)],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kHrvColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.monitor_heart_outlined, color: _kHrvColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('RMSSD', style: TextStyle(color: AppColors.subtext, fontSize: 12)),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(hrv > 0 ? hrv.toStringAsFixed(1) : '--',
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 36,
                        fontWeight: FontWeight.w800, height: 1)),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6, left: 4),
                  child: Text('ms', style: TextStyle(color: AppColors.subtext, fontSize: 13)),
                ),
              ]),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(label,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (rrBuffer.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 16),
          Row(children: [
            _MiniStat('Avg RR', '${avgRr.toStringAsFixed(0)} ms', _kRrColor),
            const SizedBox(width: 16),
            _MiniStat('Est. HR', '$bpm bpm', AppColors.heartRed),
            const SizedBox(width: 16),
            _MiniStat('Samples', '${rrBuffer.length}', AppColors.vitalBP),
          ]),
        ],
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.subtext, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      );
}

// ── RR ECG Chart ──────────────────────────────────────────────────────────────
class _RrLineChart extends StatelessWidget {
  final List<({int idx, double rrMs})> points;
  final Color color;   // kept for API compat, ECG overrides with _kEcgRr
  final double height;
  const _RrLineChart({required this.points, required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final spots   = points.map((p) => FlSpot(p.idx.toDouble(), p.rrMs)).toList();
    final ys      = spots.map((s) => s.y).toList();
    final minY    = (ys.reduce(math.min) - 40).clamp(0.0, 9999.0);
    final maxY    = ys.reduce(math.max) + 40;
    final hRange  = maxY - minY;
    final hStep   = (hRange / 5).clamp(10.0, 9999.0);
    final vStep   = points.length <= 1 ? 1.0 : (points.length / 5).ceilToDouble();

    return _EcgContainer(
      height: height,
      child: LineChart(LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: _kEcgRr,
            barWidth: 1.8,
            isCurved: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            shadow: const Shadow(color: Color(0x6600E676), blurRadius: 6),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: hStep,
          verticalInterval: vStep,
          getDrawingHorizontalLine: (v) {
            final isMajor = ((v - minY) % (hStep * 5)).abs() < 1;
            return FlLine(
              color: isMajor ? _kEcgGridMajor : _kEcgGrid,
              strokeWidth: isMajor ? 0.8 : 0.4,
            );
          },
          getDrawingVerticalLine: (_) =>
              const FlLine(color: _kEcgGrid, strokeWidth: 0.4),
        ),
        titlesData: FlTitlesData(
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: vStep,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 7)),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: hStep,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 7)),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: _kEcgGridMajor, width: 0.8),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF0D2137),
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(0)} ms',
                      const TextStyle(
                          color: _kEcgRr, fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ))
                .toList(),
          ),
        ),
      )),
    );
  }
}

// ── ECG Container ─────────────────────────────────────────────────────────────
class _EcgContainer extends StatelessWidget {
  final Widget child;
  final double height;
  const _EcgContainer({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(2, 12, 10, 8),
      decoration: BoxDecoration(
        color: _kEcgBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kEcgGridMajor, width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x3300E676), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }
}

// ── RR Statistics Row ─────────────────────────────────────────────────────────
class _RrStats extends StatelessWidget {
  final List<double> values;
  const _RrStats({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final sdnn = _sdnn(values, avg);

    return Row(children: [
      _StatChip('Avg', '${avg.toStringAsFixed(0)} ms', _kRrColor),
      const SizedBox(width: 8),
      _StatChip('Min', '${min.toStringAsFixed(0)} ms', AppColors.vitalStress),
      const SizedBox(width: 8),
      _StatChip('Max', '${max.toStringAsFixed(0)} ms', AppColors.heartRed),
      const SizedBox(width: 8),
      _StatChip('SDNN', '${sdnn.toStringAsFixed(1)} ms', AppColors.primary),
    ]);
  }

  double _sdnn(List<double> vals, double mean) {
    if (vals.length < 2) return 0;
    final variance = vals.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / vals.length;
    return math.sqrt(variance);
  }
}

// ── RMSSD ECG Chart ───────────────────────────────────────────────────────────
class _RmssdLineChart extends StatelessWidget {
  final List<({int idx, double rmssd})> points;
  const _RmssdLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final spots   = points.map((p) => FlSpot(p.idx.toDouble(), p.rmssd)).toList();
    final ys      = spots.map((s) => s.y).toList();
    final minY    = (ys.reduce(math.min) - 5).clamp(0.0, 9999.0);
    final maxY    = ys.reduce(math.max) + 10;
    final hRange  = maxY - minY;
    final hStep   = (hRange / 5).clamp(1.0, 9999.0);
    final vStep   = points.length <= 1 ? 1.0 : (points.length / 5).ceilToDouble();

    return _EcgContainer(
      height: 200,
      child: LineChart(LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: _kEcgHrv,
            barWidth: 1.8,
            isCurved: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            shadow: const Shadow(color: Color(0x6640C4FF), blurRadius: 6),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: hStep,
          verticalInterval: vStep,
          getDrawingHorizontalLine: (v) {
            final isMajor = ((v - minY) % (hStep * 5)).abs() < 0.5;
            return FlLine(
              color: isMajor ? _kEcgGridMajor : _kEcgGrid,
              strokeWidth: isMajor ? 0.8 : 0.4,
            );
          },
          getDrawingVerticalLine: (_) =>
              const FlLine(color: _kEcgGrid, strokeWidth: 0.4),
        ),
        titlesData: FlTitlesData(
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: vStep,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: const TextStyle(color: Color(0xFF4DD0E1), fontSize: 7)),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: hStep,
              getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                  style: const TextStyle(color: Color(0xFF4DD0E1), fontSize: 7)),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: _kEcgGridMajor, width: 0.8),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF0D2137),
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(1)} ms',
                      const TextStyle(
                          color: _kEcgHrv, fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ))
                .toList(),
          ),
        ),
      )),
    );
  }
}

// ── RMSSD Statistics ──────────────────────────────────────────────────────────
class _RmssdStats extends StatelessWidget {
  final List<double> values;
  const _RmssdStats({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);

    return Row(children: [
      _StatChip('Avg RMSSD', '${avg.toStringAsFixed(1)} ms', _kHrvColor),
      const SizedBox(width: 8),
      _StatChip('Min', '${min.toStringAsFixed(1)} ms', AppColors.vitalStress),
      const SizedBox(width: 8),
      _StatChip('Max', '${max.toStringAsFixed(1)} ms', AppColors.success),
    ]);
  }
}

// ── Interpretation Card ───────────────────────────────────────────────────────
class _InterpretationCard extends StatelessWidget {
  final double hrv;
  const _InterpretationCard({required this.hrv});

  ({String zone, String message, Color color, IconData icon}) _interpret() {
    if (hrv >= 50) {
      return (
        zone: 'Excellent Recovery',
        message: 'Your nervous system is well-recovered. Ideal for high-intensity training today.',
        color: AppColors.success,
        icon: Icons.trending_up,
      );
    }
    if (hrv >= 30) {
      return (
        zone: 'Good Recovery',
        message: 'Moderate recovery. Suitable for normal training load.',
        color: const Color(0xFF26A69A),
        icon: Icons.check_circle_outline,
      );
    }
    if (hrv >= 20) {
      return (
        zone: 'Fair — Moderate Stress',
        message: 'Signs of fatigue or stress. Consider a lighter session or active recovery.',
        color: AppColors.warning,
        icon: Icons.warning_amber_outlined,
      );
    }
    return (
      zone: 'Low — High Stress',
      message: 'Significant fatigue detected. Prioritize rest and recovery today.',
      color: AppColors.error,
      icon: Icons.bedtime_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _interpret();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.color.withValues(alpha: 0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(info.icon, color: info.color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(info.zone,
                style: TextStyle(
                    color: info.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(info.message,
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 13, height: 1.5)),
          ]),
        ),
      ]),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isConnected;
  const _EmptyState({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kHrvColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monitor_heart_outlined, color: _kHrvColor, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('No HRV Data',
              style: TextStyle(
                  color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            isConnected
                ? 'Wear the device and wait for RR intervals\nto be captured in real-time.'
                : 'Connect your device to start\ncapturing HRV data.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.subtext, fontSize: 14, height: 1.5),
          ),
        ]),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.subtext,
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600));
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}
