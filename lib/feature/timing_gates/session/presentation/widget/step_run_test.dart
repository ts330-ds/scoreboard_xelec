import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_state.dart';

class StepRunTest extends StatelessWidget {
  const StepRunTest({super.key});

  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _border = Color(0xFFDDE3EC);
  static const _success = Color(0xFF16A34A);
  static const _warning = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimingSessionCubit, TimingSessionState>(
      builder: (context, state) {
        // YOYO: fully separate layout
        if (state.mode == 'yoyo') return _buildYoyoLayout(context, state);

        if (state.phase == RunTestPhase.done) return _buildDone(context);
        return Column(
          children: [
            _buildProgress(state),
            Expanded(
              child: state.mode == 'shuttle'
                  ? _buildShuttleBody(context, state)
                  : _buildSingleBody(context, state),
            ),
            _buildFooter(context, state),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // YOYO LAYOUT
  // ══════════════════════════════════════════════════════════════════════════

  static const _red = Color(0xFFDC2626);
  static const _orange = Color(0xFFD97706);

  Widget _buildYoyoLayout(BuildContext context, TimingSessionState state) {
    if (state.yoyoPhase == YoYoPhase.done) return _buildYoyoDone(context, state);
    return Column(
      children: [
        _buildYoyoHeader(state),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: List.generate(state.yoyoNumLanes, (i) {
              final laneStatus = i < state.yoyoLaneStatuses.length
                  ? state.yoyoLaneStatuses[i]
                  : YoYoLaneStatus(laneNumber: i + 1);
              final athleteName = i < state.athletes.length
                  ? state.athletes[i].fullName
                  : 'Lane ${i + 1}';
              return _buildYoyoLaneCard(state, laneStatus, athleteName);
            }),
          ),
        ),
        _buildYoyoFooter(context, state),
      ],
    );
  }

  Widget _buildYoyoHeader(TimingSessionState state) {
    Color bgColor = _surface;
    Color titleColor = _text;
    String title = '';
    String subtitle = '';

    switch (state.yoyoPhase) {
      case YoYoPhase.idle:
        title = 'Ready to Start';
        subtitle = 'Tap Start to begin the 5-second countdown';
        break;
      case YoYoPhase.countdown:
        bgColor = _primaryLight;
        titleColor = _primary;
        title = 'Countdown…';
        subtitle = 'Gates arming — stand clear, do not cross';
        break;
      case YoYoPhase.running:
        bgColor = const Color(0xFFF0FDF4);
        titleColor = _success;
        title = 'Level ${state.yoyoCurrentLevel}  ·  Rep ${state.yoyoCurrentRep}';
        subtitle = 'Window: ${state.yoyoWindowSecs.toStringAsFixed(1)}s per rep';
        break;
      case YoYoPhase.recovery:
        bgColor = _warning.withValues(alpha: 0.08);
        titleColor = _warning;
        title = 'Recovery — 10 seconds';
        subtitle = 'Next: Level ${state.yoyoCurrentLevel}  Rep ${state.yoyoCurrentRep}';
        break;
      case YoYoPhase.done:
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (state.yoyoPhase == YoYoPhase.countdown ||
                  state.yoyoPhase == YoYoPhase.running) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: titleColor),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: _subtext, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildYoyoLaneCard(
    TimingSessionState state,
    YoYoLaneStatus laneStatus,
    String athleteName,
  ) {
    final isEliminated = laneStatus.eliminated;
    final isRunning = state.yoyoPhase == YoYoPhase.running;

    Color borderColor = isEliminated ? _red.withValues(alpha: 0.35) : _border;
    Color bgColor = isEliminated ? _red.withValues(alpha: 0.04) : _surface;
    if (isRunning && !isEliminated) {
      borderColor = _primary.withValues(alpha: 0.25);
      bgColor = _primaryLight.withValues(alpha: 0.3);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // ── Header row: lane circle + athlete + status ─────────────────
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isEliminated ? _red : _primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'L${laneStatus.laneNumber}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athleteName,
                      style: const TextStyle(
                          color: _text, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if (isEliminated)
                      const Text('ELIMINATED',
                          style: TextStyle(
                              color: _red,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5))
                    else
                      Text(
                        'Active${laneStatus.strikes > 0 ? " · ${laneStatus.strikes} strike${laneStatus.strikes > 1 ? "s" : ""}" : ""}',
                        style: const TextStyle(color: _subtext, fontSize: 12),
                      ),
                  ],
                ),
              ),
              // Finish time when rep is done for this lane
              if (!isEliminated && laneStatus.finishHit && laneStatus.lastFinishTime != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${laneStatus.lastFinishTime!.toStringAsFixed(2)}s',
                      style: const TextStyle(
                          color: _success,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                    const Text('✓ Done',
                        style: TextStyle(color: _success, fontSize: 10)),
                  ],
                ),
            ],
          ),

          // ── Gate hit indicators (visible when running & not eliminated) ─
          if (!isEliminated && isRunning) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFEEF2F6)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildYoyoGateIndicator(label: 'Turn Gate', hit: laneStatus.turnHit),
                const SizedBox(width: 8),
                _buildYoyoGateIndicator(label: 'Finish Gate', hit: laneStatus.finishHit),
              ],
            ),
          ],

          // ── Strike dots ────────────────────────────────────────────────
          if (!isEliminated) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Strikes: ',
                    style: TextStyle(color: _subtext, fontSize: 12)),
                ...List.generate(
                  2,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      i < laneStatus.strikes ? Icons.circle : Icons.circle_outlined,
                      color: i < laneStatus.strikes ? _orange : _subtext,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYoyoGateIndicator({required String label, required bool hit}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: hit ? _success.withValues(alpha: 0.08) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: hit ? _success.withValues(alpha: 0.4) : _border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hit ? Icons.sensors : Icons.sensors_off,
              size: 13,
              color: hit ? _success : _subtext,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: hit ? _success : _subtext,
                fontSize: 11,
                fontWeight: hit ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (hit) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check, size: 11, color: _success),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildYoyoFooter(BuildContext context, TimingSessionState state) {
    final cubit = context.read<TimingSessionCubit>();

    // Only show Start button before test begins
    if (state.yoyoPhase == YoYoPhase.idle) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: _surface,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text(
              'Start Yo-Yo Test',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: cubit.sendStart,
          ),
        ),
      );
    }

    // Test running — show status text only (firmware drives everything)
    String statusText;
    Color statusColor;
    switch (state.yoyoPhase) {
      case YoYoPhase.countdown:
        statusText = '⏱  5-second countdown in progress';
        statusColor = _primary;
        break;
      case YoYoPhase.running:
        statusText = '🏃  Test running — results are automatic';
        statusColor = _success;
        break;
      case YoYoPhase.recovery:
        statusText = '😮‍💨  Recovery period — next rep starts automatically';
        statusColor = _warning;
        break;
      default:
        statusText = '';
        statusColor = _subtext;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Text(
        statusText,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: statusColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildYoyoDone(BuildContext context, TimingSessionState state) {
    final isAllCleared = state.yoyoTestOverReason == 'all_stages_cleared';
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ── Hero card ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isAllCleared
                        ? const Color(0xFFF0FDF4)
                        : _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isAllCleared
                          ? _success.withValues(alpha: 0.3)
                          : _border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isAllCleared ? Icons.emoji_events : Icons.flag_outlined,
                        color: isAllCleared ? _success : _primary,
                        size: 52,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAllCleared ? 'All Stages Cleared! 🏆' : 'Yo-Yo Test Complete',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: _text, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAllCleared
                            ? 'Outstanding — all athletes survived every level.'
                            : 'All athletes have been eliminated.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _subtext, fontSize: 13),
                      ),
                      if (state.yoyoCurrentLevel.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Last Level: ${state.yoyoCurrentLevel}  ·  Rep ${state.yoyoCurrentRep}',
                            style: const TextStyle(
                                color: _primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Final standings ────────────────────────────────────
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Final Standings',
                    style: TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(state.yoyoNumLanes, (i) {
                  final laneStatus = i < state.yoyoLaneStatuses.length
                      ? state.yoyoLaneStatuses[i]
                      : YoYoLaneStatus(laneNumber: i + 1);
                  final athleteName = i < state.athletes.length
                      ? state.athletes[i].fullName
                      : 'Lane ${i + 1}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: laneStatus.eliminated
                          ? _red.withValues(alpha: 0.04)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: laneStatus.eliminated
                            ? _red.withValues(alpha: 0.25)
                            : _success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: laneStatus.eliminated ? _red : _success,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'L${i + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(athleteName,
                                  style: const TextStyle(
                                      color: _text,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                laneStatus.eliminated
                                    ? 'Eliminated'
                                    : 'Survived ✓',
                                style: TextStyle(
                                  color: laneStatus.eliminated
                                      ? _red
                                      : _success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Per-lane level: eliminated → their level, survived → global
                        Builder(builder: (_) {
                          final lvl = laneStatus.eliminated
                              ? (laneStatus.eliminatedAtLevel ?? state.yoyoCurrentLevel)
                              : state.yoyoCurrentLevel;
                          if (lvl.isEmpty) return const SizedBox.shrink();
                          return Text(
                            'Lv $lvl',
                            style: TextStyle(
                              color: laneStatus.eliminated ? _red : _success,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // ── Footer ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: const BoxDecoration(
            color: _surface,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.read<TimingSessionCubit>().goToStep(6),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'View Results →',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Progress bar ───────────────────────────────────────────────────────────

  Widget _buildProgress(TimingSessionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: _surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.completedTrialsCount} / ${state.totalTrials} trials',
                style: const TextStyle(color: _subtext, fontSize: 12),
              ),
              Text(
                '${(state.progressPercent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: _primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: state.progressPercent,
            backgroundColor: _primaryLight,
            valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  // ── Shuttle: 3-lane parallel body ─────────────────────────────────────────

  Widget _buildShuttleBody(BuildContext context, TimingSessionState state) {
    final batch = state.currentShuttleBatch;
    if (batch.isEmpty) {
      return const Center(child: Text('Session complete.'));
    }

    final trialNum = batch.first.trialNumber;
    final doneLanes = state.shuttleBatchResults.length;
    final totalLanes = batch.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trial badge + batch status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Trial $trialNum of ${state.trialsCount}',
                  style: const TextStyle(
                      color: _primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (state.phase == RunTestPhase.waitingForResult)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$doneLanes / $totalLanes done',
                    style: const TextStyle(
                        color: _warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Lane cards — one per athlete
          ...batch.map((item) => _buildLaneCard(state, item)),
          const SizedBox(height: 14),

          // Phase indicator
          _buildPhaseCard(state),
        ],
      ),
    );
  }

  /// One athlete's lane card with real-time result display.
  Widget _buildLaneCard(TimingSessionState state, TrialQueueItem item) {
    final lane = item.shuttleLane ?? 1;
    final result = state.shuttleBatchResults[lane];
    final isDone = result != null;
    final isWaiting =
        state.phase == RunTestPhase.waitingForResult && !isDone;

    // Colour scheme: green when done, blue while waiting, neutral when ready
    final Color borderColor = isDone
        ? _success.withValues(alpha: 0.4)
        : isWaiting
            ? _primary.withValues(alpha: 0.25)
            : _border;
    final Color bgColor = isDone
        ? _success.withValues(alpha: 0.06)
        : isWaiting
            ? _primaryLight.withValues(alpha: 0.5)
            : _surface;
    final Color laneCircleColor = isDone ? _success : _primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Lane number circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: laneCircleColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'L$lane',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Athlete info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.athleteName,
                  style: const TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  'Lane $lane',
                  style: const TextStyle(color: _subtext, fontSize: 12),
                ),
              ],
            ),
          ),

          // Status: time / spinner / waiting icon
          if (isDone)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result.totalTime?.toStringAsFixed(3) ?? '--'} s',
                  style: const TextStyle(
                      color: _success,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                const Text('✓ Done',
                    style: TextStyle(color: _success, fontSize: 11)),
              ],
            )
          else if (isWaiting)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: _primary),
            )
          else
            const Icon(Icons.radio_button_unchecked,
                color: _subtext, size: 22),
        ],
      ),
    );
  }

  // ── Single athlete body (non-shuttle modes) ────────────────────────────────

  Widget _buildSingleBody(BuildContext context, TimingSessionState state) {
    final athlete = state.currentAthlete;
    final item = state.currentQueueItem;

    if (athlete == null || item == null) {
      return const Center(child: Text('Session complete.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Athlete card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _primaryLight,
                  child: Text(
                    athlete.fullName.isNotEmpty
                        ? athlete.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: _primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  athlete.fullName,
                  style: const TextStyle(
                      color: _text, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                if (athlete.team.isNotEmpty)
                  Text(athlete.team,
                      style: const TextStyle(color: _subtext, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Trial ${item.trialNumber} of ${state.trialsCount}',
                    style: const TextStyle(
                        color: _primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildPhaseCard(state),
          const SizedBox(height: 16),
          if (state.phase == RunTestPhase.result &&
              state.lastTrialResult != null)
            _buildResultCard(state),
        ],
      ),
    );
  }

  // ── Phase indicator card ───────────────────────────────────────────────────

  Widget _buildPhaseCard(TimingSessionState state) {
    final isWaiting = state.phase == RunTestPhase.waitingForResult;
    final isReArming = state.phase == RunTestPhase.reArming;
    final isActive = isWaiting || isReArming;

    Color cardColor = _surface;
    Color borderColor = _border;
    Color iconColor = _subtext;
    Color textColor = _subtext;

    if (isWaiting) {
      cardColor = _primaryLight;
      borderColor = _primary.withValues(alpha: 0.3);
      iconColor = _primary;
      textColor = _primary;
    } else if (isReArming) {
      cardColor = _warning.withValues(alpha: 0.08);
      borderColor = _warning.withValues(alpha: 0.4);
      iconColor = _warning;
      textColor = _warning;
    }

    String label;
    if (state.mode == 'shuttle' && isWaiting) {
      final done = state.shuttleBatchResults.length;
      final total = state.currentShuttleBatch.length;
      label = done == 0
          ? 'Waiting for results...'
          : '$done / $total lanes finished — waiting...';
    } else if (isWaiting) {
      label = 'Waiting for result...';
    } else if (isReArming) {
      label = 'False start — walk through gates '
          '(${state.registeredGatesCount} registered)';
    } else if (state.mode == 'shuttle' && state.phase == RunTestPhase.result) {
      label = 'All lanes done — tap Next to continue';
    } else {
      label = 'Ready — tap Start';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isActive)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: iconColor),
            )
          else
            Icon(Icons.sports_score, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result card (non-shuttle only) ─────────────────────────────────────────

  Widget _buildResultCard(TimingSessionState state) {
    final result = state.lastTrialResult!;
    final splits = result.splits;

    double cumulative = 0;
    final cumulativeList = splits.map((s) {
      cumulative += s;
      return cumulative;
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Text('Total Time',
                    style: TextStyle(color: _subtext, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '${result.totalTime?.toStringAsFixed(3) ?? '--'} s',
                  style: const TextStyle(
                      color: _success,
                      fontSize: 40,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (splits.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(children: const [
              Expanded(
                  flex: 2,
                  child: Text('Gate',
                      style: TextStyle(
                          color: _subtext,
                          fontSize: 11,
                          fontWeight: FontWeight.w600))),
              Expanded(
                  flex: 3,
                  child: Text('Split Time',
                      style: TextStyle(
                          color: _subtext,
                          fontSize: 11,
                          fontWeight: FontWeight.w600))),
              Expanded(
                  flex: 3,
                  child: Text('Cumulative',
                      style: TextStyle(
                          color: _subtext,
                          fontSize: 11,
                          fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 8),
            ...splits.asMap().entries.map((e) {
              final gateNum = e.key + 1;
              final splitTime = e.value;
              final cum = cumulativeList[e.key];
              final isLast = e.key == splits.length - 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isLast
                      ? _success.withValues(alpha: 0.12)
                      : _surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLast
                        ? _success.withValues(alpha: 0.4)
                        : _border,
                  ),
                ),
                child: Row(children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isLast ? _success : _primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$gateNum',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${splitTime.toStringAsFixed(3)} s',
                      style: TextStyle(
                          color: _text,
                          fontSize: 13,
                          fontWeight: isLast
                              ? FontWeight.w700
                              : FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${cum.toStringAsFixed(3)} s',
                      style: TextStyle(
                          color: isLast ? _success : _subtext,
                          fontSize: 13,
                          fontWeight: isLast
                              ? FontWeight.w700
                              : FontWeight.normal),
                    ),
                  ),
                ]),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context, TimingSessionState state) {
    final cubit = context.read<TimingSessionCubit>();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DEV ONLY: simulate result (non-shuttle only)
          if (kDebugMode &&
              state.mode != 'shuttle' &&
              state.phase == RunTestPhase.waitingForResult) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bolt, size: 16),
                label: const Text('Simulate Result (Dev)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9333EA),
                  side: const BorderSide(color: Color(0xFF9333EA)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                onPressed: cubit.simulateTrialResult,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Result phase: False Start + Next
          if (state.phase == RunTestPhase.result)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: cubit.falseStart,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _warning),
                      foregroundColor: _warning,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      state.mode == 'shuttle' ? 'False Start\n(Batch)' : 'False Start',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: cubit.acceptResult,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Next →'),
                  ),
                ),
              ],
            ),

          // Ready / Waiting / ReArming phase: Skip + Start
          if (state.phase != RunTestPhase.result)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.phase == RunTestPhase.reArming
                        ? null
                        : cubit.skipTrial,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      state.mode == 'shuttle' ? 'Skip Batch' : 'Skip',
                      style: const TextStyle(color: _subtext),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      state.phase == RunTestPhase.reArming
                          ? Icons.sensors
                          : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(
                      state.phase == RunTestPhase.waitingForResult
                          ? 'Waiting...'
                          : state.phase == RunTestPhase.reArming
                              ? 'Re-arming...'
                              : 'Start',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (state.phase == RunTestPhase.waitingForResult ||
                                  state.phase == RunTestPhase.reArming)
                              ? _border
                              : _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed:
                        (state.phase == RunTestPhase.waitingForResult ||
                                state.phase == RunTestPhase.reArming)
                            ? null
                            : cubit.sendStart,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Done screen ────────────────────────────────────────────────────────────

  Widget _buildDone(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: _success, size: 64),
          const SizedBox(height: 16),
          const Text('All trials complete!',
              style: TextStyle(
                  color: _text, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Tap below to view results.',
              style: TextStyle(color: _subtext, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                context.read<TimingSessionCubit>().goToStep(6),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('View Results'),
          ),
        ],
      ),
    );
  }
}
