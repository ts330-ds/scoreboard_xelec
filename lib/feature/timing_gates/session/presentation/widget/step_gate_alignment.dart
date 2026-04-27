import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // Only rebuild when structurally relevant fields change.
      // Gate distance values are handled locally in _SprintGateDistances —
      // so gateDistances content changes don't trigger a full screen rebuild.
      buildWhen: (prev, curr) =>
          prev.currentStep != curr.currentStep ||
          prev.registeredGatesCount != curr.registeredGatesCount ||
          prev.allGatesReady != curr.allGatesReady ||
          prev.gateSetupLog.length != curr.gateSetupLog.length ||
          prev.yoyoLaneStatuses != curr.yoyoLaneStatuses ||
          prev.gateDistances.length != curr.gateDistances.length,
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
                  ] else if (state.mode == 'linear' && state.subMode == 'sprint' &&
                      state.gateDistances.isNotEmpty) ...[
                    _SprintGateDistances(state: state),
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
    } else if (state.mode == 'linear' && state.subMode == 'sprint') {
      final reg = state.registeredGatesCount;
      title = reg > 0
          ? '$reg gate${reg == 1 ? '' : 's'} registered'
          : 'No gates registered';
      subtitle = reg >= 2
          ? 'Enter gate distances below, then tap Start Test'
          : reg == 1
              ? 'Walk through at least one more gate'
              : 'Walk through each gate to register it';
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

  // ── Can start test? ─────────────────────────────────────────────────────────

  bool _canStartTest(TimingSessionState state) {
    // Sprint: needs at least 2 physical gates — no bypass
    if (state.mode == 'linear' && state.subMode == 'sprint') {
      return state.registeredGatesCount >= 2;
    }
    // Shuttle: firmware may fire ALL_LANES_CONFIGURED without individual
    // gate-registered events — treat allGatesReady as sufficient
    if (state.mode == 'shuttle') {
      return state.allGatesReady || state.registeredGatesCount >= 1;
    }
    // 505 / ttest / other linear modes: require at least 1 gate as before
    return state.registeredGatesCount >= 1;
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
                // Sprint: needs 2+ gates; others: 1+ gate or allGatesReady.
                // allGatesReady covers the case where the firmware fires
                // ALL_LANES_CONFIGURED without individual gate-registered events
                // (shuttle firmware may not send per-gate confirmations).
                child: _canStartTest(state)
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: Text(
                          state.registeredGatesCount > 0
                              ? 'Start Test (${state.registeredGatesCount} gate${state.registeredGatesCount == 1 ? '' : 's'})'
                              : 'Start Test',
                        ),
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

// ── Sprint gate distance inputs ───────────────────────────────────────────────

class _SprintGateDistances extends StatefulWidget {
  final TimingSessionState state;
  const _SprintGateDistances({required this.state});

  @override
  State<_SprintGateDistances> createState() => _SprintGateDistancesState();
}

class _SprintGateDistancesState extends State<_SprintGateDistances> {
  static const _primary      = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text         = Color(0xFF1E2A3A);
  static const _subtext      = Color(0xFF6B7A8D);
  static const _border       = Color(0xFFDDE3EC);
  static const _success      = Color(0xFF16A34A);

  late List<TextEditingController> _controllers;
  // One debounce timer per gate — cubit call fires 400ms after last keystroke
  late List<Timer?> _debounceTimers;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.state.gateDistances);
  }

  // Total distance from protocol / custom field
  double get _totalDistance {
    if (widget.state.protocol == 'custom') {
      return widget.state.customDistance ?? 0.0;
    }
    final data = TimingSessionState.protocolData[widget.state.protocol];
    if (data != null) return (data['distance'] as int).toDouble();
    return 0.0;
  }

  // Current value of gate i (from text controller, fallback to state)
  double _currentVal(int i) {
    final text = _controllers[i].text;
    return double.tryParse(text) ?? widget.state.gateDistances[i];
  }

  @override
  void didUpdateWidget(_SprintGateDistances old) {
    super.didUpdateWidget(old);
    // Reinit if gate count changed (e.g. retry setup)
    if (old.state.gateDistances.length != widget.state.gateDistances.length) {
      _disposeControllers();
      _initControllers(widget.state.gateDistances);
    }
  }

  void _initControllers(List<double> distances) {
    _debounceTimers = List.filled(distances.length, null);
    _controllers = List.generate(distances.length, (i) {
      final val    = distances[i];
      final isAuto = (i == 0) || (i == distances.length - 1);
      final text   = isAuto
          ? val.toStringAsFixed(0)
          : (val > 0 ? val.toStringAsFixed(0) : '');
      // No addListener — onChanged in the TextField handles local setState.
      return TextEditingController(text: text);
    });
  }

  void _disposeControllers() {
    for (final t in _debounceTimers) {
      t?.cancel();
    }
    for (final c in _controllers) {
      c.dispose();
    }
  }

  /// Called on every keystroke:
  /// - setState immediately → live segment/remaining display (local only, fast)
  /// - cubit call debounced 400ms → avoids a state emit per keystroke
  void _onGateChanged(int index, String val, TimingSessionCubit cubit) {
    setState(() {}); // local rebuild only — no BlocBuilder involved
    _debounceTimers[index]?.cancel();
    _debounceTimers[index] = Timer(const Duration(milliseconds: 400), () {
      final d = double.tryParse(val);
      if (d != null) cubit.setGateDistance(index, d);
    });
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distances  = widget.state.gateDistances;
    final cubit      = context.read<TimingSessionCubit>();
    final totalDist  = _totalDistance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gate Distances',
                    style: TextStyle(
                        color: _text, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Enter segment distance between each gate',
                    style: TextStyle(color: _subtext, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Total distance badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Total: ${totalDist.toStringAsFixed(0)} m',
                style: const TextStyle(
                    color: _primary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Gate rows ─────────────────────────────────────────────────────
        ...List.generate(distances.length, (i) {
          final isMaster = i == 0;
          final isLast   = i == distances.length - 1;
          final isAuto   = isMaster || isLast;
          final badgeLabel = isMaster ? 'M' : 'G$i';

          // gateDistances stores RELATIVE distances:
          //   index 0 = Master (0, ignored)
          //   index i = distance from G[i-1] → G[i]
          // segDist = current field value (already a segment distance)
          final segDist = _currentVal(i);

          // Remaining = totalDist - sum of all entered segment distances so far
          double enteredSoFar = 0;
          for (int j = 1; j <= i; j++) {
            enteredSoFar += _currentVal(j);
          }
          final remaining = totalDist - enteredSoFar;
          final isError   = !isMaster && !isLast && enteredSoFar > totalDist;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isError
                      ? const Color(0xFFFEF2F2)
                      : isAuto
                          ? _primaryLight
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isError
                        ? const Color(0xFFDC2626).withValues(alpha: 0.4)
                        : isAuto
                            ? _primary.withValues(alpha: 0.3)
                            : _border,
                  ),
                ),
                child: Row(
                  children: [
                    // Badge
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isError
                            ? const Color(0xFFDC2626)
                            : isAuto
                                ? _primary
                                : _success,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          badgeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: isAuto
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMaster ? 'Master (Start)' : 'Finish gate',
                                  style: const TextStyle(
                                    color: _text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  isMaster
                                      ? '0 m (auto)'
                                      : () {
                                          // Compute actual last segment = total - sum of all middle segments
                                          double midSum = 0;
                                          for (int j = 1; j < distances.length - 1; j++) {
                                            midSum += _currentVal(j);
                                          }
                                          final lastSeg = (totalDist - midSum).clamp(0.0, double.infinity);
                                          return '${lastSeg.toStringAsFixed(1)} m (auto)';
                                        }(),
                                  style: const TextStyle(
                                      color: _subtext, fontSize: 12),
                                ),
                              ],
                            )
                          : TextFormField(
                              controller: _controllers[i],
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              decoration: InputDecoration(
                                hintText: i == 1
                                    ? 'M → G1 segment (0 = athlete starts at G1)'
                                    : 'G${i - 1} → G$i segment (m)',
                                hintStyle: const TextStyle(
                                    color: _subtext, fontSize: 12),
                                suffixText: 'm',
                                suffixStyle: const TextStyle(
                                    color: _subtext, fontSize: 13),
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: _border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: _border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _primary.withValues(alpha: 0.6),
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFDC2626)),
                                ),
                              ),
                              onChanged: (val) =>
                                _onGateChanged(i, val, cubit),
                            ),
                    ),
                  ],
                ),
              ),

              // ── Segment + Remaining info row ────────────────────────────
              if (!isMaster) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 54, top: 4, bottom: 8),
                  child: Row(
                    children: [
                      // Segment chip
                      if (i > 0 && !isMaster)
                        _infoChip(
                          icon: Icons.straighten,
                          label: segDist >= 0
                              ? 'Seg: ${segDist.toStringAsFixed(1)} m'
                              : 'Seg: —',
                          color: segDist >= 0 ? _subtext : const Color(0xFFDC2626),
                        ),
                      const SizedBox(width: 8),
                      // Remaining chip
                      if (!isLast)
                        _infoChip(
                          icon: Icons.flag_outlined,
                          label: isError
                              ? 'Exceeds total!'
                              : remaining == 0
                                  ? 'At finish'
                                  : '${remaining.toStringAsFixed(1)} m left',
                          color: isError
                              ? const Color(0xFFDC2626)
                              : remaining == 0
                                  ? _success
                                  : _primary,
                        ),
                      if (isLast)
                        _infoChip(
                          icon: Icons.check_circle_outline,
                          label: 'Finish ✓',
                          color: _success,
                        ),
                    ],
                  ),
                ),
              ] else
                const SizedBox(height: 4),
            ],
          );
        }),
      ],
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
