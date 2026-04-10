import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_state.dart';

class StepGateAlignment extends StatelessWidget {
  const StepGateAlignment({super.key});

  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _border = Color(0xFFDDE3EC);
  static const _success = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimingSessionCubit, TimingSessionState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildStatusCard(state),
                  const SizedBox(height: 20),
                  if (state.mode == 'yoyo') ...[
                    _buildYoyoGateGrid(state),
                    if (state.gateSetupLog.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildLog(state),
                    ],
                  ] else if (state.gateSetupLog.isNotEmpty)
                    _buildLog(state)
                  else
                    _buildInstructions(),
                ],
              ),
            ),
            _buildFooter(context, state),
          ],
        );
      },
    );
  }

  // ── Status card ─────────────────────────────────────────────────────────────

  Widget _buildStatusCard(TimingSessionState state) {
    final ready = state.registeredGatesCount > 0;

    final String title;
    final String subtitle;

    if (state.mode == 'yoyo') {
      final completedLanes = state.yoyoLaneStatuses.where((l) => l.setupComplete).length;
      title = ready
          ? 'All YOYO Gates Ready'
          : '${state.registeredGatesCount} / ${state.yoyoNumLanes * 2} gates registered';
      subtitle = ready
          ? 'Tap Start Test to begin'
          : '$completedLanes / ${state.yoyoNumLanes} lanes fully configured';
    } else {
      final reg = state.registeredGatesCount;
      title = reg > 0
          ? '$reg gate${reg == 1 ? '' : 's'} registered'
          : 'No gates registered';
      subtitle = reg > 0
          ? 'You can start the test or walk through more gates'
          : 'Walk through each gate to register it';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ready ? _success.withValues(alpha: 0.4) : _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ready ? _success.withValues(alpha: 0.1) : _primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ready ? Icons.check_circle : Icons.sensors,
              color: ready ? _success : _primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ready ? _success : _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: _subtext, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── YOYO: per-lane gate grid ─────────────────────────────────────────────────

  Widget _buildYoyoGateGrid(TimingSessionState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gate Registration',
          style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'For each lane: trigger FINISH gate first, then TURN gate',
          style: TextStyle(color: _subtext, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...List.generate(state.yoyoNumLanes, (i) {
          final laneStatus = i < state.yoyoLaneStatuses.length
              ? state.yoyoLaneStatuses[i]
              : YoYoLaneStatus(laneNumber: i + 1);
          return _buildYoyoLaneSetupCard(laneStatus);
        }),
      ],
    );
  }

  Widget _buildYoyoLaneSetupCard(YoYoLaneStatus lane) {
    final complete = lane.setupComplete;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: complete ? _success.withValues(alpha: 0.05) : _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: complete ? _success.withValues(alpha: 0.4) : _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: complete ? _success : _primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'L${lane.laneNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Lane ${lane.laneNumber}',
                style: TextStyle(
                  color: complete ? _success : _text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (complete)
                const Icon(Icons.check_circle, color: _success, size: 18)
              else
                Text(
                  '${(lane.finishGateOk ? 1 : 0) + (lane.turnGateOk ? 1 : 0)} / 2',
                  style: const TextStyle(color: _subtext, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildGateChip(
                label: 'Finish (ID ${(lane.laneNumber - 1) * 2 + 1})',
                ok: lane.finishGateOk,
                icon: Icons.flag_outlined,
              ),
              const SizedBox(width: 8),
              _buildGateChip(
                label: 'Turn (ID ${(lane.laneNumber - 1) * 2 + 2})',
                ok: lane.turnGateOk,
                icon: Icons.turn_right,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGateChip({required String label, required bool ok, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ok ? _success.withValues(alpha: 0.08) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ok ? _success.withValues(alpha: 0.4) : _border),
        ),
        child: Row(
          children: [
            Icon(ok ? Icons.sensors : icon, size: 13, color: ok ? _success : _subtext),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ok ? _success : _subtext,
                  fontSize: 11,
                  fontWeight: ok ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Log (console-style) ──────────────────────────────────────────────────────

  Widget _buildLog(TimingSessionState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: state.gateSetupLog
            .map((line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    line,
                    style: const TextStyle(
                      color: Color(0xFF86EFAC),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Instructions (non-YOYO, no log yet) ─────────────────────────────────────

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withValues(alpha: 0.2)),
      ),
      child: const Text(
        '1. Place gates physically on ground\n'
        '2. Tap "Setup Gates" below\n'
        '3. Walk through each gate in order — auto-registers\n'
        '4. Wait for "All Gates Ready" confirmation',
        style: TextStyle(color: _primary, fontSize: 13, height: 1.6),
      ),
    );
  }

  // ── Setup Gates button ──────────────────────────────────────────────────────

  Widget _buildSetupGatesButton(
    BuildContext context,
    TimingSessionState state,
    TimingSessionCubit cubit,
  ) {
    final setupStarted = state.gateSetupLog.isNotEmpty;

    if (!setupStarted) {
      // ── Not started yet → show "Setup Gates" button ──
      return ElevatedButton.icon(
        icon: const Icon(Icons.sensors, size: 18),
        label: const Text('Setup Gates'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => cubit.beginGateSetup(),
      );
    }

    // ── Setup in progress → show spinner + "Retry" button ──
    return Column(
      children: [
        // Status row: spinner + text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Setting up… (${state.registeredGatesCount} / ${state.expectedGatesCount} gates)',
              style: const TextStyle(color: _subtext, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Retry button — user can tap to re-send setup command
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry Setup'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              cubit.resetGates();
              cubit.beginGateSetup();
            },
          ),
        ),
      ],
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────

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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    cubit.resetGates();
                    cubit.prevStep();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Back', style: TextStyle(color: _text)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                // 1+ gate registered → "Start Test" enabled
                // 0 gates → "Setup Gates" or "Setting up..."
                child: state.registeredGatesCount > 0
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text('Start Test (${state.registeredGatesCount} gate${state.registeredGatesCount == 1 ? '' : 's'})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => cubit.startTest(),
                      )
                    : _buildSetupGatesButton(context, state, cubit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
