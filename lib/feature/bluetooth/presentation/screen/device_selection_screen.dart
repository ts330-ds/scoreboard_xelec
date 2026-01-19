import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/utility/theme_extension.dart';
import '../cubit/ble/ble_cubit.dart';
import '../cubit/ble/ble_state.dart';
import '../widget/ble_scan_bottom_sheet.dart';

class DeviceSelectionScreen extends StatelessWidget {
  final String selectedFeature;
  const DeviceSelectionScreen({super.key, required this.selectedFeature});

  void _navigateToFeature(BuildContext context) {
    switch (selectedFeature) {
      case 'scoreboard':
        context.go(AppPaths.home);
        break;
      case 'time-gate':
        // TODO: context.go(AppPaths.timeGateHome);
        context.go(AppPaths.home);
        break;
      case 'heart-tracker':
        // TODO: context.go(AppPaths.heartTrackerHome);
        context.go(AppPaths.home);
        break;
      default:
        context.go(AppPaths.home);
    }
  }

  void _showScanSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BleScanBottomSheet(),
    );

    if (result == true && context.mounted) {
      _navigateToFeature(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load saved devices when the screen is built
    context.read<BleCubit>().loadSavedDevices();

    return AdaptiveScaffold(
      title: 'Device Selection',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose a device for ${selectedFeature.replaceAll('-', ' ').toUpperCase()}',
              style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            BlocBuilder<BleCubit, BleState>(
              builder: (context, state) {
                if (state.previousDevices.isNotEmpty) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Previous Devices',
                          style: context.text.titleMedium?.copyWith(color: context.colors.outline),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: state.previousDevices.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final device = state.previousDevices[index];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: context.colors.outlineVariant),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: context.colors.primaryContainer,
                                    child: Icon(Icons.bluetooth, color: context.colors.onPrimaryContainer),
                                  ),
                                  title: Text(
                                    device['name'] ?? 'Unknown Device',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    device['id'] ?? '',
                                    style: context.text.bodySmall,
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () => _showScanSheet(context),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No previous devices found', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => _showScanSheet(context),
              icon: const Icon(Icons.search),
              label: const Text('Scan New Devices'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => _navigateToFeature(context),
              child: const Text('Continue without connecting'),
            ),
          ],
        ),
      ),
    );
  }
}
