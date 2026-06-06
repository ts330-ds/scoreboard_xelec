import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/service/socket/coach_live_task_socket_service.dart';
import '../cubit/coach_live_task_cubit.dart';
import '../cubit/coach_live_task_state.dart';

class CoachLiveTaskMobile extends StatelessWidget {
  final int taskId;
  final String athleteName;
  final String taskName;

  const CoachLiveTaskMobile({
    super.key,
    required this.taskId,
    required this.athleteName,
    required this.taskName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoachLiveTaskCubit, CoachLiveTaskState>(
      listenWhen: (prev, curr) =>
          (prev.errorMessage != curr.errorMessage &&
              curr.errorMessage != null) ||
          (!prev.isAthleteStopped && curr.isAthleteStopped),
      listener: (context, state) {
        if (state.isAthleteStopped) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.stop_circle_outlined,
                      color: AppColors.error, size: 24),
                  SizedBox(width: 10),
                  Text('Session Ended',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                '$athleteName has stopped their session.',
                style: const TextStyle(color: AppColors.subtext, fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.pop();
                  },
                  child: const Text('OK',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      },
      builder: (context, state) {
        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              context.read<CoachLiveTaskCubit>().stopWatching(taskId);
            }
          },
          child: SafeArea(
            child: Scaffold(
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
                _LiveBadge(isStopped: state.isAthleteStopped),
                const SizedBox(width: 12),
              ],
            ),
            body: switch (state.status) {
              CoachLiveTaskStatus.connecting => const _ConnectingView(),
              CoachLiveTaskStatus.error => _ErrorView(
                  message: state.errorMessage ?? 'Connection failed',
                  onRetry: () =>
                      context.read<CoachLiveTaskCubit>().startWatching(taskId),
                ),
              _ => _LiveView(
                  state: state,
                  taskName: taskName,
                  athleteName: athleteName,
                  isReconnecting:
                      state.status == CoachLiveTaskStatus.reconnecting,
                ),
            },
          ),
        ),
        );
      },
    );
  }
}

