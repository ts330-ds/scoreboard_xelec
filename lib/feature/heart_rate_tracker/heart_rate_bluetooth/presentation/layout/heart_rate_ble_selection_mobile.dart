import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/presentation/widget/heart_ble_connect_button.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/presentation/widget/heart_rate_ble_illustration.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/presentation/widget/heart_rate_ble_status_chip.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

class HeartBleSelectionMobile extends StatelessWidget {
  const HeartBleSelectionMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: "Connect Device",
      bodyBackground: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              

    
              const SizedBox(height: 8),
              const Text(
                'Heart Rate\nMonitor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 40),

              // ── Illustration — reacts to connection / scan / heart rate
              BlocBuilder<HeartBleCubit, HeartBleState>(
                buildWhen: (p, c) =>
                    p.isConnected != c.isConnected ||
                    p.isScanning != c.isScanning ||
                    p.heartRate != c.heartRate,
                builder: (context, state) => HeartBleIllustration(
                  isConnected: state.isConnected,
                  isScanning: state.isScanning,
                  heartRate: state.heartRate,
                ),
              ),

              const SizedBox(height: 28),

              // ── Status Chip — live status text from cubit ────────────
              BlocBuilder<HeartBleCubit, HeartBleState>(
                buildWhen: (p, c) =>
                    p.isConnected != c.isConnected ||
                    p.status != c.status ||
                    p.lastDevice != c.lastDevice,
                builder: (context, state) => HeartBleStatusChip(
                  isConnected: state.isConnected,
                  status: state.status,
                  deviceName: state.isConnected && state.lastDevice.isNotEmpty
                      ? state.lastDevice
                      : null,
                ),
              ),

              const Spacer(),

              // ── Connect / Disconnect button driven by cubit state ────
              BlocBuilder<HeartBleCubit, HeartBleState>(
                buildWhen: (p, c) =>
                    p.isConnected != c.isConnected ||
                    p.isScanning != c.isScanning,
                builder: (context, state) => HeartBleConnectButton(
                  isConnected: state.isConnected,
                  isScanning: state.isScanning,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
