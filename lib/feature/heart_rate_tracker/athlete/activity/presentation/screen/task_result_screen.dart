import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/athlete_task_entity.dart';
import '../cubit/task_result_cubit.dart';
import '../cubit/task_result_state.dart';

double _toD(dynamic v) =>
    v == null ? 0.0 : v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;

class TaskResultScreen extends StatelessWidget {
  final AthleteTaskEntity task;

  const TaskResultScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocBuilder<TaskResultCubit, TaskResultState>(
        builder: (context, state) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _AppBar(task: task),
              if (state.status == TaskResultStatus.loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (state.status == TaskResultStatus.error)
                SliverFillRemaining(
                  child: _ErrorView(
                    message: state.errorMessage ?? 'Result load nahi hua',
                    onRetry: () => context.read<TaskResultCubit>().load(),
                  ),
                )
              else if (state.status == TaskResultStatus.loaded &&
                  state.result != null)
                _ResultBody(raw: state.result!.raw)
              else
                const SliverFillRemaining(child: _EmptyView()),
            ],
          );
        },
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final AthleteTaskEntity task;
  const _AppBar({required this.task});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 12, color: Color(0xFF80CBC4)),
                        SizedBox(width: 4),
                        Text('Completed',
                            style: TextStyle(
                                color: Color(0xFF80CBC4),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(task.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.timer_outlined,
                        size: 13, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text('${task.duration} min',
                        style:
                            const TextStyle(color: Colors.white60, fontSize: 12)),
                    if (task.assignedByName != null &&
                        task.assignedBy != 'self') ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.person_outline,
                          size: 13, color: Colors.white60),
                      const SizedBox(width: 4),
                      Text(task.assignedByName!,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12)),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Result Body ───────────────────────────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  final Map<String, dynamic> raw;
  const _ResultBody({required this.raw});

  @override
  Widget build(BuildContext context) {
    final results = (raw['results'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    if (results.isEmpty) {
      return const SliverFillRemaining(child: _EmptyView());
    }

    final widgets = <Widget>[];

    for (var i = 0; i < results.length; i++) {
      final session = results[i];
      if (results.length > 1) {
        widgets.add(_SessionHeader(index: i + 1));
        widgets.add(const SizedBox(height: 12));
      }
      widgets.addAll(_buildSession(session));
      if (i < results.length - 1) {
        widgets.add(const SizedBox(height: 24));
        widgets.add(const Divider(color: AppColors.border, height: 1));
        widgets.add(const SizedBox(height: 24));
      }
    }
    widgets.add(SizedBox(height: 32 + MediaQuery.of(context).padding.bottom));

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(widgets),
      ),
    );
  }

  List<Widget> _buildSession(Map<String, dynamic> session) {
    final stats =
        (session['aggregated_stats'] as Map<String, dynamic>?) ?? {};
    final rawList = (session['raw_data'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList()
            .reversed
            .toList() ?? // oldest-first for chart
        [];

    final hrStats = (stats['heart_rate'] as Map<String, dynamic>?) ?? {};
    final spo2Stats = (stats['spo2'] as Map<String, dynamic>?) ?? {};
    final stressStats = (stats['stress'] as Map<String, dynamic>?) ?? {};
    final sugarStats = (stats['sugar'] as Map<String, dynamic>?) ?? {};

    // Build chart spots
    final hrSpots = rawList.asMap().entries.map((e) {
      final hr = e.value['heart_rate'];
      return FlSpot(e.key.toDouble(), _toD(hr));
    }).where((s) => s.y > 0).toList();

    final hrvSpots = rawList.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _toD(e.value['sugar_level']));
    }).where((s) => s.y > 0).toList();

    final spo2Spots = rawList.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _toD(e.value['spo2']));
    }).where((s) => s.y > 0).toList();

    final stressSpots = rawList.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _toD(e.value['stress_level']));
    }).where((s) => s.y > 0).toList();

    final startedAt = session['started_at'] as String?;
    final endedAt = session['ended_at'] as String?;
    Duration? duration;
    if (startedAt != null && endedAt != null) {
      final s = DateTime.tryParse(startedAt);
      final e = DateTime.tryParse(endedAt);
      if (s != null && e != null) duration = e.difference(s);
    }

    return [
      // Session info
      _SessionInfoCard(
          startedAt: startedAt, endedAt: endedAt, duration: duration),
      const SizedBox(height: 14),

      // Heart rate hero chart
      if (hrSpots.isNotEmpty) ...[
        _HeartRateHeroCard(
          spots: hrSpots,
          avg: _toD(hrStats['avg']),
          min: _toD(hrStats['min']),
          max: _toD(hrStats['max']),
          readings: rawList.length,
        ),
        const SizedBox(height: 14),
      ],

      // HRV chart
      if (hrvSpots.length >= 2) ...[
        _HrvLineChart(
          spots: hrvSpots,
          avg: _toD(sugarStats['avg']),
          min: _toD(sugarStats['min']),
          max: _toD(sugarStats['max']),
        ),
        const SizedBox(height: 14),
      ],

      // SpO2 chart
      if (spo2Spots.isNotEmpty) ...[
        _VitalLineChart(
          title: 'SpO2',
          unit: '%',
          icon: Icons.bloodtype,
          color: const Color(0xFF5C6BC0),
          spots: spo2Spots,
          avg: _toD(spo2Stats['avg']),
          min: _toD(spo2Stats['min']),
          max: _toD(spo2Stats['max']),
        ),
        const SizedBox(height: 14),
      ],

      // Stress chart
      if (stressSpots.isNotEmpty) ...[
        _VitalLineChart(
          title: 'Stress Level',
          unit: '',
          icon: Icons.psychology,
          color: const Color(0xFF26A69A),
          spots: stressSpots,
          avg: _toD(stressStats['avg']),
          min: _toD(stressStats['min']),
          max: _toD(stressStats['max']),
        ),
      ],
    ];
  }
}

