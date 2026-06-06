import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import '../../domain/entity/my_athlete_entity.dart';
import '../cubit/athlete_detail_cubit.dart';
import '../cubit/athlete_detail_state.dart';
import '../cubit/athlete_health_metrics_cubit.dart';
import '../cubit/athlete_health_metrics_state.dart';
import '../cubit/athlete_hour_raw_cubit.dart';
import '../cubit/athlete_hour_raw_state.dart';
import '../cubit/completed_tasks_cubit.dart';
import '../cubit/completed_tasks_state.dart';
import '../../domain/entity/completed_task_entity.dart';
import '../../../live_now/presentation/screen/coach_task_result_screen.dart';

const _hrColor = Color(0xFFEF5350);
const _sleepColor = Color(0xFF7B1FA2);
const _rrColor = Color(0xFF26A69A);

class AthleteDetailMobile extends StatelessWidget {
  final MyAthleteEntity preview;
  const AthleteDetailMobile({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteDetailCubit, AthleteDetailState>(
      builder: (context, detailState) {
        final athlete = detailState.athlete ?? preview;
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: AppColors.bg,
            body: Column(
              children: [
                _HeroHeader(athlete: athlete),
                Material(
                  color: AppColors.surface,
                  child: TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.subtext,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2.5,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(
                        height: 44,
                        icon: null,
                        iconMargin: EdgeInsets.zero,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt, size: 16),
                            SizedBox(width: 6),
                            Text('Completed Tasks'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.monitor_heart_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('Health Metrics'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                Expanded(
                  child: TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _CompletedTasksTab(
                        athleteId: athlete.id,
                        athleteFallbackName: athlete.name,
                      ),
                      _HealthMetricsTab(
                        athlete: athlete,
                        detailLoading: detailState.status ==
                            AthleteDetailStatus.loading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Health Metrics Tab (existing content moved here) ─────────────────────────

class _HealthMetricsTab extends StatelessWidget {
  final MyAthleteEntity athlete;
  final bool detailLoading;
  const _HealthMetricsTab(
      {required this.athlete, required this.detailLoading});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        if (detailLoading) const _LoadingBanner(),
        _DateRangePill(athleteId: athlete.id),
        const SizedBox(height: 16),
        _HealthSection(athleteId: athlete.id),
        const SizedBox(height: 24),
        const _SectionHeader(
            icon: Icons.person_outline, title: 'Personal Info'),
        const SizedBox(height: 12),
        _InfoCard(items: [
          _InfoRow('Gender', athlete.gender),
          _InfoRow('Date of Birth', athlete.dob),
          _InfoRow('Phone', athlete.phone),
          _InfoRow('Status', athlete.status),
          _InfoRow('Member Since', athlete.createdAt),
        ]),
      ],
    );
  }
}

// ── Completed Tasks Tab ──────────────────────────────────────────────────────

class _CompletedTasksTab extends StatelessWidget {
  final int athleteId;
  final String athleteFallbackName;
  const _CompletedTasksTab(
      {required this.athleteId, required this.athleteFallbackName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompletedTasksCubit, CompletedTasksState>(
      builder: (context, state) {
        switch (state.status) {
          case CompletedTasksStatus.initial:
          case CompletedTasksStatus.loading:
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          case CompletedTasksStatus.error:
            return Padding(
              padding: const EdgeInsets.all(20),
              child: _ErrorView(
                message: state.errorMessage ?? 'Failed to load tasks',
                onRetry: () =>
                    context.read<CompletedTasksCubit>().fetch(athleteId),
              ),
            );
          case CompletedTasksStatus.loaded:
            if (state.tasks.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: _EmptyHint(
                    icon: Icons.task_alt,
                    text: 'No completed tasks yet'),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  context.read<CompletedTasksCubit>().fetch(athleteId),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: state.tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _CompletedTaskCard(
                  task: state.tasks[i],
                  athleteFallbackName: athleteFallbackName,
                ),
              ),
            );
        }
      },
    );
  }
}

class _CompletedTaskCard extends StatelessWidget {
  final CompletedTaskEntity task;
  final String athleteFallbackName;
  const _CompletedTaskCard(
      {required this.task, required this.athleteFallbackName});

  void _openResult(BuildContext context) {
    final id = task.id;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoachTaskResultScreen(
          taskId: id,
          athleteName: task.athleteName ?? athleteFallbackName,
          taskName: task.name ?? 'Task #$id',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = task.name ?? 'Task #${task.id ?? '-'}';
    final duration = task.durationSeconds;
    final displayDate = task.displayDate;
    final fb = task.feedback;

    final byLabel = _assignedByLabel(task);
    final hasFeedback = fb != null;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: task.id == null ? null : () => _openResult(context),
        child: Ink(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle,
                          size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          if (displayDate != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _fmtRelative(displayDate),
                              style: const TextStyle(
                                  color: AppColors.subtext,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (task.id != null)
                      Text('#${task.id}',
                          style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (duration != null)
                      _TaskChip(
                          icon: Icons.timer_outlined,
                          text: _fmtSeconds(duration),
                          color: AppColors.primary),
                    if (byLabel != null)
                      _TaskChip(
                          icon: Icons.person_outline,
                          text: byLabel,
                          color: const Color(0xFF5C6BC0)),
                    if (!hasFeedback)
                      _TaskChip(
                          icon: Icons.hourglass_empty,
                          text: 'No feedback',
                          color: AppColors.subtext),
                  ],
                ),
              ],
            ),
          ),

          // ── Feedback block (if present)
          if (hasFeedback)
            _FeedbackBlock(
              feedback: fb,
              sessionSeconds: duration,
            ),
        ],
      ),
        ),
      ),
    );
  }

  String? _assignedByLabel(CompletedTaskEntity t) {
    final by = t.assignedBy?.toLowerCase();
    if (by == null) return null;
    if (by == 'self') return 'Self-assigned';
    final name = t.assignedByName;
    if (name != null) return 'by $name';
    return 'by ${t.assignedBy}';
  }
}

// ── Feedback Block ───────────────────────────────────────────────────────────

class _FeedbackBlock extends StatelessWidget {
  final CompletedTaskFeedback feedback;
  final int? sessionSeconds;
  const _FeedbackBlock({required this.feedback, this.sessionSeconds});

  @override
  Widget build(BuildContext context) {
    final rpe = feedback.rpe;
    final session = sessionSeconds;
    final note = feedback.note;
    final rpeColor = _rpeColor(rpe);
    final sessionMinutes = session != null ? (session / 60).round() : null;
    final load = (rpe != null && sessionMinutes != null) ? rpe * sessionMinutes : null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reviews_outlined,
                  size: 13, color: AppColors.subtext),
              const SizedBox(width: 5),
              const Text('Athlete Feedback',
                  style: TextStyle(
                      color: AppColors.subtext,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (rpe != null)
                Expanded(
                  flex: 0,
                  child: _RpeBadge(rpe: rpe, color: rpeColor),
                ),
              if (rpe != null) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (load != null)
                      _FbStat(
                        icon: Icons.fitness_center,
                        label: 'Load (RPE x Duration)',
                        value: '$load',
                      ),
                    if (load != null && session != null)
                      const SizedBox(height: 6),
                    if (session != null)
                      _FbStat(
                        icon: Icons.timelapse,
                        label: 'Session',
                        value: _fmtSeconds(session),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote,
                      size: 14, color: AppColors.subtext),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(note,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.35)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _rpeColor(int? rpe) {
    if (rpe == null) return AppColors.subtext;
    if (rpe <= 3) return const Color(0xFF66BB6A); // easy — green
    if (rpe <= 6) return const Color(0xFFFFA726); // moderate — amber
    if (rpe <= 8) return const Color(0xFFEF5350); // hard — red
    return const Color(0xFFB71C1C); // max — deep red
  }
}

class _RpeBadge extends StatelessWidget {
  final int rpe;
  final Color color;
  const _RpeBadge({required this.rpe, required this.color});

  String get _label {
    if (rpe <= 3) return 'Easy';
    if (rpe <= 6) return 'Moderate';
    if (rpe <= 8) return 'Hard';
    return 'Max';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Text('Rating',
              style: TextStyle(
                  color: AppColors.subtext,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text('$rpe',
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1)),
          const Text('/ 10',
              style: TextStyle(
                  color: AppColors.subtext,
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(_label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FbStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _FbStat(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.subtext),
        const SizedBox(width: 5),
        Text('$label:',
            style: const TextStyle(
                color: AppColors.subtext,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TaskChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _TaskChip(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

String _fmtSeconds(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  if (m == 0) return '${s}s';
  if (s == 0) return '${m}m';
  return '${m}m ${s}s';
}

String _fmtRelative(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return _fmtDate(dt.toIso8601String());
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final MyAthleteEntity athlete;
  const _HeroHeader({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final initials = athlete.name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(athlete.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(athlete.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    if (athlete.sportName != null)
                      _heroChip(Icons.sports, athlete.sportName!),
                    if (athlete.gender != null)
                      _heroChip(Icons.person, athlete.gender!),
                    if (athlete.status != null)
                      _heroChip(Icons.circle, athlete.status!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ── Date Range Pill ──────────────────────────────────────────────────────────

class _DateRangePill extends StatelessWidget {
  final int athleteId;
  const _DateRangePill({required this.athleteId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteHealthMetricsCubit, AthleteHealthMetricsState>(
      builder: (context, state) {
        final from = state.fromDate;
        final to = state.toDate;
        final label = (from == null || to == null)
            ? 'Select date range'
            : '${_d(from)}  →  ${_d(to)}';

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: () => _pickRange(context, state),
                icon: const Icon(Icons.tune, size: 14),
                label: const Text('Change'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _d(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickRange(
      BuildContext context, AthleteHealthMetricsState state) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: (state.fromDate != null && state.toDate != null)
          ? DateTimeRange(start: state.fromDate!, end: state.toDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      context.read<AthleteHealthMetricsCubit>().fetchMetrics(
            athleteId,
            fromDate: picked.start,
            toDate: picked.end,
          );
    }
  }
}

// ── Health Section ───────────────────────────────────────────────────────────

class _HealthSection extends StatelessWidget {
  final int athleteId;
  const _HealthSection({required this.athleteId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteHealthMetricsCubit, AthleteHealthMetricsState>(
      builder: (context, state) {
        switch (state.status) {
          case AthleteHealthMetricsStatus.initial:
            return _EmptyHint(
                icon: Icons.date_range_outlined,
                text: 'Pick a date range to view metrics');
          case AthleteHealthMetricsStatus.loading:
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child:
                  Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          case AthleteHealthMetricsStatus.error:
            return _ErrorView(
              message: state.errorMessage ?? 'Failed to load',
              onRetry: () {
                if (state.fromDate != null && state.toDate != null) {
                  context.read<AthleteHealthMetricsCubit>().fetchMetrics(
                        athleteId,
                        fromDate: state.fromDate!,
                        toDate: state.toDate!,
                      );
                }
              },
            );
          case AthleteHealthMetricsStatus.loaded:
            final days = ((state.metrics?.raw['data'] as List?) ?? [])
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            if (days.isEmpty) {
              return _EmptyHint(
                  icon: Icons.bar_chart_rounded,
                  text: 'No data found for this period');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OverviewStats(days: days),
                const SizedBox(height: 16),
                if (_hasHR(days)) ...[
                  _SectionHeader(
                      icon: Icons.favorite_rounded, title: 'Heart Rate Trend'),
                  const SizedBox(height: 10),
                  _HRTrendCard(days: days, athleteId: athleteId),
                  const SizedBox(height: 22),
                ],
                _SectionHeader(
                    icon: Icons.calendar_today_outlined,
                    title: 'Daily Breakdown'),
                const SizedBox(height: 10),
                for (var i = 0; i < days.length; i++)
                  _DailyCard(
                      day: days[i],
                      athleteId: athleteId,
                      initiallyExpanded: i == 0),
              ],
            );
        }
      },
    );
  }
}

// ── Overview Stats ───────────────────────────────────────────────────────────

class _OverviewStats extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  const _OverviewStats({required this.days});

  @override
  Widget build(BuildContext context) {
    final hrVals = <double>[];

    for (final d in days) {
      final health = d['health'];
      if (health is Map<String, dynamic>) {
        final stats = health['aggregated_stats'];
        if (stats is Map<String, dynamic>) {
          final hr = stats['heart_rate'];
          if (hr is Map) {
            final avg = (hr['avg'] as num?)?.toDouble();
            if (avg != null) hrVals.add(avg);
          }
        }
      }
    }

    final overallHR = hrVals.isEmpty
        ? null
        : hrVals.reduce((a, b) => a + b) / hrVals.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _OverviewTile(
            icon: Icons.calendar_today_outlined,
            label: 'Days',
            value: '${days.length}',
            color: AppColors.primary,
          ),
          _divider(),
          _OverviewTile(
            icon: Icons.favorite,
            label: 'Avg HR',
            value: overallHR == null
                ? '--'
                : overallHR.toStringAsFixed(0),
            suffix: overallHR == null ? null : 'bpm',
            color: _hrColor,
          ),
        
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: AppColors.borderLight,
      );
}

class _OverviewTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? suffix;
  final Color color;
  const _OverviewTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1),
                ),
                if (suffix != null)
                  TextSpan(
                    text: ' $suffix',
                    style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.subtext,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Heart Rate Trend Card ────────────────────────────────────────────────────

class _HRTrendCard extends StatelessWidget {
  final List<Map<String, dynamic>> days;
  final int athleteId;
  const _HRTrendCard({required this.days, required this.athleteId});

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<Map<String, dynamic>, _HRDay>>[];
    for (final d in days) {
      final stats = _statsOfDay(d);
      final hr = stats['heart_rate'];
      if (hr is Map<String, dynamic>) {
        final avg = (hr['avg'] as num?)?.toDouble();
        final min = (hr['min'] as num?)?.toDouble();
        final max = (hr['max'] as num?)?.toDouble();
        if (avg != null) {
          entries.add(MapEntry(
            d,
            _HRDay(
              dateStr: d['date'] as String? ?? '',
              avg: avg,
              min: min ?? avg,
              max: max ?? avg,
            ),
          ));
        }
      }
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    final avgSpots = <FlSpot>[];
    final maxSpots = <FlSpot>[];
    final minSpots = <FlSpot>[];
    for (var i = 0; i < entries.length; i++) {
      avgSpots.add(FlSpot(i.toDouble(), entries[i].value.avg));
      maxSpots.add(FlSpot(i.toDouble(), entries[i].value.max));
      minSpots.add(FlSpot(i.toDouble(), entries[i].value.min));
    }

    final allVals = entries.expand((e) => [e.value.min, e.value.max]);
    final maxY = (allVals.reduce(math.max) + 12).roundToDouble();
    final minY =
        (allVals.reduce(math.min) - 12).clamp(0.0, double.infinity);

    final overallAvg =
        entries.map((e) => e.value.avg).reduce((a, b) => a + b) /
            entries.length;
    final overallMin = entries.map((e) => e.value.min).reduce(math.min);
    final overallMax = entries.map((e) => e.value.max).reduce(math.max);

    final yFloor = (minY / 20).floor() * 20.0;
    final yCeil = (maxY / 20).ceil() * 20.0;
    const double yInterval = 20;

    final screenWidth = MediaQuery.of(context).size.width - 72;
    const pxPerDay = 50.0;
    final calculatedWidth = entries.length * pxPerDay;
    final chartWidth = math.max(calculatedWidth, screenWidth);

    final double labelInterval;
    if (entries.length <= 10) {
      labelInterval = 1;
    } else if (entries.length <= 20) {
      labelInterval = 2;
    } else {
      labelInterval = (entries.length / 8).ceilToDouble();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: _hrColor.withValues(alpha: 0.06),
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: overallAvg.toStringAsFixed(0),
                      style: const TextStyle(
                          color: _hrColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1),
                    ),
                    const TextSpan(
                      text: '  bpm avg',
                      style: TextStyle(
                          color: _hrColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
                const Spacer(),
                _RangePill(
                  min: overallMin,
                  max: overallMax,
                  color: _hrColor,
                ),
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
                Text('Swipe to scroll • Tap to zoom',
                    style: TextStyle(
                        color: AppColors.subtext.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
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
                            reservedSize: 32,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24),
                      child: SizedBox(
                      width: chartWidth,
                      child: LineChart(
                        LineChartData(
                          minY: yFloor,
                          maxY: yCeil,
                          minX: -0.3,
                          maxX: (entries.length - 1).toDouble() + 0.3,
                          clipData: const FlClipData.none(),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: yInterval,
                            verticalInterval: labelInterval,
                            getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.borderLight,
                                strokeWidth: 1),
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
                                reservedSize: 32,
                                interval: labelInterval,
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i < 0 ||
                                      i >= entries.length ||
                                      i.toDouble() != v) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _shortDate(
                                          entries[i].value.dateStr),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: AppColors.subtext,
                                          fontSize: 9,
                                          height: 1.2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            touchCallback: (event, response) {
                              if (event is FlTapUpEvent &&
                                  response?.lineBarSpots != null &&
                                  response!.lineBarSpots!.isNotEmpty) {
                                final spot =
                                    response.lineBarSpots!.first;
                                final idx = spot.spotIndex;
                                if (idx >= 0 &&
                                    idx < entries.length) {
                                  _openDayDetail(
                                    context,
                                    entries[idx].key,
                                    entries[idx].value.dateStr,
                                  );
                                }
                              }
                            },
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touched) =>
                                  touched.map((s) {
                                final i = s.spotIndex;
                                final e = entries[i].value;
                                return LineTooltipItem(
                                  '${e.avg.toStringAsFixed(0)} bpm\n↓${e.min.toStringAsFixed(0)} ↑${e.max.toStringAsFixed(0)}',
                                  const TextStyle(
                                      color: _hrColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11),
                                );
                              }).toList(),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: maxSpots,
                              isCurved: true,
                              curveSmoothness: 0.3,
                              color:
                                  _hrColor.withValues(alpha: 0.25),
                              barWidth: 1.5,
                              dotData: const FlDotData(show: false),
                              dashArray: [4, 4],
                            ),
                            LineChartBarData(
                              spots: avgSpots,
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: _hrColor,
                              barWidth: 2.6,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter:
                                    (s, _, __, index) =>
                                        FlDotCirclePainter(
                                  radius: index ==
                                          avgSpots.length - 1
                                      ? 5
                                      : 2.6,
                                  color: _hrColor,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _hrColor.withValues(
                                        alpha: 0.18),
                                    _hrColor.withValues(
                                        alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                            LineChartBarData(
                              spots: minSpots,
                              isCurved: true,
                              curveSmoothness: 0.3,
                              color:
                                  _hrColor.withValues(alpha: 0.25),
                              barWidth: 1.5,
                              dotData: const FlDotData(show: false),
                              dashArray: [4, 4],
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _Legend(color: _hrColor, label: 'Avg', solid: true),
                const SizedBox(width: 14),
                _Legend(
                    color: _hrColor.withValues(alpha: 0.6),
                    label: 'Min / Max',
                    solid: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDayDetail(
      BuildContext context, Map<String, dynamic> day, String dateStr) {
    final health = day['health'] is Map<String, dynamic>
        ? day['health'] as Map<String, dynamic>
        : null;
    final hours = (health?['hours'] as List?) ?? const [];
    if (hours.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AthleteHourRawCubit>(),
        child: _DayHourlySheet(
          dateStr: dateStr,
          hours: hours,
          athleteId: athleteId,
          day: day,
        ),
      ),
    );
  }

  String _shortDate(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const mo = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${wd[d.weekday - 1]}\n${d.day} ${mo[d.month - 1]}';
    } catch (_) {
      return '';
    }
  }
}

class _DayHourlySheet extends StatelessWidget {
  final String dateStr;
  final List hours;
  final int athleteId;
  final Map<String, dynamic> day;
  const _DayHourlySheet({
    required this.dateStr,
    required this.hours,
    required this.athleteId,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _statsOfDay(day);
    final hr = stats['heart_rate'] is Map<String, dynamic>
        ? stats['heart_rate'] as Map<String, dynamic>
        : null;
    final hrAvg = (hr?['avg'] as num?)?.toDouble();
    final hrMin = (hr?['min'] as num?)?.toDouble();
    final hrMax = (hr?['max'] as num?)?.toDouble();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _hrColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_outlined,
                        size: 18, color: _hrColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fmtDate(dateStr),
                            style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const Text(
                          'Hourly Breakdown',
                          style: TextStyle(
                              color: AppColors.subtext,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (hrAvg != null)
                    _PillBadge(
                      icon: Icons.favorite,
                      text: '${hrAvg.toStringAsFixed(0)} bpm',
                      color: _hrColor,
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            if (hrAvg != null && hrMin != null && hrMax != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    _SheetStat(
                        label: 'Avg',
                        value: hrAvg.toStringAsFixed(0),
                        color: _hrColor),
                    const SizedBox(width: 10),
                    _SheetStat(
                        label: 'Min',
                        value: hrMin.toStringAsFixed(0),
                        color: _hrColor),
                    const SizedBox(width: 10),
                    _SheetStat(
                        label: 'Max',
                        value: hrMax.toStringAsFixed(0),
                        color: _hrColor),
                  ].map((w) => Expanded(child: w)).toList(),
                ),
              ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _HourlyBreakdown(
                    hours: hours,
                    athleteId: athleteId,
                    dateStr: dateStr,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool solid;
  const _Legend(
      {required this.color, required this.label, required this.solid});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: solid ? color : null,
            border: solid
                ? null
                : Border(
                    top: BorderSide(color: color, width: 2, style: BorderStyle.solid),
                  ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RangePill extends StatelessWidget {
  final double min, max;
  final Color color;
  const _RangePill(
      {required this.min, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '↓ ${min.toStringAsFixed(0)}   ↑ ${max.toStringAsFixed(0)}',
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3),
      ),
    );
  }
}

// ── Daily Card ───────────────────────────────────────────────────────────────

class _DailyCard extends StatefulWidget {
  final Map<String, dynamic> day;
  final int athleteId;
  final bool initiallyExpanded;
  const _DailyCard({
    required this.day,
    required this.athleteId,
    this.initiallyExpanded = false,
  });

  @override
  State<_DailyCard> createState() => _DailyCardState();
}

class _DailyCardState extends State<_DailyCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final dateStr = day['date'] as String? ?? '';
    final health = day['health'] is Map<String, dynamic>
        ? day['health'] as Map<String, dynamic>
        : null;
    final stats = _statsOfDay(day);
    final totalReadings = (health?['total_readings'] as num?)?.toInt() ?? 0;
    final hours = (health?['hours'] as List?) ?? const [];

    final hr = stats['heart_rate'] is Map<String, dynamic>
        ? stats['heart_rate'] as Map<String, dynamic>
        : null;

    final hrAvg = (hr?['avg'] as num?)?.toDouble();
    final hrMin = (hr?['min'] as num?)?.toDouble();
    final hrMax = (hr?['max'] as num?)?.toDouble();

    final sleep = day['sleep'] is Map<String, dynamic>
        ? day['sleep'] as Map<String, dynamic>
        : null;
    final rr = day['rr_intervals'] is Map<String, dynamic>
        ? day['rr_intervals'] as Map<String, dynamic>
        : null;

    final hasBody =
        hr != null || sleep != null || rr != null || hours.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: hasBody ? () => setState(() => _expanded = !_expanded) : null,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: _expanded ? Radius.zero : const Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(_fmtDate(dateStr),
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      if (totalReadings > 0)
                        Text('• ${_fmtNum(totalReadings)} rdg',
                            style: const TextStyle(
                                color: AppColors.subtext,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      const Spacer(),
                      if (hrAvg != null)
                        _PillBadge(
                          icon: Icons.favorite,
                          text: '${hrAvg.toStringAsFixed(0)} bpm',
                          color: _hrColor,
                        ),
                      if (hasBody) ...[
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.keyboard_arrow_down,
                              size: 20, color: AppColors.subtext),
                        ),
                      ],
                    ],
                  ),
                  if (hrAvg != null &&
                      hrMin != null &&
                      hrMax != null &&
                      hrMax > hrMin) ...[
                    const SizedBox(height: 10),
                    _HrRangeBar(min: hrMin, avg: hrAvg, max: hrMax),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : _DailyExpanded(
                    hr: hr,
                    sleep: sleep,
                    rr: rr,
                    hours: hours,
                    athleteId: widget.athleteId,
                    dateStr: dateStr,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _PillBadge(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── HR range bar ─────────────────────────────────────────────────────────────

class _HrRangeBar extends StatelessWidget {
  final double min, avg, max;
  const _HrRangeBar({required this.min, required this.avg, required this.max});

  @override
  Widget build(BuildContext context) {
    final span = max - min;
    final pct = span > 0 ? ((avg - min) / span).clamp(0.0, 1.0) : 0.5;
    const trackColor = Color(0xFFFCD9D9);
    const fillColor = _hrColor;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(min.toStringAsFixed(0),
                  style: const TextStyle(
                      color: AppColors.subtext,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Positioned(
                    left: ((w - 60) * pct).clamp(0.0, w - 60) - 5,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 18,
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 30,
              child: Text(max.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppColors.subtext,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}

// ── Daily expanded body ──────────────────────────────────────────────────────

class _DailyExpanded extends StatelessWidget {
  final Map<String, dynamic>? hr, sleep, rr;
  final List hours;
  final int athleteId;
  final String dateStr;

  const _DailyExpanded({
    required this.hr,
    required this.sleep,
    required this.rr,
    required this.hours,
    required this.athleteId,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: AppColors.borderLight),
        if (hr != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: _VitalTile(
              width: double.infinity,
              icon: Icons.favorite,
              label: 'Heart Rate',
              avg: (hr!['avg'] as num?)?.toDouble() ?? 0,
              min: (hr!['min'] as num?)?.toDouble() ?? 0,
              max: (hr!['max'] as num?)?.toDouble() ?? 0,
              unit: 'bpm',
              color: _hrColor,
            ),
          ),
        if (hours.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _HourlyBreakdown(
                hours: hours, athleteId: athleteId, dateStr: dateStr),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: _StatusBox(
                  icon: Icons.bedtime_outlined,
                  label: 'Sleep',
                  present: sleep != null,
                  color: _sleepColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusBox(
                  icon: Icons.show_chart,
                  label: 'RR Intervals',
                  present: rr != null,
                  color: _rrColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Vital Tile ───────────────────────────────────────────────────────────────

class _VitalTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final double avg, min, max;
  final String unit;
  final Color color;

  const _VitalTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.avg,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(avg.toStringAsFixed(0),
                  style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: TextStyle(
                        color: color.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            _MiniChip(text: '↓ ${min.toStringAsFixed(0)}', color: color),
            const SizedBox(width: 4),
            _MiniChip(text: '↑ ${max.toStringAsFixed(0)}', color: color),
          ]),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 9,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool present;
  final Color color;
  const _StatusBox({
    required this.icon,
    required this.label,
    required this.present,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = present ? color : AppColors.subtext;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: present ? color.withValues(alpha: 0.07) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: present
                ? color.withValues(alpha: 0.2)
                : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: c,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          Text(present ? 'Available' : 'No data',
              style: TextStyle(
                  color: c.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Hourly Breakdown ─────────────────────────────────────────────────────────

class _HourlyBreakdown extends StatelessWidget {
  final List hours;
  final int athleteId;
  final String dateStr;
  const _HourlyBreakdown({
    required this.hours,
    required this.athleteId,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    final entries = <_HourEntry>[];
    for (final h in hours) {
      if (h is! Map<String, dynamic>) continue;
      final hour = (h['hour'] as num?)?.toInt();
      if (hour == null) continue;
      final stats = h['aggregated_stats'] as Map<String, dynamic>? ?? {};
      final hr = stats['heart_rate'];
      double? avg;
      if (hr is Map<String, dynamic>) {
        avg = (hr['avg'] as num?)?.toDouble();
      }
      final time = h['time'] as String?;
      entries.add(_HourEntry(hour: hour, hrAvg: avg, time: time));
    }
    entries.sort((a, b) => a.hour.compareTo(b.hour));
    if (entries.isEmpty) return const SizedBox.shrink();

    final hrVals = entries.where((e) => e.hrAvg != null).map((e) => e.hrAvg!);
    final maxHR = hrVals.isEmpty ? 0.0 : hrVals.reduce(math.max);
    final minHR = hrVals.isEmpty ? 0.0 : hrVals.reduce(math.min);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_outlined,
                  size: 13, color: _hrColor),
              const SizedBox(width: 5),
              const Text('Hourly Heart Rate',
                  style: TextStyle(
                      color: _hrColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app,
                        size: 10, color: AppColors.primary),
                    SizedBox(width: 3),
                    Text('Tap to zoom',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: entries.map((e) {
                  final pct = (maxHR > 0 && e.hrAvg != null)
                      ? (e.hrAvg! / maxHR).clamp(0.0, 1.0)
                      : 0.0;
                  final isHigh = e.hrAvg != null &&
                      maxHR > minHR &&
                      e.hrAvg! >= minHR + (maxHR - minHR) * 0.85;
                  final timeLabel = e.time ?? '${e.hour.toString().padLeft(2, '0')}:00';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: SizedBox(
                      width: 42,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => _openZoom(context, e.hour),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (e.hrAvg != null)
                              Text(e.hrAvg!.toStringAsFixed(0),
                                  style: TextStyle(
                                      color: isHigh
                                          ? _hrColor
                                          : _hrColor.withValues(alpha: 0.65),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Container(
                              height: (74 * pct).clamp(2.0, 74.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isHigh
                                      ? [
                                          _hrColor,
                                          _hrColor.withValues(alpha: 0.5),
                                        ]
                                      : [
                                          _hrColor.withValues(alpha: 0.7),
                                          _hrColor.withValues(alpha: 0.2),
                                        ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(timeLabel,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.subtext,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openZoom(BuildContext context, int hour) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return;
    context
        .read<AthleteHourRawCubit>()
        .fetchHour(athleteId: athleteId, date: date, hour: hour);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AthleteHourRawCubit>(),
        child: _HourRawSheet(
            dateStr: dateStr, hour: hour, athleteId: athleteId),
      ),
    );
  }
}

class _HourEntry {
  final int hour;
  final double? hrAvg;
  final String? time;
  const _HourEntry({required this.hour, required this.hrAvg, this.time});
}

// ── Hour Raw Bottom Sheet (zoom-on-demand) ───────────────────────────────────

class _HourRawSheet extends StatelessWidget {
  final String dateStr;
  final int hour;
  final int athleteId;
  const _HourRawSheet({
    required this.dateStr,
    required this.hour,
    required this.athleteId,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _hrColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.zoom_in,
                        size: 18, color: _hrColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fmtDate(dateStr),
                            style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        Text(
                          '${hour.toString().padLeft(2, '0')}:00 – ${hour.toString().padLeft(2, '0')}:59',
                          style: const TextStyle(
                              color: AppColors.subtext,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: BlocBuilder<AthleteHourRawCubit, AthleteHourRawState>(
                builder: (context, state) {
                  switch (state.status) {
                    case AthleteHourRawStatus.loading:
                    case AthleteHourRawStatus.initial:
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      );
                    case AthleteHourRawStatus.error:
                      return _ErrorView(
                        message: state.errorMessage ?? 'Failed to load',
                        onRetry: () {
                          final d = DateTime.tryParse(dateStr);
                          if (d != null) {
                            context.read<AthleteHourRawCubit>().fetchHour(
                                athleteId: athleteId, date: d, hour: hour);
                          }
                        },
                      );
                    case AthleteHourRawStatus.loaded:
                      final raw = state.data?.healthRaw ?? const [];
                      if (raw.isEmpty) {
                        return const _EmptyHint(
                            icon: Icons.inbox_outlined,
                            text: 'No raw readings for this hour');
                      }
                      return _HourRawBody(
                          raw: raw, scrollController: scrollCtrl);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HourRawBody extends StatelessWidget {
  final List<Map<String, dynamic>> raw;
  final ScrollController scrollController;
  const _HourRawBody({required this.raw, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final hrSpots = <FlSpot>[];
    double? hrMin, hrMax;
    int? firstEpoch;

    for (final r in raw) {
      final ts = r['recorded_at'];
      DateTime? dt;
      if (ts is String) dt = DateTime.tryParse(ts);
      if (dt == null) continue;
      firstEpoch ??= dt.millisecondsSinceEpoch;
      final x = (dt.millisecondsSinceEpoch - firstEpoch) / 1000.0;
      final hr = _toDouble(r['heart_rate']);
      if (hr != null) {
        hrSpots.add(FlSpot(x, hr));
        hrMin = hrMin == null ? hr : math.min(hrMin, hr);
        hrMax = hrMax == null ? hr : math.max(hrMax, hr);
      }
    }

    final hrAvg = hrSpots.isEmpty
        ? null
        : hrSpots.map((s) => s.y).reduce((a, b) => a + b) / hrSpots.length;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _SheetStat(
                  label: 'Readings',
                  value: _fmtNum(raw.length),
                  color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SheetStat(
                  label: 'HR avg',
                  value: hrAvg?.toStringAsFixed(0) ?? '--',
                  color: _hrColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SheetStat(
                label: 'HR range',
                value:
                    '${hrMin?.toStringAsFixed(0) ?? '--'}–${hrMax?.toStringAsFixed(0) ?? '--'}',
                color: _hrColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (hrSpots.isNotEmpty) ...[
          _SectionHeader(
              icon: Icons.favorite, title: 'Heart Rate (second-by-second)'),
          const SizedBox(height: 8),
          _RawLineChart(
            spots: hrSpots,
            color: _hrColor,
            minY: ((hrMin ?? 0) - 5).clamp(0, double.infinity).toDouble(),
            maxY: (hrMax ?? 0) + 5,
            unit: 'bpm',
            startEpochMs: firstEpoch,
          ),
        ],
      ],
    );
  }
}

class _SheetStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SheetStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.subtext,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _RawLineChart extends StatefulWidget {
  final List<FlSpot> spots;
  final Color color;
  final double minY, maxY;
  final String unit;

  /// Epoch ms of the first data point — used to show real clock time on X-axis.
  final int? startEpochMs;

  const _RawLineChart({
    required this.spots,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.unit,
    this.startEpochMs,
  });

  @override
  State<_RawLineChart> createState() => _RawLineChartState();
}

class _RawLineChartState extends State<_RawLineChart> {
  /// Zoom levels: px per second of data.
  static const _zoomLevels = [0.3, 0.5, 1.0, 2.0, 4.0];
  static const _zoomLabels = ['1x', '2x', '3x', '5x', '10x'];
  int _zoomIndex = 1; // start at 0.5 px/sec

  double get _pxPerSecond => _zoomLevels[_zoomIndex];

  void _zoomIn() {
    if (_zoomIndex < _zoomLevels.length - 1) {
      setState(() => _zoomIndex++);
    }
  }

  void _zoomOut() {
    if (_zoomIndex > 0) {
      setState(() => _zoomIndex--);
    }
  }

  void _resetZoom() {
    setState(() => _zoomIndex = 1);
  }

  /// X-axis label — short format for axis, detailed for tooltip.
  String _xAxisLabel(double x, int? startEpochMs) {
    if (startEpochMs != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        startEpochMs + (x * 1000).toInt(),
      ).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m'; // compact: "14:05"
    }
    final sec = x.toInt();
    final mm = (sec ~/ 60).toString().padLeft(2, '0');
    final ss = (sec % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Tooltip label — includes seconds for precision.
  String _tooltipLabel(double x, int? startEpochMs) {
    if (startEpochMs != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        startEpochMs + (x * 1000).toInt(),
      ).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return '$h:$m:$s'; // detailed: "14:05:30"
    }
    final sec = x.toInt();
    final mm = (sec ~/ 60).toString().padLeft(2, '0');
    final ss = (sec % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final spots = widget.spots;
    final color = widget.color;
    final unit = widget.unit;
    final maxX = spots.isEmpty ? 1.0 : spots.last.x;
    final screenWidth = MediaQuery.of(context).size.width - 72;

    // Chart width based on zoom level
    const minChartWidth = 350.0;
    final calculatedWidth =
        (maxX * _pxPerSecond).clamp(minChartWidth, double.infinity);
    final chartWidth = math.max(calculatedWidth, screenWidth);

    // X-axis: smart intervals based on visible density
    final visibleSeconds = chartWidth > 0 ? maxX / (chartWidth / screenWidth) : maxX;
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

    // Y-axis: round intervals (20 bpm steps)
    final yFloor = (widget.minY / 20).floor() * 20.0;
    final yCeil = (widget.maxY / 20).ceil() * 20.0;
    const double yInterval = 20;

    final canZoomIn = _zoomIndex < _zoomLevels.length - 1;
    final canZoomOut = _zoomIndex > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Zoom controls ──
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.swipe_outlined,
                    size: 12,
                    color: AppColors.subtext.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  'Swipe to scroll',
                  style: TextStyle(
                    color: AppColors.subtext.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _ZoomButton(
                  icon: Icons.remove,
                  onTap: canZoomOut ? _zoomOut : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: _resetZoom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _zoomLabels[_zoomIndex],
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                _ZoomButton(
                  icon: Icons.add,
                  onTap: canZoomIn ? _zoomIn : null,
                ),
              ],
            ),
          ),

          // ── Chart ──
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // ── Fixed Y-axis ──
                SizedBox(
                  width: 40,
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
                                    color: AppColors.subtext, fontSize: 10)),
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

                // ── Scrollable chart ──
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: chartWidth,
                      child: LineChart(
                        LineChartData(
                          minY: yFloor,
                          maxY: yCeil,
                          minX: 0,
                          maxX: maxX,
                          clipData: const FlClipData.all(),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: yInterval,
                            verticalInterval: labelInterval,
                            getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.borderLight,
                                strokeWidth: 1),
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
                                  final label = _xAxisLabel(v, widget.startEpochMs);
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4),
                                    child: Text(label,
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
                              getTooltipItems: (touched) => touched
                                  .map((s) {
                                    final timeStr = _tooltipLabel(s.x, widget.startEpochMs);
                                    return LineTooltipItem(
                                      '${s.y.toStringAsFixed(0)} $unit\n$timeStr',
                                      TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: false,
                              color: color,
                              barWidth: 1.6,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Zoom Button ─────────────────────────────────────────────────────────────

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _ZoomButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.borderLight,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? AppColors.primary : AppColors.subtext,
        ),
      ),
    );
  }
}

// ── Section header / shared bits ─────────────────────────────────────────────

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

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final visible = items.where((i) => i.value != null).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(visible.length, (i) {
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(visible[i].label,
                          style: const TextStyle(
                              color: AppColors.subtext, fontSize: 12)),
                    ),
                    Expanded(
                      child: Text(visible[i].value!,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              if (i < visible.length - 1)
                const Divider(height: 1, color: AppColors.borderLight),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String? value;
  const _InfoRow(this.label, this.value);
}

class _LoadingBanner extends StatelessWidget {
  const _LoadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
          SizedBox(width: 10),
          Text('Loading full details…',
              style: TextStyle(color: AppColors.primary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.subtext),
            const SizedBox(height: 10),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.errorBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline,
                color: AppColors.error, size: 28),
          ),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.subtext, fontSize: 12)),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

bool _hasHR(List<Map<String, dynamic>> days) => days.any((d) {
      final hr = _statsOfDay(d)['heart_rate'];
      return hr is Map && hr['avg'] != null;
    });

class _HRDay {
  final String dateStr;
  final double avg, min, max;
  const _HRDay(
      {required this.dateStr,
      required this.avg,
      required this.min,
      required this.max});
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

Map<String, dynamic> _statsOfDay(Map<String, dynamic> d) {
  final health = d['health'];
  if (health is Map<String, dynamic>) {
    final s = health['aggregated_stats'];
    if (s is Map<String, dynamic>) return s;
  }
  final s = d['aggregated_stats'];
  return s is Map<String, dynamic> ? s : const {};
}

String _fmtDate(String raw) {
  try {
    final d = DateTime.parse(raw);
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  } catch (_) {
    return raw;
  }
}

String _fmtNum(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) return '${(n / 1000).toStringAsFixed(n < 10000 ? 1 : 0)}k';
  return '${(n / 1000000).toStringAsFixed(1)}M';
}
