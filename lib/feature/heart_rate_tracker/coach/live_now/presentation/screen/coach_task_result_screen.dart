import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../../domain/entity/coach_task_result_entity.dart';
import '../cubit/coach_task_result_cubit.dart';
import '../cubit/coach_task_result_state.dart';

// Helper: elapsed seconds → "M:SS" or "H:MM:SS"
String _fmtElapsed(int totalSeconds) {
  if (totalSeconds < 0) totalSeconds = 0;
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

// Helper: anchor + offsetSeconds → "HH:MM" (local time)
String _fmtClock(DateTime anchor, int offsetSeconds) {
  final dt = anchor.add(Duration(seconds: offsetSeconds)).toLocal();
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _fmtClockSec(DateTime anchor, int offsetSeconds) {
  final dt = anchor.add(Duration(seconds: offsetSeconds)).toLocal();
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

class CoachTaskResultScreen extends StatelessWidget {
  final int taskId;
  final String athleteName;
  final String taskName;

  const CoachTaskResultScreen({
    super.key,
    required this.taskId,
    required this.athleteName,
    required this.taskName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CoachTaskResultCubit(
        taskId: taskId,
        getTaskResult: sl(),
      )..load(),
      child: _CoachTaskResultBody(
        athleteName: athleteName,
        taskName: taskName,
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _CoachTaskResultBody extends StatelessWidget {
  final String athleteName;
  final String taskName;

  const _CoachTaskResultBody(
      {required this.athleteName, required this.taskName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(athleteName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text(taskName,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Done',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<CoachTaskResultCubit, CoachTaskResultState>(
        builder: (context, state) {
          if (state.status == CoachTaskResultStatus.loading ||
              state.status == CoachTaskResultStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == CoachTaskResultStatus.error) {
            return _ErrorView(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => context.read<CoachTaskResultCubit>().load(),
            );
          }

          final sessions = state.result?.sessions ?? [];
          if (sessions.isEmpty) {
            return const _EmptyView();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            itemCount: sessions.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(
                  bottom: i < sessions.length - 1 ? 24 : 0),
              child: _SessionView(
                session: sessions[i],
                sessionNumber: sessions.length > 1 ? i + 1 : null,
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

// ── Session View ──────────────────────────────────────────────────────────────

class _SessionView extends StatelessWidget {
  final CoachTaskResultSession session;
  final int? sessionNumber;

  const _SessionView({required this.session, this.sessionNumber});

  @override
  Widget build(BuildContext context) {
    final hasChart = session.rawData.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sessionNumber != null) ...[
          Text('Session $sessionNumber',
              style: const TextStyle(
                  color: AppColors.subtext,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 10),
        ],

        // ── 1. Heart Rate chart (top, prominent)
        if (hasChart) ...[
          _SectionHeader(
              icon: Icons.favorite_rounded, title: 'Heart Rate'),
          const SizedBox(height: 10),
          _HeartRateHeroCard(session: session),
          const SizedBox(height: 16),
        ] else ...[
          _HeartRateSummaryCard(stats: session.stats.heartRate),
          const SizedBox(height: 16),
        ],

        // ── 2. Heart Rate Zones distribution
        if (hasChart) ...[
          _HrZonesCard(
            spots: ([...session.rawData]
                  ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt)))
                .map((p) => FlSpot(
                      p.recordedAt
                          .difference(session.startedAt)
                          .inSeconds
                          .toDouble(),
                      p.heartRate.toDouble(),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // ── 3. Session info
        _SessionInfoCard(session: session),
        const SizedBox(height: 16),

        // ── 4. HRV chart
        Builder(builder: (context) {
          // Anchor x-axis to session.startedAt so labels show clock time
          final sorted = [...session.rawData]
            ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
          if (sorted.isEmpty) return const SizedBox.shrink();
          final anchor = session.startedAt;
          final hrvSpots = <FlSpot>[];
          for (final p in sorted) {
            final v = p.sugarLevel;
            if (v == null || v <= 0) continue;
            hrvSpots.add(FlSpot(
              p.recordedAt.difference(anchor).inSeconds.toDouble(),
              v,
            ));
          }
          if (!hasChart || hrvSpots.length < 2) {
            return const SizedBox.shrink();
          }
          final sessionSpan = session.duration.inSeconds.toDouble();
          final lastX = hrvSpots.last.x;
          final totalSec = sessionSpan > 0 ? sessionSpan : lastX;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                  icon: Icons.monitor_heart_outlined,
                  title: 'HRV (RMSSD)'),
              const SizedBox(height: 10),
              _HrvLineChart(
                spots: hrvSpots,
                statRange: session.stats.sugar,
                totalSeconds: totalSec,
                anchor: anchor,
              ),
            ],
          );
        }),

      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
        ],
      );
}

// ── Heart Rate Hero Card (chart + stats) ─────────────────────────────────────

class _HeartRateHeroCard extends StatefulWidget {
  final CoachTaskResultSession session;
  const _HeartRateHeroCard({required this.session});

  @override
  State<_HeartRateHeroCard> createState() => _HeartRateHeroCardState();
}

class _HeartRateHeroCardState extends State<_HeartRateHeroCard> {
  static const _zoomLevels = [0.3, 0.5, 1.0, 2.0, 4.0];
  static const _zoomLabels = ['1x', '2x', '3x', '5x', '10x'];
  int _zoomIndex = 1;

  double get _pxPerSecond => _zoomLevels[_zoomIndex];

  @override
  Widget build(BuildContext context) {
    final stats = widget.session.stats.heartRate;
    final sorted = [...widget.session.rawData]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final anchor = widget.session.startedAt;
    // ~15s buckets me average → smooth curve (dense per-second data warna spiky
    // dikhti hai). maxBpm/minBpm aur stats raw se aate hain, numbers pe asar nahi.
    final anchorMs = anchor.millisecondsSinceEpoch;
    final spots = <FlSpot>[];
    if (sorted.length < 4) {
      for (final p in sorted) {
        spots.add(FlSpot(
            p.recordedAt.difference(anchor).inSeconds.toDouble(),
            p.heartRate.toDouble()));
      }
    } else {
      const bucketMs = 15000;
      int bucketStart = sorted.first.recordedAt.millisecondsSinceEpoch;
      int firstMs = bucketStart;
      int lastMs = bucketStart;
      double sum = 0;
      int n = 0;
      for (final p in sorted) {
        final ms = p.recordedAt.millisecondsSinceEpoch;
        if (ms - bucketStart >= bucketMs && n > 0) {
          final midMs = (firstMs + lastMs) ~/ 2;
          spots.add(FlSpot((midMs - anchorMs) / 1000.0, sum / n));
          bucketStart = ms;
          firstMs = ms;
          sum = 0;
          n = 0;
        }
        sum += p.heartRate;
        lastMs = ms;
        n++;
      }
      if (n > 0) {
        final midMs = (firstMs + lastMs) ~/ 2;
        spots.add(FlSpot((midMs - anchorMs) / 1000.0, sum / n));
      }
    }

    final bpms = sorted.map((p) => p.heartRate).toList();
    final maxBpm = bpms.reduce(math.max);
    final minBpm = bpms.reduce(math.min);
    final yFloor = ((minBpm - 20).clamp(0, 999) / 20).floor() * 20.0;
    final yCeil = ((maxBpm + 20) / 20).ceil() * 20.0;
    const double yInterval = 20;
    final sessionSpan = widget.session.duration.inSeconds.toDouble();
    final lastX = spots.isNotEmpty ? spots.last.x : 0.0;
    final double maxX =
        (sessionSpan > 0 ? sessionSpan : lastX).clamp(1.0, double.infinity);

    final avgBpm = stats.avg;

    Color zoneColor(double bpm) {
      if (bpm < 60) return AppColors.primary;
      if (bpm < 100) return AppColors.success;
      if (bpm < 140) return AppColors.warning;
      return AppColors.error;
    }

    String zoneLabel(double bpm) {
      if (bpm < 60) return 'Resting';
      if (bpm < 100) return 'Normal';
      if (bpm < 140) return 'Moderate';
      return 'High Intensity';
    }

    final color = zoneColor(avgBpm);

    final screenWidth = MediaQuery.of(context).size.width - 72;
    const minChartWidth = 350.0;
    final calculatedWidth =
        (maxX * _pxPerSecond).clamp(minChartWidth, double.infinity);
    final chartWidth = math.max(calculatedWidth, screenWidth);

    final visibleSeconds =
        chartWidth > 0 ? maxX / (chartWidth / screenWidth) : maxX;
    final double labelInterval;
    if (visibleSeconds <= 120) {
      labelInterval = 15;
    } else if (visibleSeconds <= 300) {
      labelInterval = 30;
    } else if (visibleSeconds <= 600) {
      labelInterval = 60;
    } else if (visibleSeconds <= 1800) {
      labelInterval = 120;
    } else if (visibleSeconds <= 3600) {
      labelInterval = 300;
    } else {
      labelInterval = 600;
    }

    final canZoomIn = _zoomIndex < _zoomLevels.length - 1;
    final canZoomOut = _zoomIndex > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: color),
                      const SizedBox(width: 5),
                      Text(zoneLabel(avgBpm),
                          style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.favorite_rounded, color: color, size: 16),
                const SizedBox(width: 4),
                Text('Heart Rate',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stats.avg.toStringAsFixed(0),
                  style: TextStyle(
                    color: color,
                    fontSize: 68,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('BPM avg',
                      style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                const Spacer(),
                _ZoomButton(
                    icon: Icons.remove,
                    onTap: canZoomOut
                        ? () => setState(() => _zoomIndex--)
                        : null),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _zoomIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_zoomLabels[_zoomIndex],
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                _ZoomButton(
                    icon: Icons.add,
                    onTap: canZoomIn
                        ? () => setState(() => _zoomIndex++)
                        : null),
              ],
            ),
          ),
          const SizedBox(height: 6),

          SizedBox(
            height: 200,
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: LineChart(
                    LineChartData(
                      minY: yFloor,
                      maxY: yCeil,
                      minX: 0,
                      maxX: 1,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: yInterval,
                            getTitlesWidget: (v, _) => Text(
                                v.toStringAsFixed(0),
                                style: const TextStyle(
                                    color: AppColors.subtext,
                                    fontSize: 10)),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (_, __) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      lineTouchData: const LineTouchData(enabled: false),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: chartWidth,
                        child: LineChart(
                          LineChartData(
                            minY: yFloor,
                            maxY: yCeil,
                            minX: 0,
                            maxX: maxX,
                            clipData: const FlClipData.none(),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              // Sub-lines: minor har 5, major (har 20) darker.
                              horizontalInterval: 5,
                              verticalInterval: labelInterval,
                              getDrawingHorizontalLine: (value) {
                                final isMajor =
                                    (value - yFloor).round() % 20 == 0;
                                return isMajor
                                    ? const FlLine(
                                        color: AppColors.border,
                                        strokeWidth: 1.2)
                                    : FlLine(
                                        color: AppColors.borderLight
                                            .withValues(alpha: 0.45),
                                        strokeWidth: 0.5);
                              },
                              getDrawingVerticalLine: (_) => FlLine(
                                  color: AppColors.borderLight
                                      .withValues(alpha: 0.5),
                                  strokeWidth: 0.5),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 26,
                                  interval: labelInterval,
                                  getTitlesWidget: (v, _) {
                                    if (v < 0 || v > maxX) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(top: 6),
                                      child: Text(
                                          _fmtClock(anchor, v.toInt()),
                                          style: const TextStyle(
                                              color: AppColors.subtext,
                                              fontSize: 9)),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => AppColors.text,
                                getTooltipItems: (spots) => spots
                                    .map((s) => LineTooltipItem(
                                          '${s.y.toInt()} bpm  •  ${_fmtClockSec(anchor, s.x.toInt())}',
                                          const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.w600),
                                        ))
                                    .toList(),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                curveSmoothness: 0.4,
                                preventCurveOverShooting: true,
                                color: color,
                                barWidth: 2.5,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      color.withValues(alpha: 0.2),
                                      color.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          const Divider(height: 1, color: AppColors.border),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Row(
              children: [
                _BpmStat(
                  label: 'Min',
                  value: stats.min.toStringAsFixed(0),
                  color: AppColors.primary,
                ),
                _Divider(),
                _BpmStat(
                  label: 'Avg',
                  value: stats.avg.toStringAsFixed(0),
                  color: AppColors.success,
                ),
                _Divider(),
                _BpmStat(
                  label: 'Max',
                  value: stats.max.toStringAsFixed(0),
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BpmStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BpmStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 10)),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.border);
}

// ── Fallback when no raw_data ─────────────────────────────────────────────────

class _HeartRateSummaryCard extends StatelessWidget {
  final StatRange stats;
  const _HeartRateSummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
                label: 'Min BPM',
                value: stats.min.toStringAsFixed(0),
                color: AppColors.primary),
            _StatItem(
                label: 'Avg BPM',
                value: stats.avg.toStringAsFixed(0),
                color: AppColors.success),
            _StatItem(
                label: 'Max BPM',
                value: stats.max.toStringAsFixed(0),
                color: AppColors.error),
          ],
        ),
      );
}

// ── Session Info Card ─────────────────────────────────────────────────────────

class _SessionInfoCard extends StatelessWidget {
  final CoachTaskResultSession session;
  const _SessionInfoCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dur = session.duration;
    final durStr =
        '${dur.inMinutes}m ${dur.inSeconds.remainder(60)}s';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoItem(
              icon: Icons.play_circle_outline,
              label: 'Started',
              value: _fmt(session.startedAt),
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: _InfoItem(
              icon: Icons.stop_circle_outlined,
              label: 'Ended',
              value: _fmt(session.endedAt),
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: _InfoItem(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: durStr,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.subtext, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      );
}

// ── Stat Item ─────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.subtext, fontSize: 11)),
        ],
      );
}

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded,
                color: AppColors.subtext, size: 52),
            SizedBox(height: 16),
            Text('No result found',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('This task has no recorded session',
                style:
                    TextStyle(color: AppColors.subtext, fontSize: 13)),
          ],
        ),
      );
}

// ── HR Zones Card ────────────────────────────────────────────────────────────

class _HrZonesCard extends StatelessWidget {
  final List<FlSpot> spots;
  const _HrZonesCard({required this.spots});

  // Zones based on absolute HR thresholds (age agnostic)
  // Z1 Resting (<100), Z2 Fat Burn (100-120), Z3 Cardio (120-140),
  // Z4 Peak (140-160), Z5 Max (>=160)
  static const _zones = [
    (label: 'Resting', color: Color(0xFF66BB6A), min: 0, max: 100),
    (label: 'Fat Burn', color: Color(0xFF9CCC65), min: 100, max: 120),
    (label: 'Cardio', color: Color(0xFFFFA726), min: 120, max: 140),
    (label: 'Peak', color: Color(0xFFFB8C00), min: 140, max: 160),
    (label: 'Max', color: Color(0xFFEF5350), min: 160, max: 999),
  ];

  @override
  Widget build(BuildContext context) {
    final counts = List<int>.filled(_zones.length, 0);
    for (final s in spots) {
      for (var i = 0; i < _zones.length; i++) {
        if (s.y >= _zones[i].min && s.y < _zones[i].max) {
          counts[i]++;
          break;
        }
      }
    }
    final total = counts.fold<int>(0, (a, b) => a + b);
    final dominant = total == 0
        ? 0
        : counts.indexOf(counts.reduce((a, b) => a > b ? a : b));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                  color: _zones[dominant].color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.bar_chart,
                  color: _zones[dominant].color, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Heart Rate Zones',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            if (total > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _zones[dominant].color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mostly ${_zones[dominant].label}',
                  style: TextStyle(
                      color: _zones[dominant].color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ]),

          const SizedBox(height: 16),

          // Stacked bar
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: List.generate(_zones.length, (i) {
                  if (counts[i] == 0) return const SizedBox.shrink();
                  return Expanded(
                    flex: counts[i],
                    child: Container(height: 14, color: _zones[i].color),
                  );
                }),
              ),
            )
          else
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

          const SizedBox(height: 16),

          // Legend rows
          for (var i = 0; i < _zones.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ZoneRow(
                color: _zones[i].color,
                label: _zones[i].label,
                range: i == _zones.length - 1
                    ? '${_zones[i].min}+'
                    : '${_zones[i].min}–${_zones[i].max - 1}',
                seconds: counts[i],
                pct: total == 0 ? 0 : counts[i] / total,
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final Color color;
  final String label, range;
  final int seconds;
  final double pct;
  const _ZoneRow({
    required this.color,
    required this.label,
    required this.range,
    required this.seconds,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 70,
        child: Text(label,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
      SizedBox(
        width: 64,
        child: Text('$range bpm',
            style: const TextStyle(color: AppColors.subtext, fontSize: 11)),
      ),
      const Spacer(),
      Text(_fmtElapsed(seconds),
          style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700)),
      const SizedBox(width: 10),
      SizedBox(
        width: 38,
        child: Text('${(pct * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}

// ── HRV Line Chart (ECG style) ────────────────────────────────────────────────

const _kHrvColor = Color(0xFF40C4FF);

class _HrvLineChart extends StatefulWidget {
  final List<FlSpot> spots;
  final StatRange statRange;
  final double totalSeconds;
  final DateTime anchor;

  const _HrvLineChart({
    required this.spots,
    required this.statRange,
    required this.totalSeconds,
    required this.anchor,
  });

  @override
  State<_HrvLineChart> createState() => _HrvLineChartState();
}

class _HrvLineChartState extends State<_HrvLineChart> {
  static const _zoomLevels = [0.3, 0.5, 1.0, 2.0, 4.0];
  static const _zoomLabels = ['1x', '2x', '3x', '5x', '10x'];
  int _zoomIndex = 1;

  double get _pxPerSecond => _zoomLevels[_zoomIndex];

  @override
  Widget build(BuildContext context) {
    final spots = widget.spots;
    final ys = spots.map((s) => s.y);
    final maxVal = ys.reduce(math.max);
    final minVal = ys.reduce(math.min);
    final range = maxVal - minVal;
    final padding = range < 5 ? 5.0 : range * 0.2;
    final yFloor = ((minVal - padding).clamp(0.0, double.infinity) / 10)
            .floor() *
        10.0;
    final yCeil = ((maxVal + padding) / 10).ceil() * 10.0;
    const double yInterval = 10;
    final double maxX = widget.totalSeconds > 0
        ? widget.totalSeconds
        : (spots.isNotEmpty ? spots.last.x : 1.0);

    final screenWidth = MediaQuery.of(context).size.width - 72;
    const minChartWidth = 350.0;
    final calculatedWidth =
        (maxX * _pxPerSecond).clamp(minChartWidth, double.infinity);
    final chartWidth = math.max(calculatedWidth, screenWidth);

    final visibleSeconds =
        chartWidth > 0 ? maxX / (chartWidth / screenWidth) : maxX;
    final double labelInterval;
    if (visibleSeconds <= 120) {
      labelInterval = 15;
    } else if (visibleSeconds <= 300) {
      labelInterval = 30;
    } else if (visibleSeconds <= 600) {
      labelInterval = 60;
    } else if (visibleSeconds <= 1800) {
      labelInterval = 120;
    } else if (visibleSeconds <= 3600) {
      labelInterval = 300;
    } else {
      labelInterval = 600;
    }

    final canZoomIn = _zoomIndex < _zoomLevels.length - 1;
    final canZoomOut = _zoomIndex > 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kHrvColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: _kHrvColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Text(
                  '${widget.statRange.avg.toStringAsFixed(1)} ms',
                  style: const TextStyle(
                      color: _kHrvColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 6),
                const Text('avg RMSSD',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                Text(
                  'min ${widget.statRange.min.toStringAsFixed(1)}  max ${widget.statRange.max.toStringAsFixed(1)}',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.swipe_outlined,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text('Swipe to scroll',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                _ZoomButton(
                    icon: Icons.remove,
                    dark: true,
                    onTap: canZoomOut
                        ? () => setState(() => _zoomIndex--)
                        : null),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _zoomIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kHrvColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_zoomLabels[_zoomIndex],
                          style: const TextStyle(
                              color: _kHrvColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                _ZoomButton(
                    icon: Icons.add,
                    dark: true,
                    onTap: canZoomIn
                        ? () => setState(() => _zoomIndex++)
                        : null),
              ],
            ),
          ),
          const SizedBox(height: 6),

          SizedBox(
            height: 160,
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: LineChart(
                    LineChartData(
                      minY: yFloor,
                      maxY: yCeil,
                      minX: 0,
                      maxX: 1,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: yInterval,
                            getTitlesWidget: (v, _) => Text(
                                v.toStringAsFixed(0),
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10)),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (_, __) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      lineTouchData: const LineTouchData(enabled: false),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: chartWidth,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: maxX,
                            minY: yFloor,
                            maxY: yCeil,
                            clipData: const FlClipData.none(),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: yInterval,
                              verticalInterval: labelInterval,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color:
                                    Colors.white.withValues(alpha: 0.05),
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (_) => FlLine(
                                color:
                                    Colors.white.withValues(alpha: 0.03),
                                strokeWidth: 0.5,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 26,
                                  interval: labelInterval,
                                  getTitlesWidget: (v, _) {
                                    if (v < 0 || v > maxX) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 6),
                                      child: Text(
                                        _fmtClock(widget.anchor,
                                            v.toInt()),
                                        style: TextStyle(
                                            color: Colors.white
                                                .withValues(
                                                    alpha: 0.45),
                                            fontSize: 9),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) =>
                                    const Color(0xFF1A2940),
                                getTooltipItems: (touched) =>
                                    touched.map((s) {
                                  return LineTooltipItem(
                                    '${s.y.toStringAsFixed(1)} ms  •  ${_fmtClockSec(widget.anchor, s.x.toInt())}',
                                    const TextStyle(
                                        color: _kHrvColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  );
                                }).toList(),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: false,
                                color: _kHrvColor,
                                barWidth: 1.8,
                                dotData:
                                    const FlDotData(show: false),
                                belowBarData:
                                    BarAreaData(show: false),
                                shadow: Shadow(
                                    color: _kHrvColor.withValues(
                                        alpha: 0.4),
                                    blurRadius: 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Zoom Button ─────────────────────────────────────────────────────────────

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool dark;
  const _ZoomButton({required this.icon, this.onTap, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final bgEnabled = dark
        ? _kHrvColor.withValues(alpha: 0.12)
        : AppColors.primary.withValues(alpha: 0.1);
    final bgDisabled = dark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.surfaceAlt;
    final borderEnabled = dark
        ? _kHrvColor.withValues(alpha: 0.25)
        : AppColors.primary.withValues(alpha: 0.3);
    final borderDisabled =
        dark ? Colors.white.withValues(alpha: 0.1) : AppColors.borderLight;
    final iconEnabled = dark ? _kHrvColor : AppColors.primary;
    final iconDisabled =
        dark ? Colors.white.withValues(alpha: 0.3) : AppColors.subtext;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? bgEnabled : bgDisabled,
          borderRadius: BorderRadius.circular(7),
          border:
              Border.all(color: enabled ? borderEnabled : borderDisabled),
        ),
        child: Icon(icon,
            size: 14, color: enabled ? iconEnabled : iconDisabled),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    color: AppColors.error, size: 40),
              ),
              const SizedBox(height: 20),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
}