// ── Session Header ────────────────────────────────────────────────────────────

class _SessionHeader extends StatelessWidget {
  final int index;
  const _SessionHeader({required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('Session $index',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}

// ── Session Info Card ─────────────────────────────────────────────────────────

class _SessionInfoCard extends StatelessWidget {
  final String? startedAt;
  final String? endedAt;
  final Duration? duration;
  const _SessionInfoCard(
      {this.startedAt, this.endedAt, this.duration});

  String _fmt(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        if (startedAt != null)
          Expanded(
            child: _InfoChip(
                icon: Icons.play_circle_outline,
                label: 'Started',
                value: _fmt(startedAt!)),
          ),
        if (startedAt != null && endedAt != null)
          Container(
              width: 1,
              height: 36,
              color: AppColors.borderLight,
              margin: const EdgeInsets.symmetric(horizontal: 12)),
        if (endedAt != null)
          Expanded(
            child: _InfoChip(
                icon: Icons.stop_circle_outlined,
                label: 'Ended',
                value: _fmt(endedAt!)),
          ),
        if (duration != null) ...[
          Container(
              width: 1,
              height: 36,
              color: AppColors.borderLight,
              margin: const EdgeInsets.symmetric(horizontal: 12)),
          Expanded(
            child: _InfoChip(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: _fmtDuration(duration!)),
          ),
        ],
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 11, color: AppColors.subtext),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(color: AppColors.subtext, fontSize: 10)),
        ]),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Heart Rate Hero Card ──────────────────────────────────────────────────────

class _HeartRateHeroCard extends StatelessWidget {
  final List<FlSpot> spots;
  final double avg, min, max;
  final int readings;

  const _HeartRateHeroCard({
    required this.spots,
    required this.avg,
    required this.min,
    required this.max,
    required this.readings,
  });

