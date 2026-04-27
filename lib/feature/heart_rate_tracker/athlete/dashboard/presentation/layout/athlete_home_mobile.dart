import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class AthleteHomeMobile extends StatelessWidget {
  const AthleteHomeMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Dashboard',
      bodyBackground: AppColors.bg,
      appBarBackground: AppColors.primary,
      onSettingsPressed: () =>
          context.push(HeartTrackerPaths.heartBleSelectionScreen),
      settingsIcon: BlocBuilder<HeartBleCubit, HeartBleState>(
        buildWhen: (p, c) => p.isConnected != c.isConnected,
        builder: (context, state) => Icon(
          state.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
          color: state.isConnected ? AppColors.success : null,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push(HeartTrackerPaths.athleteNotification),
        ),
      ],
      body: BlocBuilder<HeartBleCubit, HeartBleState>(
        builder: (context, state) => SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroHeader(state: state),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: "Today's Activity"),
                      const SizedBox(height: 12),
                      _ActivityRow(state: state),
                      const SizedBox(height: 28),
                      const _SectionTitle(title: 'Health Vitals'),
                      const SizedBox(height: 12),
                      _VitalGrid(state: state),
                      const SizedBox(height: 28),
                      if (state.hasHistoryData) ...[
                        const _SectionTitle(title: 'Data Sync'),
                        const SizedBox(height: 12),
                        _HistorySyncCard(state: state),
                        const SizedBox(height: 28),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
    final name = prefs.getString(PrefKeys.userName) ?? 'Athlete';
    final role = prefs.getString(PrefKeys.userRole) ?? '';
    final token = prefs.getString(PrefKeys.userToken) ?? '';
    debugPrint("Token: $token");
    final connected = state.isConnected;
    final accent = connected ? AppColors.success : AppColors.primary;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
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
                  backgroundColor: Colors.white.withOpacity(0.2),
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
                                color: Colors.white.withOpacity(0.65),
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
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12)),
                        ]),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              connected && state.heartRate > 0
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
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12)),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                            connected && state.lastDevice.isNotEmpty
                                ? state.lastDevice
                                : 'Not Connected',
                            style: TextStyle(
                                color: connected ? Colors.white : Colors.white54,
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
                              color: accent.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              connected ? 'Live' : 'Offline',
                              style: TextStyle(
                                  color: connected
                                      ? const Color(0xFF80CBC4)
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
      ),
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
          color: color.withOpacity(0.2),
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
      const SizedBox(width: 12),
      _ActivityCard(
          icon: Icons.local_fire_department,
          value: '${state.calorie}',
          label: 'kcal',
          color: AppColors.actCalorie),
      const SizedBox(width: 12),
      _ActivityCard(
          icon: Icons.straighten,
          value: (state.distance / 1000).toStringAsFixed(1),
          label: 'km',
          color: AppColors.actDistance),
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
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
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
    final vitals = [
      _VitalData('SpO2', state.spo2 > 0 ? '${state.spo2}%' : '--',
          Icons.bloodtype, AppColors.vitalOxygen),
      _VitalData(
          'Blood Pressure',
          state.systolic > 0 ? '${state.systolic}/${state.diastolic}' : '--',
          Icons.speed,
          AppColors.vitalBP),
      _VitalData(
          'Body Temp',
          state.bodyTemp1 > 0 ? '${state.bodyTemp1.toStringAsFixed(1)}°C' : '--',
          Icons.thermostat,
          AppColors.vitalTemp),
      _VitalData('Stress', state.stressLevel > 0 ? '${state.stressLevel}' : '--',
          Icons.psychology, AppColors.vitalStress),
      _VitalData(
          'HRV (RMSSD)',
          state.hrv > 0 ? '${state.hrv.toStringAsFixed(1)} ms' : '--',
          Icons.monitor_heart_outlined,
          AppColors.primary),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2),
      itemCount: vitals.length,
      itemBuilder: (_, i) => _VitalTile(data: vitals[i]),
    );
  }
}

class _VitalData {
  final String label, value;
  final IconData icon;
  final Color color;
  const _VitalData(this.label, this.value, this.icon, this.color);
}

class _VitalTile extends StatelessWidget {
  final _VitalData data;
  const _VitalTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: data.color.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: data.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, color: data.color, size: 16),
          ),
          const Spacer(),
          Text(data.value,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(data.label,
              style:
                  const TextStyle(color: AppColors.subtext, fontSize: 11)),
        ],
      ),
    );
  }
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
            color: color.withOpacity(0.1),
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
