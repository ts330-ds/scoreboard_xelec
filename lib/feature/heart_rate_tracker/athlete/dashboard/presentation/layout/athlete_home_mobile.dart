import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/core/widgets/ecg_waveform.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/health_monitor/presentation/cubit/athlete_health_monitor_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/profile/presentation/cubit/athlete_profile_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/profile/presentation/cubit/athlete_profile_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

const _kAthleteGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
);

class AthleteHomeMobile extends StatelessWidget {
  const AthleteHomeMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return _AthleteHomeView();
  }
}

class _AthleteHomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ));
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _kAthleteGradient),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () =>
                context.push(HeartTrackerPaths.athleteNotification),
          ),
          BlocBuilder<HeartBleCubit, HeartBleState>(
            buildWhen: (p, c) =>
                p.isConnected != c.isConnected ||
                p.isReconnecting != c.isReconnecting,
            builder: (context, state) => IconButton(
              icon: Icon(
                state.isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth,
                color: state.isConnected ? AppColors.success : Colors.white,
              ),
              onPressed: () =>
                  context.push(HeartTrackerPaths.heartBleSelectionScreen),
            ),
          ),
        ],
      ),
      body: BlocBuilder<HeartBleCubit, HeartBleState>(
        builder: (context, bleState) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroHeader(state: bleState),
              _HealthMonitorStatusBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: "Today's Activity"),
                    const SizedBox(height: 12),
                    _ActivityRow(state: bleState),
                    const SizedBox(height: 28),
                    const _SectionTitle(title: 'Health Vitals'),
                    const SizedBox(height: 12),
                    _VitalGrid(state: bleState),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Header ──────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final HeartBleState state;
  const _HeroHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final prefs = sl<SharedPreferences>();
    final role = prefs.getString(PrefKeys.userRole) ?? '';
    // Read name from AthleteProfileCubit so it updates when profile is edited
    final profileState = context.watch<AthleteProfileCubit>().state;
    final name = profileState.status == AthleteProfileStatus.loaded
        ? (profileState.profile?.name ?? prefs.getString(PrefKeys.userName) ?? 'Athlete')
        : (prefs.getString(PrefKeys.userName) ?? 'Athlete');
    final connected = state.isConnected;
    final hasData = state.isConnected || state.isReconnecting;
    final accent = connected ? AppColors.success : AppColors.primary;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: _kAthleteGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting row
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'A',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hey, $name 👋',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      if (role.isNotEmpty)
                        Text(role.toUpperCase(),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 11,
                                letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Heart rate + device card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  // BPM
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.favorite,
                              color: connected
                                  ? const Color(0xFFEF9A9A)
                                  : Colors.white38,
                              size: 16),
                          const SizedBox(width: 6),
                          Text('Heart Rate',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12)),
                        ]),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              state.heartRate > 0
                                  ? '${state.heartRate}'
                                  : '--',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  height: 1),
                            ),
                            const SizedBox(width: 4),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text('BPM',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                      width: 1, height: 56, color: Colors.white24),

                  // Device status
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(
                              connected
                                  ? Icons.bluetooth_connected
                                  : Icons.bluetooth_disabled,
                              color: connected
                                  ? const Color(0xFF80CBC4)
                                  : Colors.white38,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text('Device',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12)),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                            hasData
                                ? (state.lastDevice.isNotEmpty
                                    ? state.lastDevice
                                    : 'Connected')
                                : 'Not Connected',
                            style: TextStyle(
                                color: hasData ? Colors.white : Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              connected
                                  ? 'Live'
                                  : state.isReconnecting
                                      ? 'Reconnecting'
                                      : 'Offline',
                              style: TextStyle(
                                  color: connected
                                      ? const Color(0xFF80CBC4)
                                      : state.isReconnecting
                                          ? Colors.orange.shade300
                                          : Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Battery + signal
                  if (connected)
                    Column(
                      children: [
                        _BatteryChip(battery: state.battery),
                        const SizedBox(height: 8),
                        _SignalDots(bars: state.signalBars),
                      ],
                    ),
                ],
              ),
            ),

            if (connected) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => context
                      .read<HeartBleCubit>()
                      .disconnect(),
                  icon: const Icon(Icons.link_off,
                      size: 14, color: Colors.white60),
                  label: const Text('Disconnect',
                      style:
                          TextStyle(color: Colors.white60, fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
        ), // SafeArea
      ),
    );
  }
}

