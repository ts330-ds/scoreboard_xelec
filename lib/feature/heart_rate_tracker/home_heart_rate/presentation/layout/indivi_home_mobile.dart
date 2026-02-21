import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';

class IndiviHomeMobile extends StatelessWidget {
  const IndiviHomeMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Home',
      onSettingsPressed: () =>
          context.push(HeartTrackerPaths.heartBleSelectionScreen),
      settingsIcon: BlocBuilder<HeartBleCubit, HeartBleState>(
        buildWhen: (p, c) => p.isConnected != c.isConnected,
        builder: (context, state) => Icon(
          state.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
          color: state.isConnected ? const Color(0xFF66BB6A) : null,
        ),
      ),
      bodyBackground: const Color(0xFF0A0E1A),
      body: BlocBuilder<HeartBleCubit, HeartBleState>(
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Single device card ───────────────────────────────
                  _DeviceCard(
                    state: state,
                    onDisconnect: () =>
                        context.read<HeartBleCubit>().disconnect(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Unified Device Card ─────────────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final HeartBleState state;
  final VoidCallback onDisconnect;

  const _DeviceCard({required this.state, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    final connected = state.isConnected;
    final accentColor =
        connected ? const Color(0xFF66BB6A) : const Color(0xFF4A90E2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: device name + status dot + disconnect button ────
          Row(
            children: [
              // BT icon
              Icon(
                connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),

              // Device name / status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connected && state.lastDevice.isNotEmpty
                          ? state.lastDevice
                          : 'No Device',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      state.status,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Live dot
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.6),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

              // Small disconnect button — only when connected
              if (connected)
                GestureDetector(
                  onTap: onDisconnect,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFEF5350).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            const Color(0xFFEF5350).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth_disabled,
                            color: Color(0xFFEF5350), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Disconnect',
                          style: TextStyle(
                            color: Color(0xFFEF5350),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 20),

          // ── Bottom row: heart rate  |  battery ──────────────────────
          Row(
            children: [
              // Heart Rate
              Expanded(
                child: _Metric(
                  icon: Icons.favorite,
                  iconColor: const Color(0xFFEF5350),
                  value: connected && state.heartRate > 0
                      ? '${state.heartRate}'
                      : '--',
                  unit: 'BPM',
                  label: 'Heart Rate',
                  active: connected,
                ),
              ),

              // Divider
              Container(
                width: 1,
                height: 56,
                color: Colors.white.withValues(alpha: 0.06),
              ),

              // Battery
              Expanded(
                child: _Metric(
                  icon: Icons.battery_charging_full,
                  iconColor: const Color(0xFF66BB6A),
                  value: connected && state.battery > 0
                      ? '${state.battery}'
                      : '--',
                  unit: '%',
                  label: 'Battery',
                  active: connected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Single metric inside the card ───────────────────────────────────────────
class _Metric extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;
  final bool active;

  const _Metric({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + label row
          Row(
            children: [
              Icon(icon,
                  color: active ? iconColor : iconColor.withValues(alpha: 0.3),
                  size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white24,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: active ? Colors.white38 : Colors.white12,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}