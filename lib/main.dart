import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/error/screen/global_error_screen.dart';
import 'package:xelex_esp/router/app_router.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import 'package:xelex_esp/service/permission/bluetooth_permission_service.dart';
import 'package:xelex_esp/utility/theme.dart';

import 'feature/bluetooth/presentation/cubit/ble/ble_cubit.dart';
import 'feature/permission/bluetooth/cubit/bluetooth_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDI();
  FlutterBluePlus.setLogLevel(LogLevel.warning, color: false);
  final bluetoothPermission = BluetoothPermissionService();
  // SocketService().connect("ws://scoreboard.local:81");
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => PermissionCubit(bluetoothPermission)),
        BlocProvider(create: (_) => sl<BleCubit>()),
        BlocProvider(create: (_) => sl<GlobalErrorCubit>()),
      ],
      child: const MyApp(),
    ),
  );

  // runApp(DevicePreview(
  //   builder: (BuildContext context) {
  //     return MultiBlocProvider(
  //         providers: [
  //           BlocProvider(create: (context) => PermissionCubit(bluetoothPermission)..checkPermission()),
  //           BlocProvider(create: (_) => sl<BleCubit>()),
  //           BlocProvider(create: (_) => sl<GlobalErrorCubit>(),)
  //         ],
  //         child: const MyApp()

  //     );
  //   },
  // ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
          theme: lightTheme(context),
          darkTheme: lightTheme(context),
          themeMode: ThemeMode.system,
          builder: (context, child) {
            return ScaffoldMessenger(
              child: GlobalErrorToastListener(child: Scaffold(body: child!)),
            );
          },
        );
      },
    );
  }
}
