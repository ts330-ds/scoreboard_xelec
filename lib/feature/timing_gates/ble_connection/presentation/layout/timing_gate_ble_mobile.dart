import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/presentation/cubit/timing_gate_bluetooth_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/presentation/cubit/timing_gate_bluetooth_state.dart';
import 'package:xelex_esp/router/timing_gate_path.dart';

class TimingGateBleMobile extends StatefulWidget {
  const TimingGateBleMobile({super.key});

  @override
  State<TimingGateBleMobile> createState() => _TimingGateBleMobileState();
}

class _TimingGateBleMobileState extends State<TimingGateBleMobile> {
  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _border = Color(0xFFDDE3EC);
  static const _warning = Color(0xFFD97706);
  static const _error = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    // Auto-start scan when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimingGateBleCubit>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TimingGateBleCubit, TimingGateBleState>(
      // When connected → automatically navigate to the timing gate main screen
      listenWhen: (prev, curr) => prev.isConnected != curr.isConnected,
      listener: (context, state) {
        if (state.isConnected) {
          // pushReplacement: BLE screen hata ke main screen lagao
          // → back dabane pe seedha feature selection pe jao
          context.pushReplacement(TimingGatePaths.timingGateHomeMobile);
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _text),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Connect Timing Gates',
            style: TextStyle(
              color: _text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: BlocBuilder<TimingGateBleCubit, TimingGateBleState>(
          builder: (context, state) {
            if (state.isBluetoothOff) return _buildBluetoothOff(context);
            if (state.isPermissionDenied) {
              return _buildPermissionDenied(context);
            }
            return _buildContent(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TimingGateBleState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(state),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Devices',
                style: TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!state.isScanning && !state.isConnecting)
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Scan Again'),
                  style: TextButton.styleFrom(foregroundColor: _primary),
                  onPressed: () =>
                      context.read<TimingGateBleCubit>().startScan(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildDeviceList(context, state)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(TimingGateBleState state) {
    final isScanning = state.isScanning;
    final isConnecting = state.isConnecting;
    final isActive = isScanning || isConnecting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? _primaryLight : const Color(0xFFF0F4F8),
              shape: BoxShape.circle,
            ),
            child: isActive
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _primary,
                    ),
                  )
                : const Icon(
                    Icons.bluetooth_searching,
                    color: _subtext,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnecting
                      ? 'Connecting...'
                      : isScanning
                          ? 'Searching for Gates'
                          : state.foundDevices.isEmpty
                              ? 'No devices found'
                              : '${state.foundDevices.length} device(s) found',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnecting
                      ? state.status
                      : isScanning
                          ? 'Make sure your APEX gates are powered on'
                          : 'Tap a device below to connect',
                  style: const TextStyle(color: _subtext, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, TimingGateBleState state) {
    if (state.isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primary),
            SizedBox(height: 16),
            Text(
              'Scanning for nearby devices...',
              style: TextStyle(color: _subtext, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (state.foundDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.bluetooth_disabled,
                color: _subtext,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No devices found',
              style: TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make sure your APEX timing gates\nare powered on and nearby.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _subtext, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => context.read<TimingGateBleCubit>().startScan(),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: state.foundDevices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final device = state.foundDevices[index];
        return _buildDeviceCard(context, device, state.isConnecting);
      },
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    TimingGateBleDevice device,
    bool isConnecting,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: device.isCompatible
              ? _primary.withValues(alpha: 0.3)
              : _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  device.isCompatible ? _primaryLight : const Color(0xFFF0F4F8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sensors,
              color: device.isCompatible ? _primary : _subtext,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _SignalBars(bars: device.signalBars),
                    const SizedBox(width: 6),
                    Text(
                      '${device.rssi} dBm',
                      style: const TextStyle(color: _subtext, fontSize: 12),
                    ),
                    // if (device.isCompatible) ...[
                    //   const SizedBox(width: 8),
                    //   Container(
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 6,
                    //       vertical: 2,
                    //     ),
                    //     decoration: BoxDecoration(
                    //       color: _primaryLight,
                    //       borderRadius: BorderRadius.circular(4),
                    //     ),
                    //     child: const Text(
                    //       'Timing Gates',
                    //       style: TextStyle(
                    //         color: _primary,
                    //         fontSize: 10,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ),
                    // ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isConnecting
                ? null
                : () =>
                    context.read<TimingGateBleCubit>().connectToDevice(device),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _border,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Connect', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothOff(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.bluetooth_disabled,
                color: _warning,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bluetooth is Off',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please enable Bluetooth to connect\nyour APEX timing gates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _subtext, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings_bluetooth),
              label: const Text('Open Bluetooth Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _warning,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                context.read<TimingGateBleCubit>()
                  ..clearBluetoothOffFlag()
                  ..openBluetoothSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: _error.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.block, color: _error, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Permission Required',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bluetooth permission is required to\nconnect your timing gates. Please allow\nit in app settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _subtext, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Open App Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                context.read<TimingGateBleCubit>().clearPermissionDeniedFlag();
                openAppSettings();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Signal strength bars widget ─────────────────────────────────────────────
class _SignalBars extends StatelessWidget {
  final int bars;

  const _SignalBars({required this.bars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final active = i < bars;
        return Container(
          width: 4,
          height: 6.0 + (i * 3),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF16A34A)
                : const Color(0xFFDDE3EC),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
