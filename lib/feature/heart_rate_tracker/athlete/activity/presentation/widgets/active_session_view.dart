import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/core/widgets/ecg_waveform.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'activity_constants.dart';

class ActiveSessionView extends StatelessWidget {
  final AthleteActivityState state;
  const ActiveSessionView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final session = state.activeSession;
    if (session == null) return const SizedBox.shrink();
    final type = typeFor(session.activityType);
    final bleState = context.watch<HeartBleCubit>().state;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Socket / Reconnect banner (sirf jab kuch dikhane layak ho)
          if (state.isSessionActive &&
              (state.isSocketReconnecting ||
                  state.isReconnectExhausted ||
                  state.isAuthFailure))
            const _SessionReconnectBanner(),

          // ── BLE disconnect banner — band off / out of range. Session rukti
          // nahi (band wapas aate hi resume), par athlete ko batao ki abhi HR
          // capture nahi ho raha taaki wo band on/paas kar sake.
          if (state.isSessionActive && !bleState.isConnected)
            const _BleDisconnectBanner(),

          // ── Activity Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: type.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: type.color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type.icon, color: type.color, size: 18),
                const SizedBox(width: 8),
                Text(type.name,
                    style: TextStyle(
                        color: type.color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Compact recording timer (no target → no progress ring)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _RecordingDot(),
                const SizedBox(width: 12),
                Text(
                  AthleteActivityCubit.formatSeconds(state.elapsedSeconds),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Live Stats
          Row(
            children: [
              LiveStatCard(
                icon: Icons.favorite,
                label: 'Heart Rate',
                value: bleState.heartRate > 0
                    ? '${bleState.heartRate}'
                    : '--',
                unit: 'bpm',
                color: AppColors.heartRed,
              ),
              const SizedBox(width: 14),
              LiveStatCard(
                icon: Icons.show_chart,
                label: 'Avg HR',
                value: session.avgHeartRate > 0
                    ? '${session.avgHeartRate}'
                    : '--',
                unit: 'bpm',
                color: AppColors.vitalBP,
              ),
              const SizedBox(width: 14),
              LiveStatCard(
                icon: Icons.trending_up,
                label: 'Max HR',
                value: session.maxHeartRate > 0
                    ? '${session.maxHeartRate}'
                    : '--',
                unit: 'bpm',
                color: AppColors.warning,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── HRV Row
          Row(
            children: [
              LiveStatCard(
                icon: Icons.monitor_heart_outlined,
                label: 'HRV (RMSSD)',
                value: bleState.hrv > 0
                    ? bleState.hrv.toStringAsFixed(1)
                    : '--',
                unit: 'ms',
                color: AppColors.vitalStress,
              ),
              const SizedBox(width: 14),
              LiveStatCard(
                icon: Icons.timeline,
                label: 'Last RR',
                value: bleState.rrIntervals.isNotEmpty
                    ? '${bleState.rrIntervals.last}'
                    : '--',
                unit: 'ms',
                color: AppColors.primary,
              ),
              const SizedBox(width: 14),
              LiveStatCard(
                icon: Icons.format_list_numbered,
                label: 'RR Count',
                value: bleState.rrIntervals.isNotEmpty
                    ? '${bleState.rrIntervals.length}'
                    : '--',
                unit: 'beats',
                color: AppColors.success,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Live ECG-style waveform (sirf heart rate se driven)
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  size: 16, color: AppColors.heartRed),
              const SizedBox(width: 6),
              Text('Live Monitor',
                  style: TextStyle(
                      color: AppColors.subtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          EcgWaveform(
            bpm: bleState.heartRate,
            active: state.isSessionActive && bleState.heartRate > 0,
            height: 110,
            lineColor: AppColors.heartRed,
          ),

          const SizedBox(height: 16),

          // ── Location
          if (session.location.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.location,
                      style: const TextStyle(
                          color: AppColors.subtext, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // ── HR Samples count
          if (session.heartRateSamples.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${session.heartRateSamples.length} heart rate readings recorded',
                style:
                    const TextStyle(color: AppColors.subtext, fontSize: 12),
              ),
            ),

          // ── Stop Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: state.isStoppingSession
                  ? null
                  : () => context
                      .read<AthleteActivityCubit>()
                      .requestStopSession(),
              icon: state.isStoppingSession
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.stop_circle_outlined),
              label: Text(
                state.isStoppingSession ? 'Stopping...' : 'Stop Session',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.error.withOpacity(0.6),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
      ),
    );
  }
}

// ── Live Stat Card ────────────────────────────────────────────────────────────
class LiveStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, unit;
  final Color color;

  const LiveStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            Text(unit,
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 10)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.subtext, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Recording Dot ─────────────────────────────────────────────────────────────
// Timer ke aage pulsing red dot — "live recording" ka visual cue (target-based
// progress ring ki jagah, kyunki session duration fixed nahi hoti).
class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.3).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Session Reconnect Banner ──────────────────────────────────────────────────
// Active session ke time agar socket drop ho jaye to athlete ko visible
// feedback do — silently background me struggle nahi.
class _SessionReconnectBanner extends StatelessWidget {
  const _SessionReconnectBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteActivityCubit, AthleteActivityState>(
      buildWhen: (prev, curr) =>
          prev.isSocketReconnecting != curr.isSocketReconnecting ||
          prev.isReconnectExhausted != curr.isReconnectExhausted ||
          prev.isAuthFailure != curr.isAuthFailure ||
          prev.reconnectAttempt != curr.reconnectAttempt,
      builder: (context, state) {
        if (!(state.isSocketReconnecting ||
            state.isReconnectExhausted ||
            state.isAuthFailure)) {
          return const SizedBox.shrink();
        }

        final Color color;
        final IconData icon;
        final String label;
        final bool showSpinner;
        final bool showRetry;

        if (state.isAuthFailure) {
          color = AppColors.error;
          icon = Icons.lock_outline;
          label = 'Session expired — please log in again';
          showSpinner = false;
          showRetry = false;
        } else if (state.isReconnectExhausted) {
          color = AppColors.error;
          icon = Icons.wifi_off_rounded;
          label = 'Cannot reach server. Data is not being saved.';
          showSpinner = false;
          showRetry = true;
        } else {
          color = Colors.orange.shade700;
          icon = Icons.sync;
          label = state.reconnectAttempt > 0
              ? 'Reconnecting (#${state.reconnectAttempt})...'
              : 'Reconnecting...';
          showSpinner = true;
          showRetry = false;
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            border: Border.all(color: color.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (showSpinner)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color),
                )
              else
                Icon(icon, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showRetry)
                InkWell(
                  onTap: () => context
                      .read<AthleteActivityCubit>()
                      .retryConnectionManually(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── BLE Disconnect Banner ─────────────────────────────────────────────────────
// Session ke beech band off / out-of-range ho jaaye to athlete ko visible
// feedback do. Session rukti nahi — band wapas aate hi HR resume ho jaata hai
// aur reading band ki apni memory me bhi safe rehti hai (upload pe mil jaati).
class _BleDisconnectBanner extends StatelessWidget {
  const _BleDisconnectBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HeartBleCubit, HeartBleState>(
      buildWhen: (prev, curr) => prev.isConnected != curr.isConnected,
      builder: (context, bleState) {
        if (bleState.isConnected) return const SizedBox.shrink();

        final color = Colors.orange.shade700;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            border: Border.all(color: color.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Device disconnected — reconnecting…',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

