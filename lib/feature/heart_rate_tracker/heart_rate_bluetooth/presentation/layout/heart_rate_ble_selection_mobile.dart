import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/presentation/widget/heart_ble_connect_button.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/presentation/widget/heart_rate_ble_illustration.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/presentation/widget/heart_rate_ble_status_chip.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

void _showPermissionDeniedSnackbar(BuildContext context) {
  context.read<HeartBleCubit>().clearPermissionDeniedFlag();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFF1A1F2E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: const Row(
        children: [
          Icon(Icons.lock_outline, color: Color(0xFF4A90E2), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bluetooth permission denied. Please allow it in App Settings.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

void _showBluetoothOffDialog(BuildContext context) {
  // Cubit ko pehle hi pakad lo — dialog builder ke bahar
  final cubit = context.read<HeartBleCubit>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.bluetooth_disabled, color: Color(0xFF4A90E2), size: 28),
          SizedBox(width: 12),
          Text(
            'Bluetooth Off',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: const Text(
        'Bluetooth is turned off. Please turn on Bluetooth to connect to your heart rate monitor.',
        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OutlinedButton(
          onPressed: () {
            cubit.clearBluetoothOffFlag();
            Navigator.of(ctx).pop();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white54,
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            cubit.clearBluetoothOffFlag();
            Navigator.of(ctx).pop();
            cubit.openBluetoothSettings();
          },
          icon: const Icon(Icons.settings_bluetooth, size: 18),
          label: const Text('Turn On'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );
}

void _showBondingSnackbar(BuildContext context, String bondingStatus) {
  String message;
  IconData icon;
  Color color;

  switch (bondingStatus) {
    case "required":
      message = 'Pairing required. Please accept on your device.';
      icon = Icons.bluetooth_searching;
      color = const Color(0xFF4A90E2);
      break;
    case "bonded":
      message = 'Device paired successfully.';
      icon = Icons.bluetooth_connected;
      color = Colors.green;
      break;
    case "failed":
      message = 'Pairing failed. Please try again.';
      icon = Icons.bluetooth_disabled;
      color = Colors.redAccent;
      break;
    default:
      return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFF1A1F2E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

void _showNotificationDeniedDialog(BuildContext context) {
  final cubit = context.read<HeartBleCubit>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.notifications_off, color: Color(0xFFEF5350), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notification Permission',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'Notification permission is required to show live heart rate in the notification bar.\n\n'
        'Without this, heart rate will not be visible when the app is minimized.',
        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        OutlinedButton(
          onPressed: () {
            cubit.clearNotificationDeniedFlag();
            Navigator.of(ctx).pop();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white54,
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Skip'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            cubit.clearNotificationDeniedFlag();
            Navigator.of(ctx).pop();
            openAppSettings();
          },
          icon: const Icon(Icons.settings, size: 18),
          label: const Text('Open Settings'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );
}

class HeartBleSelectionMobile extends StatelessWidget {
  const HeartBleSelectionMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<HeartBleCubit, HeartBleState>(
      listenWhen: (p, c) =>
          (!p.isBluetoothOff && c.isBluetoothOff) ||
          (!p.isPermissionDenied && c.isPermissionDenied) ||
          (!p.isNotificationDenied && c.isNotificationDenied) ||
          p.bondingStatus != c.bondingStatus,
      listener: (context, state) {
        if (state.isBluetoothOff) _showBluetoothOffDialog(context);
        if (state.isPermissionDenied) _showPermissionDeniedSnackbar(context);
        if (state.isNotificationDenied) _showNotificationDeniedDialog(context);
        if (state.bondingStatus.isNotEmpty) {
          _showBondingSnackbar(context, state.bondingStatus);
        }
      },
      child: AdaptiveScaffold(
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
                  'Heart Rate Monitor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
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

                const SizedBox(height: 16),

                // ── Device Info + Sport Data (scrollable when connected) ──
                Expanded(
                  child: BlocBuilder<HeartBleCubit, HeartBleState>(
                    buildWhen: (p, c) =>
                        p.isConnected != c.isConnected ||
                        p.hasDeviceInfo != c.hasDeviceInfo ||
                        p.hasSportData != c.hasSportData ||
                        p.modelName != c.modelName ||
                        p.firmwareVersion != c.firmwareVersion ||
                        p.hardwareVersion != c.hardwareVersion ||
                        p.softwareVersion != c.softwareVersion ||
                        p.serialNumber != c.serialNumber ||
                        p.vendorName != c.vendorName ||
                        p.bodySensorLocation != c.bodySensorLocation ||
                        p.steps != c.steps ||
                        p.distance != c.distance ||
                        p.calorie != c.calorie,
                    builder: (context, state) {
                      if (!state.isConnected ||
                          (!state.hasDeviceInfo && !state.hasSportData)) {
                        return const SizedBox.shrink();
                      }
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            if (state.hasDeviceInfo)
                              _DeviceInfoCard(state: state),
                            if (state.hasSportData) ...[
                              const SizedBox(height: 12),
                              _SportCard(state: state),
                            ],
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  ),
                ),

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
      ),
    );
  }
}

// ── Device Info Card ─────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  final HeartBleState state;
  const _DeviceInfoCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF4A90E2), size: 16),
              SizedBox(width: 8),
              Text(
                'Device Info',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.modelName.isNotEmpty) _InfoRow('Model', state.modelName),
          if (state.vendorName.isNotEmpty) _InfoRow('Vendor', state.vendorName),
          if (state.firmwareVersion.isNotEmpty)
            _InfoRow('Firmware', state.firmwareVersion),
          if (state.hardwareVersion.isNotEmpty)
            _InfoRow('Hardware', state.hardwareVersion),
          if (state.softwareVersion.isNotEmpty)
            _InfoRow('Software', state.softwareVersion),
          if (state.serialNumber.isNotEmpty)
            _InfoRow('Serial', state.serialNumber),
          if (state.systemId.isNotEmpty) _InfoRow('System ID', state.systemId),
          if (state.bodySensorLocation.isNotEmpty)
            _InfoRow('Sensor Location', state.bodySensorLocation),
        ],
      ),
    );
  }
}

// ── Sport Data Card ──────────────────────────────────────────────────────────

class _SportCard extends StatelessWidget {
  final HeartBleState state;
  const _SportCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_walk, color: Color(0xFF4A90E2), size: 16),
              SizedBox(width: 8),
              Text(
                'Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SportStat(
                label: 'Steps',
                value: '${state.steps}',
                icon: Icons.directions_walk,
              ),
              _SportStat(
                label: 'Distance',
                value: '${state.distance}m',
                icon: Icons.straighten,
              ),
              _SportStat(
                label: 'Calories',
                value: '${state.calorie}',
                icon: Icons.local_fire_department,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SportStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SportStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4A90E2), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
