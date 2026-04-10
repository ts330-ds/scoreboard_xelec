import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xelex_esp/feature/bluetooth/presentation/cubit/ble/ble_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/presentation/cubit/ble/ble_state.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/data/cubit/bluetooth_cubit.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/permission/permission_status.dart';
import 'package:xelex_esp/utility/theme_extension.dart';
import '../widget/ble_scan_bottom_sheet.dart';

class DeviceSelectionScreen extends StatelessWidget {
  final String selectedFeature;
  const DeviceSelectionScreen({super.key, required this.selectedFeature});

  void _navigateToFeature(BuildContext context) {
    switch (selectedFeature) {
      case 'scoreboard':
        context.pushReplacement(AppPaths.home);
        break;
      case 'time-gate':
        context.pushReplacement(AppPaths.home);
        break;
      case 'heart-tracker':
        context.pushReplacement(AppPaths.home);
        break;
      default:
        context.go(AppPaths.home);
    }
  }

  void _showScanSheet(BuildContext context) async {
    // On iOS, Bluetooth permission is auto-requested when scanning starts
    // Check adapter state first, then request permissions
    final canScan = await _ensureBluetoothOn(context);
    if (!canScan) return;

    // For Android, explicitly request permissions
    if (Platform.isAndroid) {
      await context.read<PermissionCubit>().ask();
      final permissionStatus = context.read<PermissionCubit>().state;

      if (permissionStatus == AppPermissionStatus.permanentlyDenied) {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Permission denied'),
              content: const Text(
                'Bluetooth permission is permanently denied. Please enable it in Settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () async {
                    await openAppSettings();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('OPEN SETTINGS'),
                ),
              ],
            );
          },
        );
        return;
      }

      if (permissionStatus != AppPermissionStatus.granted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth permission required.')),
        );
        return;
      }
    }

    if (!context.mounted) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BleScanBottomSheet(),
    );

    if (!context.mounted) return;
    if (result == true) {
      final cubit = context.read<BleCubit>();
      BleState resultState;
      try {
        resultState = await cubit.stream
            .firstWhere(
              (state) =>
                  state.status == BleStatus.connected ||
                  state.status == BleStatus.error,
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        resultState = const BleState(
          status: BleStatus.error,
          error: 'Connection timed out',
        );
      }

      if (!context.mounted) return;

      if (resultState.status == BleStatus.connected) {
        _navigateToFeature(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultState.error ?? 'Failed to connect - Check again',
            ),
          ),
        );
      }
    }
  }

  Future<bool> _ensureBluetoothOn(BuildContext context) async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState == BluetoothAdapterState.on) {
      return true;
    }

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bluetooth is off'),
          content: const Text('Please turn on Bluetooth to scan for devices.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                if (Platform.isIOS) {
                  final settingsUri = Uri.parse('app-settings:');
                  if (await canLaunchUrl(settingsUri)) {
                    await launchUrl(
                      settingsUri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                } else {
                  try {
                    await FlutterBluePlus.turnOn();
                  } catch (_) {}
                }
                if (context.mounted) {
                  context.pop(true);
                }
              },
              child: Text(Platform.isIOS ? 'OPEN SETTINGS' : 'TURN ON'),
            ),
          ],
        );
      },
    );

    if (result != true) return false;

    final updatedState = await FlutterBluePlus.adapterState.first;
    return updatedState == BluetoothAdapterState.on;
  }

  @override
  Widget build(BuildContext context) {
    // Load saved devices when the screen is built

    return AdaptiveScaffold(
      title: 'Device Selection',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose a device for ${selectedFeature.replaceAll('-', ' ').toUpperCase()}',
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Expanded(child: const SizedBox(height: 24)),

            // BlocBuilder<BleCubit, BleState>(
            //   builder: (context, state) {
            //     if (state.previousDevices.isNotEmpty) {
            //       return Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'Previous Devices',
            //               style: context.text.titleMedium?.copyWith(
            //                 color: context.colors.outline,
            //               ),
            //             ),
            //             const SizedBox(height: 12),
            //             Expanded(
            //               child: ListView.separated(
            //                 itemCount: state.previousDevices.length,
            //                 separatorBuilder: (context, index) =>
            //                     const SizedBox(height: 12),
            //                 itemBuilder: (context, index) {
            //                   final device = state.previousDevices[index];
            //                   return Card(
            //                     elevation: 0,
            //                     shape: RoundedRectangleBorder(
            //                       borderRadius: BorderRadius.circular(16),
            //                       side: BorderSide(
            //                         color: context.colors.outlineVariant,
            //                       ),
            //                     ),
            //                     child: ListTile(
            //                       leading: CircleAvatar(
            //                         backgroundColor:
            //                             context.colors.primaryContainer,
            //                         child: Icon(
            //                           Icons.bluetooth,
            //                           color: context.colors.onPrimaryContainer,
            //                         ),
            //                       ),
            //                       title: Text(
            //                         device['name'] ?? 'Unknown Device',
            //                         style: const TextStyle(
            //                           fontWeight: FontWeight.bold,
            //                         ),
            //                       ),
            //                       subtitle: Text(
            //                         device['id'] ?? '',
            //                         style: context.text.bodySmall,
            //                       ),
            //                       trailing: const Icon(
            //                         Icons.arrow_forward_ios,
            //                         size: 16,
            //                       ),
            //                       onTap: () async {
            //                         await context.read<BleCubit>().connectToId(
            //                           device['id']!,
            //                           device['name']!,
            //                         );
            //                         if (state.status == BleStatus.connected) {
            //                           _navigateToFeature(context);
            //                         }
            //                       },
            //                     ),
            //                   );
            //                 },
            //               ),
            //             ),
            //           ],
            //         ),
            //       );
            //     } else {
            //       return const Expanded(
            //         child: Column(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
            //             Icon(
            //               Icons.bluetooth_searching,
            //               size: 64,
            //               color: Colors.grey,
            //             ),
            //             SizedBox(height: 16),
            //             Text(
            //               'No previous devices found',
            //               style: TextStyle(color: Colors.grey),
            //             ),
            //           ],
            //         ),
            //       );
            //     }
            //   },
            // ),

            //const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showScanSheet(context),
              icon: const Icon(Icons.search),
              label: const Text('Scan New Devices'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.push(AppPaths.home);
              },
              child: Text(
                "Continue without Bluetooth",
                style: TextStyle(color: context.colors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
