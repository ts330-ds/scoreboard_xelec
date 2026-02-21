import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/utility/theme_extension.dart';
import '../cubit/ble/ble_cubit.dart';
import '../cubit/scan/ble_scan_cubit.dart';
import '../cubit/scan/ble_scan_state.dart';

class BleScanBottomSheet extends StatelessWidget {
  const BleScanBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BluetoothScanCubit()..startScan(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scanning for Devices',
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                BlocBuilder<BluetoothScanCubit, BluetoothScanState>(
                  builder: (context, state) {
                    if (state.status == ScanStatus.scanning) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () =>
                          context.read<BluetoothScanCubit>().startScan(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Device List
            Expanded(
              child: BlocBuilder<BluetoothScanCubit, BluetoothScanState>(
                builder: (context, state) {
                  if (state.devices.isEmpty &&
                      state.status != ScanStatus.scanning) {
                    return const Center(child: Text("No devices found"));
                  }

                  return ListView.separated(
                    itemCount: state.devices.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final result = state.devices[index];
                      final device = result.device;
                      final name = device.advName.isNotEmpty
                          ? device.advName
                          : "Unknown Device";

                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.bluetooth),
                        ),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        onTap: () {
                          final cubit = context.read<BleCubit>();
                          cubit.connectToDevice(device);
                          if (!context.mounted) return;
                          context.pop(true);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
