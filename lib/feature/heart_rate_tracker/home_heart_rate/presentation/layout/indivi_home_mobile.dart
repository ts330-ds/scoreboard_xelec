import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';

class IndiviHomeMobile extends StatelessWidget {
  const IndiviHomeMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Health Dashboard',
      onSettingsPressed: () =>
          context.push(HeartTrackerPaths.heartBleSelectionScreen),
      settingsIcon: BlocBuilder<HeartBleCubit, HeartBleState>(
        buildWhen: (p, c) => p.isConnected != c.isConnected,
        builder: (context, state) => Icon(
          state.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
          color: state.isConnected ? AppColors.success : null,
        ),
      ),
      bodyBackground: AppColors.bg,
      appBarBackground: AppColors.primary,
      body: BlocBuilder<HeartBleCubit, HeartBleState>(
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DeviceCard(
                    state: state,
                    onDisconnect: () => context.read<HeartBleCubit>().disconnect(),
                  ),
                  const SizedBox(height: 24),

                  _ActivityRow(state: state),
                  const SizedBox(height: 24),

                  const Text(
                    "Health Vitals",
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _VitalGrid(state: state),
                  const SizedBox(height: 24),

                  if (state.hasHistoryData) ...[
                    const Text(
                      "Data Sync Status",
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HistorySyncCard(state: state),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Activity Row ───────────────────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  final HeartBleState state;
  const _ActivityRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _activityItem(Icons.directions_walk, "${state.steps}", "Steps", AppColors.actSteps),
        _activityItem(Icons.local_fire_department, "${state.calorie}", "kcal", AppColors.actCalorie),
        _activityItem(Icons.straighten, (state.distance / 1000).toStringAsFixed(1), "km", AppColors.actDistance),
      ],
    );
  }

  Widget _activityItem(IconData icon, String val, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(val, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(color: AppColors.subtext, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Vital Grid ──────────────────────────────────────────────────────────────
class _VitalGrid extends StatelessWidget {
  final HeartBleState state;
  const _VitalGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _VitalTile(
          label: "Oxygen (SpO2)",
          value: state.spo2 > 0 ? "${state.spo2}%" : "--",
          icon: Icons.bloodtype,
          color: AppColors.vitalOxygen,
        ),
        _VitalTile(
          label: "Blood Pressure",
          value: state.systolic > 0 ? "${state.systolic}/${state.diastolic}" : "--",
          icon: Icons.speed,
          color: AppColors.vitalBP,
        ),
        _VitalTile(
          label: "Body Temp",
          value: state.bodyTemp1 > 0 ? "${state.bodyTemp1.toStringAsFixed(1)}°C" : "--",
          icon: Icons.thermostat,
          color: AppColors.vitalTemp,
        ),
        _VitalTile(
          label: "Stress Level",
          value: state.stressLevel > 0 ? "${state.stressLevel}" : "--",
          icon: Icons.psychology,
          color: AppColors.vitalStress,
        ),
      ],
    );
  }
}

class _VitalTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _VitalTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.subtext, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── History Sync Card ───────────────────────────────────────────────────────
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
      child: Column(
        children: [
          _syncRow("Heart Rate History", state.historyHrData.length),
          const Divider(color: AppColors.borderLight, height: 20),
          _syncRow("Sleep Records", state.historySleep.length),
          const Divider(color: AppColors.borderLight, height: 20),
          _syncRow("Step History", state.historyStepData.length),
        ],
      ),
    );
  }

  Widget _syncRow(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppColors.subtext, fontSize: 13)),
        Text("$count logs", style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Device Card ────────────────────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final HeartBleState state;
  final VoidCallback onDisconnect;

  const _DeviceCard({required this.state, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    final connected = state.isConnected;
    final accentColor = connected ? AppColors.success : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(connected && state.lastDevice.isNotEmpty ? state.lastDevice : 'No Device',
                        style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(state.status, style: const TextStyle(color: AppColors.subtext, fontSize: 11)),
                  ],
                ),
              ),
              if (connected)
                GestureDetector(
                  onTap: onDisconnect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: const Text('Disconnect', style: TextStyle(color: AppColors.error, fontSize: 11)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _Metric(icon: Icons.favorite, iconColor: AppColors.heartRed,
                  value: connected && state.heartRate > 0 ? '${state.heartRate}' : '--', unit: 'BPM', label: 'Heart Rate', active: connected)),
              Container(width: 1, height: 40, color: AppColors.borderLight),
              Expanded(child: _Metric(icon: Icons.battery_charging_full, iconColor: AppColors.success,
                  value: connected && state.battery > 0 ? '${state.battery}' : '--', unit: '%', label: 'Battery', active: connected)),
            ],
          ),
          const SizedBox(height: 16),
          _SignalMetric(bars: connected ? state.signalBars : 0, rssi: connected ? state.connectedRssi : 0, active: connected),
        ],
      ),
    );
  }
}

// ── Metric Helper ───────────────────────────────────────────────────────────
class _Metric extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value, unit, label;
  final bool active;
  const _Metric({required this.icon, required this.iconColor, required this.value, required this.unit, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: active ? iconColor : iconColor.withOpacity(0.3), size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.subtext, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: active ? AppColors.text : AppColors.textHint, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Signal Metric Helper ───────────────────────────────────────────────────
class _SignalMetric extends StatelessWidget {
  final int bars, rssi;
  final bool active;
  const _SignalMetric({required this.bars, required this.rssi, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Signal: ", style: TextStyle(color: AppColors.subtext, fontSize: 11)),
        ...List.generate(3, (i) => Container(
          width: 4, height: 8 + (i * 4), margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(color: active && bars > i ? AppColors.success : AppColors.borderLight, borderRadius: BorderRadius.circular(1)),
        )),
        const SizedBox(width: 8),
        Text(active && rssi != 0 ? "$rssi dBm" : "--", style: const TextStyle(color: AppColors.subtext, fontSize: 10)),
      ],
    );
  }
}
