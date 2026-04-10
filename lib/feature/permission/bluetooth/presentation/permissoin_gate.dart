import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/data/cubit/bluetooth_cubit.dart';

import '../../../../service/permission/permission_status.dart';

class PermissionGate extends StatelessWidget {
  final Widget child;
  const PermissionGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermissionCubit, AppPermissionStatus>(
      builder: (context, status) {
        if (status == AppPermissionStatus.granted) {
          return child;
        }

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Bluetooth permission required"),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      context.read<PermissionCubit>().ask(),
                  child: const Text("Grant Permission"),
                ),
                if (status ==
                    AppPermissionStatus.permanentlyDenied)
                  TextButton(
                    onPressed: openAppSettings,
                    child: const Text("Open Settings"),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