// ── Health Monitor Status Banner ─────────────────────────────────────────────
class _HealthMonitorStatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteHealthMonitorCubit, HealthMonitorState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.reconnectAttempt != curr.reconnectAttempt ||
          prev.isReconnectExhausted != curr.isReconnectExhausted ||
          prev.isAuthFailure != curr.isAuthFailure,
      builder: (context, state) {
        final status = state.status;
        if (status == HealthMonitorStatus.idle) return const SizedBox.shrink();

        // Auth fail aur exhausted dono error case par fall karte hain.
        final (Color bg, Color fg, IconData icon, String label) = switch (status) {
          HealthMonitorStatus.connecting => (
              Colors.orange.shade50,
              Colors.orange.shade700,
              Icons.sync,
              'Connecting to health monitor...'
            ),
          HealthMonitorStatus.reconnecting => (
              Colors.orange.shade50,
              Colors.orange.shade700,
              Icons.sync_problem,
              state.reconnectAttempt > 0
                  ? 'Reconnecting health monitor (#${state.reconnectAttempt})...'
                  : 'Reconnecting health monitor...'
            ),
          HealthMonitorStatus.monitoring => (
              const Color(0xFFE8F5E9),
              const Color(0xFF2E7D32),
              Icons.monitor_heart,
              'Live Monitoring Active'
            ),
          HealthMonitorStatus.error => (
              const Color(0xFFFFEBEE),
              AppColors.error,
              Icons.wifi_off_rounded,
              state.isAuthFailure
                  ? 'Session expired — please log in again'
                  : state.isReconnectExhausted
                      ? 'Cannot reach server — tap Retry'
                      : 'Health Monitor Connection Error'
            ),
          HealthMonitorStatus.idle => (
              Colors.transparent,
              Colors.transparent,
              Icons.circle,
              ''
            ),
        };

        final showRetry = state.isReconnectExhausted && !state.isAuthFailure;
        final showSpinner = status == HealthMonitorStatus.connecting ||
            status == HealthMonitorStatus.reconnecting;

        return Container(
          width: double.infinity,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (showSpinner)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              else
                Icon(icon, size: 14, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      color: fg, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (showRetry)
                InkWell(
                  onTap: () => context
                      .read<AthleteHealthMonitorCubit>()
                      .retryConnectionManually(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: fg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
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

class _BatteryChip extends StatelessWidget {
  final int battery;
  const _BatteryChip({required this.battery});

  @override
  Widget build(BuildContext context) {
    final color = battery > 50
        ? const Color(0xFF80CBC4)
        : battery > 20
            ? const Color(0xFFFFCC80)
            : const Color(0xFFEF9A9A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.battery_charging_full, size: 12, color: color),
        const SizedBox(width: 3),
        Text('$battery%',
            style:
                TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _SignalDots extends StatelessWidget {
  final int bars;
  const _SignalDots({required this.bars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: bars > i ? const Color(0xFF80CBC4) : Colors.white24,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Section Title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700));
  }
}

// ── Activity Row ─────────────────────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  final HeartBleState state;
  const _ActivityRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _ActivityCard(
          icon: Icons.directions_walk,
          value: '${state.steps}',
          label: 'Steps',
          color: AppColors.actSteps),
    ]);
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _ActivityCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          Text(label,
              style:
                  const TextStyle(color: AppColors.subtext, fontSize: 11)),
        ]),
      ),
    );
  }
}

// ── Vital Grid ────────────────────────────────────────────────────────────────
class _VitalGrid extends StatelessWidget {
  final HeartBleState state;
  const _VitalGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final hrvValue =
        state.hrv > 0 ? '${state.hrv.toStringAsFixed(1)} ms' : '--';

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Upar: HRV reading
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.monitor_heart_outlined,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HRV (RMSSD)',
                        style: TextStyle(
                            color: AppColors.subtext, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(hrvValue,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 11, color: AppColors.primary.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          // ── Neeche: live ECG-style waveform (sirf heart rate se driven)
          EcgWaveform(
            bpm: state.heartRate,
            active: state.heartRate > 0,
            height: 80,
            lineColor: AppColors.heartRed,
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () => context.push(HeartTrackerPaths.athleteHrvDetail),
      child: card,
    );
  }
}

// ── Sleep Card ───────────────────────────────────────────────────────────────
class _SleepCard extends StatelessWidget {
  final HeartBleState state;
  const _SleepCard({required this.state});

  static const _deepColor = Color(0xFF5C6BC0);
  static const _lightColor = Color(0xFF80CBC4);
  static const _awakeColor = Color(0xFFEF9A9A);