  Color get _zoneColor {
    if (avg < 100) return const Color(0xFF43A047);
    if (avg < 140) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  String get _zoneLabel {
    if (avg < 100) return 'Normal';
    if (avg < 140) return 'Moderate';
    return 'High';
  }

  @override
  Widget build(BuildContext context) {
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10;
    final minY =
        (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 10)
            .clamp(0.0, double.infinity);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.favorite,
                        color: Color(0xFFEF9A9A), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Heart Rate',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: _zoneColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(_zoneLabel,
                        style: TextStyle(
                            color: _zoneColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),

                const SizedBox(height: 14),

                // Avg BPM display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(avg.toStringAsFixed(0),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            height: 1)),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 4),
                      child: Text('bpm',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 16)),
                    ),
                    const Spacer(),
                    Text('avg',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12)),
                  ],
                ),

                const SizedBox(height: 16),

                // Chart
                SizedBox(
                  height: 120,
                  child: LineChart(
                    LineChartData(
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.white.withValues(alpha: 0.1),
                            strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: const Color(0xFFEF9A9A),
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFFEF9A9A)
                                .withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) =>
                              const Color(0xFF0D47A1),
                          getTooltipItems: (spots) => spots
                              .map((s) => LineTooltipItem(
                                    '${s.y.toInt()} bpm',
                                    const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Stats row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: 'Min', value: '${min.toInt()}', unit: 'bpm'),
                      _Divider(),
                      _StatItem(label: 'Avg', value: avg.toStringAsFixed(0), unit: 'bpm'),
                      _Divider(),
                      _StatItem(label: 'Max', value: '${max.toInt()}', unit: 'bpm'),
                      _Divider(),
                      _StatItem(label: 'Readings', value: '$readings', unit: ''),
                    ],
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

class _StatItem extends StatelessWidget {
  final String label, value, unit;
  const _StatItem(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
      const SizedBox(height: 3),
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800)),
      if (unit.isNotEmpty)
        Text(unit,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 9)),
    ]);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2));
}

// ── Vital Line Chart (SpO2 / Stress) ─────────────────────────────────────────

class _VitalLineChart extends StatelessWidget {
  final String title, unit;
  final IconData icon;
  final Color color;
  final List<FlSpot> spots;
  final double avg, min, max;

  const _VitalLineChart({
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
    required this.spots,
    required this.avg,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;
    final minY =
        (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2)
            .clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: avg.toStringAsFixed(1),
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                          color: color.withValues(alpha: 0.7), fontSize: 12),
                    ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.borderLight, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: const TextStyle(
                            color: AppColors.subtext, fontSize: 9),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.text,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(1)}${unit.isNotEmpty ? " $unit" : ""}',
                              const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Min / Avg / Max chips
          Row(children: [
            _VitalChip(label: '↓ Min', value: min.toStringAsFixed(1), unit: unit, color: color),
            const SizedBox(width: 8),
            _VitalChip(label: '⊘ Avg', value: avg.toStringAsFixed(1), unit: unit, color: color),
            const SizedBox(width: 8),
            _VitalChip(label: '↑ Max', value: max.toStringAsFixed(1), unit: unit, color: color),
          ]),
        ],
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _VitalChip(
      {required this.label,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.7), fontSize: 9)),
          const SizedBox(height: 3),
          Text('$value${unit.isNotEmpty ? unit : ""}',
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ── HRV Line Chart (ECG style) ────────────────────────────────────────────────

const _kHrvColor = Color(0xFF40C4FF);

class _HrvLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final double avg, min, max;

  const _HrvLineChart({
    required this.spots,
    required this.avg,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10;
    final minY = (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 10)
        .clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kHrvColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: _kHrvColor.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _kHrvColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.monitor_heart_outlined,
                  color: _kHrvColor, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('HRV (RMSSD)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: avg.toStringAsFixed(1),
                    style: const TextStyle(
                        color: _kHrvColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: ' ms',
                    style: TextStyle(
                        color: _kHrvColor.withValues(alpha: 0.7),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 110,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.white.withValues(alpha: 0.05),
                      strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 9),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: _kHrvColor,
                    barWidth: 1.8,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    shadow: Shadow(
                        color: _kHrvColor.withValues(alpha: 0.4),
                        blurRadius: 6),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Min / Avg / Max chips
          Row(children: [
            _HrvChip(label: '↓ Min', value: min.toStringAsFixed(1)),
            const SizedBox(width: 8),
            _HrvChip(label: '⊘ Avg', value: avg.toStringAsFixed(1)),
            const SizedBox(width: 8),
            _HrvChip(label: '↑ Max', value: max.toStringAsFixed(1)),
          ]),
        ],
      ),
    );
  }
}

class _HrvChip extends StatelessWidget {
  final String label, value;
  const _HrvChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
            color: _kHrvColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  color: _kHrvColor.withValues(alpha: 0.7), fontSize: 9)),
          const SizedBox(height: 3),
          Text('$value ms',
              style: const TextStyle(
                  color: _kHrvColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ── Error / Empty ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                  color: AppColors.errorBg, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline,
                  color: AppColors.error, size: 36),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Dobara try karo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 60, color: AppColors.subtext),
            SizedBox(height: 16),
            Text('Koi result nahi mila',
                style: TextStyle(color: AppColors.subtext, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
