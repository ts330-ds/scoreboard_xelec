import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/error/screen/global_error_screen.dart';
import 'package:xelex_esp/feature/auth/presentation/screen/loginScreen.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/game_select_mapper.dart';
import 'package:xelex_esp/router/app_router.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import 'package:xelex_esp/service/permission/bluetooth_permission_service.dart';
import 'package:xelex_esp/service/webSocketService/socketService.dart';
import 'package:xelex_esp/utility/theme.dart';

import 'feature/bluetooth/presentation/cubit/ble/ble_cubit.dart';
import 'feature/bluetooth/service/ble_service.dart';
import 'feature/permission/bluetooth/cubit/bluetooth_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDI();
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  final bluetoothPermission = BluetoothPermissionService();
  final bleService = BleService();
 // SocketService().connect("ws://scoreboard.local:81");
  /*SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);*/

  runApp(DevicePreview(
    builder: (BuildContext context) {
      return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => PermissionCubit(bluetoothPermission)..checkPermission()),
            BlocProvider(create: (_) => sl<BleCubit>()),
            BlocProvider(create: (_) => sl<GlobalErrorCubit>(),)
          ],
          child: const MyApp()

      );
    },
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: lightTheme(context),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return GlobalErrorToastListener(
          child: child!,
        );
      },
    );
  }
}