  ({int totalMin, int deepMin, int lightMin, int awakeMin, int utc})? _parseLast() {
    if (state.historySleep.isEmpty) return null;
    // pick record with highest utc (most recent)
    final rec = state.historySleep.reduce((a, b) =>
        ((a['utc'] as num?)?.toInt() ?? 0) >= ((b['utc'] as num?)?.toInt() ?? 0) ? a : b);
    final utc = (rec['utc'] as num?)?.toInt() ?? 0;
    final raw = rec['actions'];
    // safe parse: platform channel may send num instead of int
    final actions = raw is List
        ? raw.map((e) => (e as num?)?.toInt() ?? 0).toList()
        : <int>[];
    if (actions.isEmpty) return null;
    final deep = actions.where((a) => a >= 2).length;   // 2=deep, 3=REM
    final light = actions.where((a) => a == 1).length;
    final awake = actions.where((a) => a == 0).length;
    final total = actions.length;                        // full session duration
    return (totalMin: total, deepMin: deep, lightMin: light, awakeMin: awake, utc: utc);
  }

  String _fmt(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _quality(int deepMin, int sleepMin) {
    if (sleepMin == 0) return '--';
    final pct = deepMin / sleepMin;
    if (pct >= 0.25) return 'Excellent';
    if (pct >= 0.15) return 'Good';
    if (pct >= 0.08) return 'Fair';
    return 'Light';
  }

  Color _qualityColor(int deepMin, int sleepMin) {
    if (sleepMin == 0) return AppColors.subtext;
    final pct = deepMin / sleepMin;
    if (pct >= 0.25) return AppColors.success;
    if (pct >= 0.15) return const Color(0xFF26A69A);
    if (pct >= 0.08) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final data = _parseLast();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: _deepColor.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: data == null ? _emptyState() : _dataView(data),
    );
  }

  Widget _emptyState() => Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: _deepColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.bedtime_outlined, color: _deepColor, size: 22),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last Night Sleep',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('Sync device from History tab to see sleep data',
                  style: TextStyle(color: AppColors.subtext, fontSize: 12)),
            ],
          ),
        ),
      ]);

  Widget _dataView(
      ({int totalMin, int deepMin, int lightMin, int awakeMin, int utc}) d) {
    final sleepMin = d.deepMin + d.lightMin;
    final quality = _quality(d.deepMin, sleepMin);
    final qColor = _qualityColor(d.deepMin, sleepMin);
    final deepFrac = d.totalMin > 0 ? d.deepMin / d.totalMin : 0.0;
    final lightFrac = d.totalMin > 0 ? d.lightMin / d.totalMin : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _deepColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.bedtime_outlined, color: _deepColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Last Night Sleep',
                    style: TextStyle(
                        color: AppColors.subtext, fontSize: 12)),
                Text(_fmt(d.totalMin),
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: qColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(quality,
                style: TextStyle(
                    color: qColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ]),

        const SizedBox(height: 16),

        // Sleep stage bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(children: [
            Flexible(
                flex: (deepFrac * 100).round(),
                child: Container(height: 10, color: _deepColor)),
            Flexible(
                flex: (lightFrac * 100).round(),
                child: Container(height: 10, color: _lightColor)),
            Flexible(
                flex: ((1 - deepFrac - lightFrac) * 100).round().clamp(0, 100),
                child: Container(height: 10, color: _awakeColor.withValues(alpha: 0.3))),
          ]),
        ),

        const SizedBox(height: 12),

        // Stage legend
        Row(children: [
          _legend(_deepColor, 'Deep', _fmt(d.deepMin)),
          const SizedBox(width: 16),
          _legend(_lightColor, 'Light', _fmt(d.lightMin)),
          const SizedBox(width: 16),
          _legend(_awakeColor, 'Awake', _fmt(d.awakeMin)),
        ]),
      ],
    );
  }

  Widget _legend(Color color, String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.subtext, fontSize: 10)),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      );
}

// ── History Sync Card ────────────────────────────────────────────────────────
class _HistorySyncCard extends StatelessWidget {
  final HeartBleState state;
  const _HistorySyncCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        _row(Icons.favorite_border, 'Heart Rate History',
            state.historyHrData.length, AppColors.heartRed),
        const Divider(color: AppColors.borderLight, height: 24),
        _row(Icons.bedtime_outlined, 'Sleep Records',
            state.historySleep.length, AppColors.vitalStress),
        const Divider(color: AppColors.borderLight, height: 24),
        _row(Icons.directions_walk_outlined, 'Step History',
            state.historyStepData.length, AppColors.actSteps),
      ]),
    );
  }

  Widget _row(IconData icon, String title, int count, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 15),
      ),
      const SizedBox(width: 12),
      Expanded(
          child: Text(title,
              style:
                  const TextStyle(color: AppColors.subtext, fontSize: 13))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(20)),
        child: Text('$count logs',
            style: const TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}
