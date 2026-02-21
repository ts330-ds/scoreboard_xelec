import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/presentation/widget/heart_rate_ble_device_tile.dart';

class HeartBleDeviceListSheet extends StatelessWidget {
  const HeartBleDeviceListSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1626),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.only(
          top: 12,
          left: 24,
          right: 24,
          bottom: 24,
        ),
        child: BlocBuilder<HeartBleCubit, HeartBleState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag Handle ─────────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
      
                const SizedBox(height: 20),
      
                // ── Sheet Header ────────────────────────────────────────
                _buildHeader(state.isScanning),
      
                const SizedBox(height: 8),
      
                // ── Device count / empty hint ───────────────────────────
                Text(
                  state.foundDevices.isEmpty
                      ? state.isScanning
                          ? 'Looking for nearby devices…'
                          : 'No devices found. Tap Scan Again.'
                      : '${state.foundDevices.length} device${state.foundDevices.length == 1 ? '' : 's'} found',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
      
                const SizedBox(height: 16),
      
                // ── Device List ─────────────────────────────────────────
                if (state.foundDevices.isEmpty && state.isScanning)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4A90E2),
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.foundDevices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final device = state.foundDevices[index];
                      return HeartBleDeviceTile(
                        name: device.name,
                        mac: device.uuid,
                        rssi: device.rssi,
                        isPaired: device.isCompatible,
                        onTap: () {
                          context.read<HeartBleCubit>().connectToDevice(device);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
      
                const SizedBox(height: 16),
      
                // ── Scan Again Button ───────────────────────────────────
                _buildScanAgainButton(context, state.isScanning),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isScanning) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Available Devices',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isScanning)
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Scanning…',
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Scan Again Button ───────────────────────────────────────────────────────
  Widget _buildScanAgainButton(BuildContext context, bool isScanning) {
    return GestureDetector(
      onTap: isScanning ? null : () => context.read<HeartBleCubit>().startScan(),
      child: Opacity(
        opacity: isScanning ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF4A90E2).withOpacity(0.4),
            ),
            color: const Color(0xFF4A90E2).withOpacity(0.08),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.refresh, color: Color(0xFF4A90E2), size: 20),
              SizedBox(width: 10),
              Text(
                'Scan Again',
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
