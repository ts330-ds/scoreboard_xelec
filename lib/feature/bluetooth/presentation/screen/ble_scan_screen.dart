import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/ble/ble_cubit.dart';
import '../cubit/scan/ble_scan_cubit.dart';
import '../cubit/scan/ble_scan_state.dart';


class BluetoothScanScreen extends StatelessWidget {
  const BluetoothScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BluetoothScanCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Select Bluetooth Device"),
          actions: [
            BlocBuilder<BluetoothScanCubit, BluetoothScanState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    state.status == ScanStatus.scanning
                        ? Icons.stop
                        : Icons.search,
                  ),
                  onPressed: () {
                    final cubit =
                    context.read<BluetoothScanCubit>();
                    state.status == ScanStatus.scanning
                        ? cubit.stopScan()
                        : cubit.startScan();
                  },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<BluetoothScanCubit, BluetoothScanState>(
          builder: (context, state) {
            if (state.devices.isEmpty) {
              return const Center(
                child: Text("No Bluetooth devices found"),
              );
            }

            return ListView.builder(
              itemCount: state.devices.length,
              itemBuilder: (context, index) {
                final result = state.devices[index];
                final device = result.device;
                final name = device.advName.isNotEmpty
                    ? device.advName
                    : "Unknown Device";

                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(name),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: Text("${result.rssi} dBm"),
                  onTap: () async {
                    await context
                        .read<BleCubit>()
                        .connectToDevice(device);

                    if (context.mounted) {
                      context.pop();
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
