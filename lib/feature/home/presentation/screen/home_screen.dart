import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/bluetooth/presentation/cubit/ble/ble_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/presentation/cubit/ble/ble_state.dart';
import 'package:xelex_esp/feature/home/presentation/layout/home_screen_mobile.dart';
import 'package:xelex_esp/feature/home/presentation/layout/home_screen_tablet.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/router/app_path.dart';

import '../layout/home_screen_desktop.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BleCubit, BleState>(
      listenWhen: (previous, current) {
        // Show dialog when connection is lost (status changes from connected to idle)
        return previous.status == BleStatus.connected &&
            current.status == BleStatus.idle;
      },
      listener: (context, state) {
        _showDisconnectionDialog(context);
      },
      child: ResponsiveLayout(
        mobile: HomeScreenMobile(),
        tablet: HomeScreenTablet(),
        desktop: HomeScreenDesktop(),
      ),
    );
  }

  void _showDisconnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Connection Lost'),
          content: const Text(
            'Bluetooth device disconnected. Please select a device again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Pop the dialog
                Navigator.of(dialogContext).pop();

                // Clear all routes and navigate to device selection
                context.go(AppPaths.deviceSelection);
              },
              child: const Text('Select Device'),
            ),
          ],
        ),
      ),
    );
  }
}
