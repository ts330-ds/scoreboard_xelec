import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/athlete_task_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_zip_submit_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/screen/session_upload_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history_sql/presentation/widgets/hr_scrollable_chart.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../cubit/task_result_cubit.dart';
import '../cubit/task_result_state.dart';

double _toD(dynamic v) =>
    v == null ? 0.0 : v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;

DateTime? _parseTs(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

// anchor + offsetSeconds → "HH:MM" (local)
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
                    message: state.errorMessage ?? 'Failed to load result',
                    onRetry: () => context.read<TaskResultCubit>().load(),
                  ),
                )
              else if (state.status == TaskResultStatus.loaded &&
                  state.result != null)
                _ResultBody(raw: state.result!.raw, task: task)
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
                  Builder(builder: (_) {
                    final isPending =
                        task.status?.toLowerCase() == 'pending';
                    final durMin = int.tryParse(task.duration) ?? 0;
                    final showDuration = !isPending && durMin > 0;
                    final showAssignedBy = task.assignedByName != null &&
                        task.assignedBy != 'self';
                    if (!showDuration && !showAssignedBy) {
                      return const SizedBox.shrink();
                    }
                    return Row(children: [
                      if (showDuration) ...[
                        const Icon(Icons.timer_outlined,
                            size: 13, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text('$durMin min',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                      ],
                      if (showAssignedBy) ...[
                        if (showDuration) const SizedBox(width: 12),
                        const Icon(Icons.person_outline,
                            size: 13, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text(task.assignedByName!,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                      ],
                    ]);
                  }),
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
  final AthleteTaskEntity task;
  const _ResultBody({required this.raw, required this.task});

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
      widgets.addAll(_buildSession(context, session));
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

  List<Widget> _buildSession(BuildContext context, Map<String, dynamic> session) {
    final stats =
        (session['aggregated_stats'] as Map<String, dynamic>?) ?? {};
    final rawList = (session['raw_data'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    final hrStats = (stats['heart_rate'] as Map<String, dynamic>?) ?? {};
    final sugarStats = (stats['sugar'] as Map<String, dynamic>?) ?? {};

    final startedAt = session['started_at'] as String?;
    final endedAt = session['ended_at'] as String?;
    Duration? duration;
    final DateTime? sessionStart =
        startedAt != null ? DateTime.tryParse(startedAt) : null;
    final DateTime? sessionEnd =
        endedAt != null ? DateTime.tryParse(endedAt) : null;
    if (sessionStart != null && sessionEnd != null) {
      duration = sessionEnd.difference(sessionStart);
    }

    if (rawList.isEmpty) {
      return [
        _SessionInfoCard(
            startedAt: startedAt, endedAt: endedAt, duration: duration),
        const SizedBox(height: 14),
        _UploadSessionButton(
          taskId: task.id,
          taskName: task.name,
          sessionStart: sessionStart,
          sessionEnd: sessionEnd,
        ),
      ];
    }

    // X-axis anchor = session.started_at (preferred) — labels real clock time
    // show karenge. Agar sessionStart na ho to first raw_data timestamp pe fallback.
    DateTime? tsOf(Map<String, dynamic> r) =>
        _parseTs(r['recorded_at'] ?? r['timestamp']);

    // Sort raw_data oldest-first by timestamp
    final sortedRaw = [...rawList]..sort((a, b) {
        final ta = tsOf(a);
        final tb = tsOf(b);
        if (ta == null || tb == null) return 0;
        return ta.compareTo(tb);
      });
    final DateTime? firstTs =
        sortedRaw.isNotEmpty ? tsOf(sortedRaw.first) : null;
    final DateTime? lastTs =
        sortedRaw.isNotEmpty ? tsOf(sortedRaw.last) : null;
    final DateTime? anchor = sessionStart ?? firstTs;

    double elapsedFor(Map<String, dynamic> r, int fallbackIdx) {
      if (anchor == null) return fallbackIdx.toDouble();
      final t = tsOf(r);
      if (t == null) return fallbackIdx.toDouble();
      return t.difference(anchor).inSeconds.toDouble();
    }

    // Build chart spots — x = elapsed seconds from FIRST raw_data timestamp.
    // (HR Zones card ke liye — wo elapsed-based spots use karta hai.)
    final hrSpots = <FlSpot>[];
    for (var i = 0; i < sortedRaw.length; i++) {
      final hr = _toD(sortedRaw[i]['heart_rate']);
      if (hr <= 0) continue;
      hrSpots.add(FlSpot(elapsedFor(sortedRaw[i], i), hr));
    }

    // HR readings in the History-chart format (stamp ms + heartRate). Ye
    // HrScrollableChart ko feed hota hai taaki activity result ka chart bilkul
    // History tab jaisa dikhe (real clock time x-axis, gap segments).
    final hrReadings = <Map<dynamic, dynamic>>[];
    for (final r in sortedRaw) {
      final hr = _toD(r['heart_rate']);
      final t = tsOf(r);
      if (hr <= 0 || t == null) continue;
      hrReadings.add({'stamp': t.millisecondsSinceEpoch, 'heartRate': hr});
    }

    final hrvSpots = <FlSpot>[];
    for (var i = 0; i < sortedRaw.length; i++) {
      final v = _toD(sortedRaw[i]['sugar_level']);
      if (v <= 0) continue;
      hrvSpots.add(FlSpot(elapsedFor(sortedRaw[i], i), v));
    }

    // X-axis ka maxX = session duration (preferred), warna first→last raw span
    final double dataSpan = (firstTs != null && lastTs != null)
        ? lastTs.difference(firstTs).inSeconds.toDouble()
        : (hrSpots.isNotEmpty ? hrSpots.last.x : 0);
    final double sessionSpanSec =
        duration != null ? duration.inSeconds.toDouble() : 0;
    final double totalSeconds =
        sessionSpanSec > 0 ? sessionSpanSec : dataSpan;

    return [
      // Session info
      _SessionInfoCard(
          startedAt: startedAt, endedAt: endedAt, duration: duration),
      const SizedBox(height: 14),

      // Heart rate chart — same design as History tab (blue background)
      if (hrReadings.isNotEmpty) ...[
        _HeartRateHeroCard(
          hrReadings: hrReadings,
          avg: _toD(hrStats['avg']),
          min: _toD(hrStats['min']),
          max: _toD(hrStats['max']),
        ),
        const SizedBox(height: 14),
      ],

      // NEW: Heart Rate Zones distribution
      if (hrSpots.isNotEmpty) ...[
        _HrZonesCard(spots: hrSpots),
        const SizedBox(height: 14),
      ],

      // HRV chart (kept)
      if (hrvSpots.length >= 2) ...[
        _HrvLineChart(
          spots: hrvSpots,
          avg: _toD(sugarStats['avg']),
          min: _toD(sugarStats['min']),
          max: _toD(sugarStats['max']),
          totalSeconds: totalSeconds,
          anchor: anchor,
        ),
      ],

      // Reupload — agar athlete data se satisfied na ho ya incomplete aaya ho
      // to device se session dobara flush kar sakta hai (sirf 3 din ke andar).
      const SizedBox(height: 14),
      _ReuploadSessionButton(
        taskId: task.id,
        taskName: task.name,
        sessionStart: sessionStart,
        sessionEnd: sessionEnd,
      ),
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
  final List<Map<dynamic, dynamic>> hrReadings;
  final double avg, min, max;

  const _HeartRateHeroCard({
    required this.hrReadings,
    required this.avg,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat tiles — same layout as History tab (AVG / MAX / MIN)
        Row(
          children: [
            _HrStatTile(
              label: 'AVG',
              value: avg.toStringAsFixed(0),
              color: AppColors.primary,
              icon: Icons.favorite,
            ),
            const SizedBox(width: 10),
            _HrStatTile(
              label: 'MAX',
              value: max.toStringAsFixed(0),
              color: AppColors.heartRed,
              icon: Icons.arrow_upward_rounded,
            ),
            const SizedBox(width: 10),
            _HrStatTile(
              label: 'MIN',
              value: min.toStringAsFixed(0),
              color: AppColors.vitalStress,
              icon: Icons.arrow_downward_rounded,
            ),
          ].map((w) => Expanded(child: w)).toList(),
        ),
        const SizedBox(height: 16),
        // Chart — reuses the History tab widget, light-blue background
        HrScrollableChart(
          readings: hrReadings,
          backgroundColor: AppColors.surface,
          emphasizeYGrid: true,
        ),
      ],
    );
  }
}

// Stat tile — mirrors the History tab's per-day AVG/MAX/MIN tiles.
class _HrStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _HrStatTile({
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

// SpO2 aur Stress charts hata diye gaye — requirements ke according.

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _HrvLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final double avg, min, max;
  final double totalSeconds;
  final DateTime? anchor;

  const _HrvLineChart({
    required this.spots,
    required this.avg,
    required this.min,
    required this.max,
    required this.totalSeconds,
    required this.anchor,
  });

  @override
  Widget build(BuildContext context) {
    final hrvDataMax = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final hrvDataMin = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    const double hrvYInterval = 10;
    final hrvYFloor = (((hrvDataMin - 5) / hrvYInterval).floor() * 10.0).clamp(0.0, double.infinity);
    final hrvYCeil = ((hrvDataMax + 5) / hrvYInterval).ceil() * 10.0;
    final double hrvMaxX = totalSeconds > 0
        ? totalSeconds
        : (spots.last.x > 0 ? spots.last.x : 1.0);

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

          const SizedBox(height: 12),

          Row(children: [
            Icon(Icons.swipe_outlined,
                size: 12,
                color: _kHrvColor.withValues(alpha: 0.4)),
            const SizedBox(width: 4),
            Text('Swipe to scroll',
                style: TextStyle(
                    color: _kHrvColor.withValues(alpha: 0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),

          // Chart with fixed y-axis + scrollable area
          Builder(builder: (context) {
            final screenWidth =
                MediaQuery.of(context).size.width - 92;
            const pxPerMinute = 100.0;
            final calculatedWidth = (hrvMaxX / 60) * pxPerMinute;
            final chartWidth =
                math.max(calculatedWidth, screenWidth);

            final double labelInterval;
            if (hrvMaxX <= 300) {
              labelInterval = 30;
            } else if (hrvMaxX <= 1800) {
              labelInterval = 60;
            } else {
              labelInterval = 300;
            }

            return SizedBox(
              height: 130,
              child: Row(
                children: [
                  // Fixed y-axis
                  SizedBox(
                    width: 36,
                    child: LineChart(
                      LineChartData(
                        minY: hrvYFloor,
                        maxY: hrvYCeil,
                        minX: 0,
                        maxX: 1,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: hrvYInterval,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.4),
                                    fontSize: 9),
                              ),
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (_, __) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        lineTouchData:
                            const LineTouchData(enabled: false),
                      ),
                    ),
                  ),
                  // Scrollable chart
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: SizedBox(
                          width: chartWidth,
                          child: LineChart(
                            LineChartData(
                              minX: -0.3,
                              maxX: hrvMaxX + 0.3,
                              minY: hrvYFloor,
                              maxY: hrvYCeil,
                              clipData: const FlClipData.none(),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval: hrvYInterval,
                                verticalInterval: labelInterval,
                                getDrawingHorizontalLine: (_) =>
                                    FlLine(
                                        color: Colors.white
                                            .withValues(alpha: 0.05),
                                        strokeWidth: 1),
                                getDrawingVerticalLine: (_) =>
                                    FlLine(
                                        color: Colors.white
                                            .withValues(alpha: 0.04),
                                        strokeWidth: 0.5),
                              ),
                              borderData:
                                  FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    interval: labelInterval,
                                    getTitlesWidget: (v, _) {
                                      if (v < 0 || v > hrvMaxX) {
                                        return const SizedBox
                                            .shrink();
                                      }
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(
                                                top: 4),
                                        child: Text(
                                          anchor != null
                                              ? _fmtClock(
                                                  anchor!,
                                                  v.toInt())
                                              : _fmtElapsed(
                                                  v.toInt()),
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(
                                                    alpha: 0.45),
                                            fontSize: 9,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: false,
                                  color: _kHrvColor,
                                  barWidth: 1.8,
                                  dotData: const FlDotData(
                                      show: false),
                                  belowBarData:
                                      BarAreaData(show: false),
                                  shadow: Shadow(
                                      color: _kHrvColor.withValues(
                                          alpha: 0.4),
                                      blurRadius: 6),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                touchTooltipData:
                                    LineTouchTooltipData(
                                  getTooltipColor: (_) =>
                                      const Color(0xFF0A1628),
                                  getTooltipItems: (touched) =>
                                      touched
                                          .map((s) =>
                                              LineTooltipItem(
                                                '${s.y.toStringAsFixed(1)} ms  •  ${anchor != null ? _fmtClockSec(anchor!, s.x.toInt()) : _fmtElapsed(s.x.toInt())}',
                                                const TextStyle(
                                                    color:
                                                        _kHrvColor,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600),
                                              ))
                                          .toList(),
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
            );
          }),

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

// ── Upload Session Button (raw_data missing) ────────────────────────────────

class _UploadSessionButton extends StatelessWidget {
  final int taskId;
  final String taskName;
  final DateTime? sessionStart;
  final DateTime? sessionEnd;

  const _UploadSessionButton({
    required this.taskId,
    required this.taskName,
    required this.sessionStart,
    required this.sessionEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined,
                color: AppColors.warning, size: 32),
          ),
          const SizedBox(height: 12),
          const Text(
            'Data not uploaded',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Session data was not synced to the server.\nTap below to upload from your device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.subtext, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: sessionStart != null && sessionEnd != null
                  ? () => _startUpload(context)
                  : null,
              icon: const Icon(Icons.upload, size: 18),
              label: const Text('Upload Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.borderLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startUpload(BuildContext context) {
    final submitCubit = sl<TaskZipSubmitCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionUploadScreen(
          submitCubit: submitCubit,
          taskId: taskId,
          taskName: taskName,
          sessionStart: sessionStart!,
          sessionEnd: sessionEnd!,
        ),
      ),
    ).then((_) {
      if (!submitCubit.isClosed) {
        submitCubit.close();
      }
      if (context.mounted) {
        context.read<TaskResultCubit>().load();
      }
    });
  }
}

// ── Reupload Session Button (completed task — re-flush from device) ──────────
// Athlete agar result se satisfied na ho ya incomplete data aaya ho to device
// se session dobara flush/upload kar sakta hai. Rule: sirf session ke 3 din ke
// andar (band history limited + relevance window). 90% completeness gate
// SessionUploadScreen → TaskZipSubmitCubit me already lagta hai, isliye adhoora
// data yahan se bhi server pe nahi jaata.
class _ReuploadSessionButton extends StatelessWidget {
  final int taskId;
  final String taskName;
  final DateTime? sessionStart;
  final DateTime? sessionEnd;

  static const _reuploadWindow = Duration(days: 3);

  const _ReuploadSessionButton({
    required this.taskId,
    required this.taskName,
    required this.sessionStart,
    required this.sessionEnd,
  });

  @override
  Widget build(BuildContext context) {
    // Bina session timestamps ke re-flush possible nahi (fetch range chahiye).
    if (sessionStart == null || sessionEnd == null) {
      return const SizedBox.shrink();
    }

    final withinWindow =
        DateTime.now().difference(sessionStart!) <= _reuploadWindow;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Not satisfied with this data?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'If the readings look incomplete, you can flush the session '
            'again from your device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.subtext, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: withinWindow ? () => _startReupload(context) : null,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reupload Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: withinWindow
                        ? AppColors.primary
                        : AppColors.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (!withinWindow) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'You can reupload data only within 3 days of session',
                    style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _startReupload(BuildContext context) {
    final submitCubit = sl<TaskZipSubmitCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionUploadScreen(
          submitCubit: submitCubit,
          taskId: taskId,
          taskName: taskName,
          sessionStart: sessionStart!,
          sessionEnd: sessionEnd!,
        ),
      ),
    ).then((_) {
      if (!submitCubit.isClosed) {
        submitCubit.close();
      }
      if (context.mounted) {
        context.read<TaskResultCubit>().load();
      }
    });
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
            Text('No result found',
                style: TextStyle(color: AppColors.subtext, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
