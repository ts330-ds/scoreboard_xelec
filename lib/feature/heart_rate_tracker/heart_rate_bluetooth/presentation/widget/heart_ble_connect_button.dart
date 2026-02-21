import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'heart_ble_device_list_sheet.dart';

class HeartBleConnectButton extends StatelessWidget {
  final bool isConnected;
  final bool isScanning;

  const HeartBleConnectButton({
    super.key,
    required this.isConnected,
    required this.isScanning,
  });

  Future<void> _onTap(BuildContext context) async {
    final cubit = context.read<HeartBleCubit>();

    if (isConnected) {
      // Already connected — disconnect
      await cubit.disconnect();
      return;
    }

    // Start scan then show the device sheet
    await cubit.startScan();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const HeartBleDeviceListSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // While scanning show a subtle loading state on the button
    final label = isConnected
        ? 'Disconnect'
        : isScanning
            ? 'Scanning…'
            : 'Connect to Bluetooth';

    final icon = isConnected
        ? Icons.bluetooth_disabled
        : isScanning
            ? Icons.bluetooth_searching
            : Icons.bluetooth_searching;

    final gradient = isConnected
        ? const LinearGradient(
            colors: [Color(0xFF455A64), Color(0xFF263238)],
          )
        : const LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF1565C0)],
          );

    return GestureDetector(
      onTap: isScanning ? null : () => _onTap(context),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: (isConnected
                      ? const Color(0xFF455A64)
                      : const Color(0xFF4A90E2))
                  .withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isScanning)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