// ── Live Badge (AppBar action) ────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  final bool isStopped;
  const _LiveBadge({required this.isStopped});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStopped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Ended',
            style: TextStyle(
                color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: Colors.greenAccent
                    .withValues(alpha: 0.4 + 0.6 * _controller.value),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            const Text('LIVE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}

// ── Connecting ────────────────────────────────────────────────────────────────

class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Connecting to live session...',
              style: TextStyle(color: AppColors.subtext, fontSize: 14)),
        ],
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
  Widget build(BuildContext context) {
    return Center(
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
              child: const Icon(Icons.wifi_off_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Connection lost',
                style: TextStyle(color: AppColors.subtext, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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

// ── Reconnecting Banner ───────────────────────────────────────────────────────

class _ReconnectingBanner extends StatelessWidget {
  final int attempt;
  final bool exhausted;
  final bool isAuthFailure;
  const _ReconnectingBanner({
    this.attempt = 0,
    this.exhausted = false,
    this.isAuthFailure = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;
    final bool showSpinner;
    final bool showRetry;

    if (isAuthFailure) {
      color = AppColors.error;
      icon = Icons.lock_outline;
      label = 'Session expired — please log in again';
      showSpinner = false;
      showRetry = false;
    } else if (exhausted) {
      color = AppColors.error;
      icon = Icons.wifi_off_rounded;
      label = 'Cannot reach server';
      showSpinner = false;
      showRetry = true;
    } else {
      color = AppColors.warning;
      icon = Icons.sync;
      label = attempt > 0
          ? 'Reconnecting (#$attempt)...'
          : 'Reconnecting...';
      showSpinner = true;
      showRetry = false;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSpinner)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          else
            Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          if (showRetry) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: () => context
                  .read<CoachLiveTaskCubit>()
                  .retryConnectionManually(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Athlete Offline Banner ────────────────────────────────────────────────────

class _AthleteOfflineBanner extends StatefulWidget {
  final String athleteName;
  const _AthleteOfflineBanner({required this.athleteName});

  @override
  State<_AthleteOfflineBanner> createState() => _AthleteOfflineBannerState();
}

class _AthleteOfflineBannerState extends State<_AthleteOfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.10 + 0.06 * _pulse.value),
          border: Border(
            bottom: BorderSide(
                color: AppColors.error.withValues(alpha: 0.35), width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 18 + 1.5 * _pulse.value),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.athleteName} offline',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Athlete's internet or device disconnected. "
                    'Readings will resume once reconnected.',
                    style: TextStyle(
                      color: AppColors.subtext,
                      fontSize: 11,
                      height: 1.3,
                    ),
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

// ── Debug Socket Status Bar ───────────────────────────────────────────────────

class _DebugSocketStatusBar extends StatelessWidget {
  final CoachLiveTaskState state;
  const _DebugSocketStatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final coachConnected = state.status == CoachLiveTaskStatus.watching ||
        state.status == CoachLiveTaskStatus.athleteStopped;
    final coachReconnecting = state.status == CoachLiveTaskStatus.reconnecting;

    final coachColor = coachConnected
        ? Colors.greenAccent
        : coachReconnecting
            ? Colors.orangeAccent
            : Colors.redAccent;

    final coachLabel = coachConnected
        ? 'Connected'
        : coachReconnecting
            ? 'Reconnecting${state.reconnectAttempt > 0 ? ' #${state.reconnectAttempt}' : ''}'
            : state.status == CoachLiveTaskStatus.connecting
                ? 'Connecting'
                : 'Disconnected';

    final athleteColor =
        state.isAthleteConnectionLost ? Colors.redAccent : Colors.greenAccent;
    final athleteLabel =
        state.isAthleteConnectionLost ? 'Offline' : 'Online';

    return Container(
      width: double.infinity,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          const Text('DEBUG  ',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          _StatusDot(color: coachColor, label: 'Coach: $coachLabel'),
          const SizedBox(width: 16),
          _StatusDot(color: athleteColor, label: 'Athlete: $athleteLabel'),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Live View ─────────────────────────────────────────────────────────────────

class _LiveView extends StatelessWidget {
  final CoachLiveTaskState state;
  final String taskName;
  final String athleteName;
  final bool isReconnecting;
  const _LiveView(
      {required this.state,
      required this.taskName,
      required this.athleteName,
      this.isReconnecting = false});

  int get _minBpm => state.readings.isEmpty
      ? 0
      : state.readings.map((r) => r.bpm).reduce(math.min);

  int get _maxBpm => state.readings.isEmpty
      ? 0
      : state.readings.map((r) => r.bpm).reduce(math.max);

  int get _avgBpm => state.readings.isEmpty
      ? 0
      : (state.readings.map((r) => r.bpm).reduce((a, b) => a + b) /
              state.readings.length)
          .round();

  @override
  Widget build(BuildContext context) {
    final showReconnectBanner = isReconnecting ||
        state.isReconnectExhausted ||
        state.isAuthFailure;

    return Column(
      children: [
        _DebugSocketStatusBar(state: state),
        if (showReconnectBanner)
          _ReconnectingBanner(
            attempt: state.reconnectAttempt,
            exhausted: state.isReconnectExhausted,
            isAuthFailure: state.isAuthFailure,
          ),
        if (state.isAthleteConnectionLost)
          _AthleteOfflineBanner(athleteName: athleteName),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).padding.bottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero BPM Card
                _BpmHeroCard(
                  bpm: state.latestBpm,
                  isStopped: state.isAthleteStopped,
                  minBpm: _minBpm,
                  maxBpm: _maxBpm,
                  avgBpm: _avgBpm,
                  totalReadings: state.totalReadings,
                ),
                const SizedBox(height: 16),

                // ── Vitals
                if (state.latestSpo2 != null ||
                    state.latestSugarLevel != null ||
                    state.latestStressLevel != null) ...[
                  _SectionHeader(
                      icon: Icons.monitor_heart_outlined, title: 'Vitals'),
                  const SizedBox(height: 10),
                  _VitalsGrid(state: state),
                  const SizedBox(height: 16),
                ],

                // ── Heart Rate Chart
                if (state.readings.length >= 2) ...[
                  _SectionHeader(
                      icon: Icons.show_chart_rounded,
                      title: 'Heart Rate History'),
                  const SizedBox(height: 10),
                  _HeartRateChart(readings: state.readings),
                  const SizedBox(height: 16),
                ],

                // ── HRV Chart
                Builder(builder: (context) {
                  final hrvPoints = state.readings
                      .where((r) => r.sugarLevel != null && r.sugarLevel! > 0)
                      .map((r) => r.sugarLevel!)
                      .toList();
                  if (hrvPoints.length < 2) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                          icon: Icons.monitor_heart_outlined,
                          title: 'HRV (RMSSD) History'),
                      const SizedBox(height: 10),
                      _HrvChart(hrvPoints: hrvPoints),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
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
  Widget build(BuildContext context) {
    return Row(
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
}

// ── BPM Hero Card ─────────────────────────────────────────────────────────────

class _BpmHeroCard extends StatefulWidget {
  final int bpm;
  final bool isStopped;
  final int minBpm;
  final int maxBpm;
  final int avgBpm;
  final int totalReadings;
  const _BpmHeroCard({
    required this.bpm,
    required this.isStopped,
    required this.minBpm,
    required this.maxBpm,
    required this.avgBpm,
    required this.totalReadings,
  });

  @override
  State<_BpmHeroCard> createState() => _BpmHeroCardState();
}

class _BpmHeroCardState extends State<_BpmHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_BpmHeroCard old) {
    super.didUpdateWidget(old);
    if (old.bpm != widget.bpm && widget.bpm > 0 && !widget.isStopped) {
      _pulse.forward(from: 0).then((_) => _pulse.reverse());
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _zoneColor {
    if (widget.bpm <= 0) return AppColors.subtext;
    if (widget.bpm < 60) return AppColors.primary;
    if (widget.bpm < 100) return AppColors.success;
    if (widget.bpm < 140) return AppColors.warning;
    return AppColors.error;
  }

  String get _zoneLabel {
    if (widget.bpm <= 0) return 'Waiting...';
    if (widget.bpm < 60) return 'Resting';
    if (widget.bpm < 100) return 'Normal';
    if (widget.bpm < 140) return 'Moderate';
    return 'High Intensity';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isStopped ? AppColors.subtext : _zoneColor;

    return Container(
      width: double.infinity,
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
          // ── Colored top band
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      Text(_zoneLabel,
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

          // ── BPM display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Text(
                    widget.bpm > 0 ? '${widget.bpm}' : '--',
                    style: TextStyle(
                      color: color,
                      fontSize: 80,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('BPM',
                      style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // ── Divider
          Divider(height: 1, color: AppColors.border),

          // ── Min / Avg / Max + Readings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Row(
              children: [
                _BpmStat(
                  label: 'Min',
                  value: widget.minBpm > 0 ? '${widget.minBpm}' : '--',
                  color: AppColors.primary,
                ),
                _VerticalDivider(),
                _BpmStat(
                  label: 'Avg',
                  value: widget.avgBpm > 0 ? '${widget.avgBpm}' : '--',
                  color: AppColors.success,
                ),
                _VerticalDivider(),
                _BpmStat(
                  label: 'Max',
                  value: widget.maxBpm > 0 ? '${widget.maxBpm}' : '--',
                  color: AppColors.error,
                ),
                _VerticalDivider(),
                _BpmStat(
                  label: 'Readings',
                  value: '${widget.totalReadings}',
                  color: AppColors.subtext,
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
  Widget build(BuildContext context) {
    return Expanded(
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
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 32, color: AppColors.border);
  }
}

// ── Vitals Grid ───────────────────────────────────────────────────────────────

class _VitalsGrid extends StatelessWidget {
  final CoachLiveTaskState state;
  const _VitalsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = <_VitalData>[];

    if (state.latestSpo2 != null) {
      items.add(_VitalData(
        icon: Icons.water_drop_rounded,
        label: 'SpO2',
        value: '${state.latestSpo2!.toStringAsFixed(1)}%',
        color: AppColors.vitalOxygen,
        subtitle: _spo2Status(state.latestSpo2!),
      ));
    }
    if (state.latestSugarLevel != null) {
      items.add(_VitalData(
        icon: Icons.monitor_heart_outlined,
        label: 'HRV',
        value: state.latestSugarLevel!.toStringAsFixed(1),
        color: const Color(0xFF40C4FF),
        subtitle: 'ms RMSSD',
      ));
    }
    if (state.latestStressLevel != null) {
      items.add(_VitalData(
        icon: Icons.psychology_outlined,
        label: 'Stress',
        value: '${state.latestStressLevel}',
        color: AppColors.vitalStress,
        subtitle: _stressLabel(state.latestStressLevel!),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < items.length ? 10 : 0),
            child: Row(
              children: [
                Expanded(child: _VitalCard(data: items[i])),
                if (i + 1 < items.length) ...[
                  const SizedBox(width: 10),
                  Expanded(child: _VitalCard(data: items[i + 1])),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  String _spo2Status(double spo2) {
    if (spo2 >= 95) return 'Normal';
    if (spo2 >= 90) return 'Low';
    return 'Critical';
  }

  String _stressLabel(int level) {
    if (level <= 25) return 'Relaxed';
    if (level <= 50) return 'Moderate';
    if (level <= 75) return 'High';
    return 'Very High';
  }
}

class _VitalData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String subtitle;
  const _VitalData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
  });
}

class _VitalCard extends StatelessWidget {
  final _VitalData data;
  const _VitalCard({required this.data});

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
            color: data.color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label,
                    style: const TextStyle(
                        color: AppColors.subtext,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(data.value,
                    style: TextStyle(
                        color: data.color,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1)),
                Text(data.subtitle,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── HRV Chart ─────────────────────────────────────────────────────────────────

const _kHrvColor = Color(0xFF40C4FF);

class _HrvChart extends StatelessWidget {
  final List<double> hrvPoints;
  const _HrvChart({required this.hrvPoints});

  @override
  Widget build(BuildContext context) {
    final spots = hrvPoints
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final maxY = (hrvPoints.reduce(math.max) + 10).clamp(0.0, 999.0);
    final minY = (hrvPoints.reduce(math.min) - 10).clamp(0.0, 999.0);

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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Text(
                  '${hrvPoints.last.toStringAsFixed(1)} ms',
                  style: const TextStyle(
                      color: _kHrvColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                const Text('Current RMSSD',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const Spacer(),
                Text('${hrvPoints.length} pts',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),

          // Chart
          SizedBox(
            height: 150,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
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
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 10,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt()}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: _kHrvColor,
                      barWidth: 1.8,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, index) {
                          final isLast = index == spots.length - 1;
                          return FlDotCirclePainter(
                            radius: isLast ? 5 : 0,
                            color: _kHrvColor,
                            strokeWidth: isLast ? 2 : 0,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                      shadow: Shadow(
                          color: _kHrvColor.withValues(alpha: 0.4),
                          blurRadius: 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Heart Rate Chart ──────────────────────────────────────────────────────────

class _HeartRateChart extends StatelessWidget {
  final List<CoachLiveReading> readings;
  const _HeartRateChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final spots = readings
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.bpm.toDouble()))
        .toList();

    final bpms = readings.map((r) => r.bpm);
    final maxY = (bpms.reduce(math.max) + 20).toDouble();
    final minY =
        ((bpms.reduce(math.min) - 20).clamp(0, 999)).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Chart header
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Text(
                  readings.isNotEmpty
                      ? '${readings.last.bpm} BPM'
                      : '--',
                  style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                const Text('Current',
                    style: TextStyle(
                        color: AppColors.subtext, fontSize: 12)),
                const Spacer(),
                Text('${readings.length} points',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),

          // ── Chart
          SizedBox(
            height: 160,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.borderLight,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 20,
                        getTitlesWidget: (val, _) => Text(
                          '${val.toInt()}',
                          style: const TextStyle(
                              color: AppColors.subtext, fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.error,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, index) {
                          final isLast = index == spots.length - 1;
                          return FlDotCirclePainter(
                            radius: isLast ? 5 : 0,
                            color: AppColors.error,
                            strokeWidth: isLast ? 2 : 0,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.error.withValues(alpha: 0.18),
                            AppColors.error.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
