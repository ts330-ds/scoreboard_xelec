import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
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
      await cubit.disconnect();
      return;
    }

    final scanStarted = await cubit.startScan();
    if (!context.mounted) return;
    if (!scanStarted) return;

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
    final label = isConnected
        ? 'Disconnect'
        : isScanning
            ? 'Scanning…'
            : 'Connect to Bluetooth';

    final icon = isConnected
        ? Icons.bluetooth_disabled
        : Icons.bluetooth_searching;

    final bgColor = isConnected ? AppColors.subtext : AppColors.primary;

    return GestureDetector(
      onTap: isScanning ? null : () => _onTap(context),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
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
