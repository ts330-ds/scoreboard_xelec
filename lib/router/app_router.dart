import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/auth/presentation/screen/loginScreen.dart';
import 'package:xelex_esp/feature/bluetooth/presentation/screen/ble_scan_screen.dart';
import 'package:xelex_esp/feature/bluetooth/presentation/screen/device_selection_screen.dart';
import 'package:xelex_esp/feature/home/presentation/screen/home_screen.dart';
import 'package:xelex_esp/feature/feature_selection/presentation/screen/feature_selection_screen.dart';
import 'package:xelex_esp/feature/permission/bluetooth/presentation/permissoin_gate.dart';
import 'package:xelex_esp/feature/scoreboard/Kabaddi/presentation/screen/khabaddi_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/Kabaddi/presentation/screen/khabaddi_screen.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/screen/badminton_screen.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/screen/basket_ball_screen.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/screen/basketball_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/football/presentation/screen/football_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/football/presentation/screen/football_screen.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/screen/hand_ball_screen.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/screen/hockey_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/screen/hockey_screen.dart';
import 'package:xelex_esp/feature/scoreboard/kho_kho/presentation/screen/khokho_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/kho_kho/presentation/screen/khokho_screen.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/screen/universal_game_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/screen/universal_game_screen.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/router/router_notifier.dart';

import '../feature/permission/bluetooth/cubit/bluetooth_cubit.dart';
import '../feature/scoreboard/badminton/presentation/screen/badminton_config_screen.dart';
import '../feature/scoreboard/handball/presentation/screen/handball_config_screen.dart';
import '../feature/scoreboard/table_tennis/presentation/screen/table_tennis_config_screen.dart';
import '../feature/scoreboard/table_tennis/presentation/screen/table_tennis_screen.dart';
import '../responsive/adaptive_page.dart';
import '../service/permission/permission_status.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppPaths.login,
  routes: [
    /// 🏀 Basketball Screen
    GoRoute(
      path: AppPaths.basketball,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const BasketBallScreen(),
      ),
    ),

    /// 🏀 Basketball Config Screen
    GoRoute(
      path: AppPaths.basketballConfig,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const BasketBallConfigScreen(),
      ),
    ),

    /// Badminton Screen
    GoRoute(
      path: AppPaths.badminton,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const BadmintonScreen(),
      ),
    ),

    // Badminton Config Screen
    GoRoute(
      path: AppPaths.badmintonConfig,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const BadmintonConfigScreen(),
      ),
    ),

    GoRoute(
      path: AppPaths.handball,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const HandBallScreen(),
      ),
    ),

    /// 🏀 Handball Config Screen
    GoRoute(
      path: AppPaths.handballConfig,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const HandBallConfigScreen(),
      ),
    ),

    GoRoute(
      path: AppPaths.hockey,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const HockeyScreen(),
      ),
    ),

    GoRoute(
      path: AppPaths.hockeyConfig,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const HockeyConfigScreen(),
      ),
    ),

    GoRoute(
      path: AppPaths.table_tennis,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const TableTennisScreen(),
      ),
    ),

    GoRoute(
      path: AppPaths.tableTennisConfig,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const TableTennisConfigScreen(),
      ),
    ),

    GoRoute(
      path: AppPaths.kho_kho,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const KhoKhoScreen(),
      ),
    ),

    GoRoute(
      path: AppPaths.khoKhoConfig,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const KhoKhoConfigScreen(),
      ),
    ),

    GoRoute(
      path: AppPaths.football,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const FootballScreen(),
      ),
    ),
    GoRoute(
      path: AppPaths.footballConfig,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const FootballConfigScreen(),
      ),
    ),


    GoRoute(
      path: AppPaths.khabaddisConfig,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const KhabaddiConfigScreen(),
      ),
    ),
    GoRoute(
      path: AppPaths.khabaddi,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const KhabaddiScreen(),

      ),
    ),

    GoRoute(
      path: AppPaths.universalConfig,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const UniversalGameConfigScreen(),
      ),
    ),
    GoRoute(
      path: AppPaths.universal,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const UniversalGameScreen(),

      ),
    ),


    /// ⚙️ Login Screen
    GoRoute(
      path: AppPaths.login,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const LoginScreen(),
      ),
    ),

    /// 🛠 Feature Selection Screen
    GoRoute(
      path: AppPaths.featureSelection,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const FeatureSelectionScreen(),
      ),
    ),

    /// 📱 Device Selection Screen
    GoRoute(
      path: AppPaths.deviceSelection,
      pageBuilder: (context, state) {
        final feature = state.uri.queryParameters['feature'] ?? 'scoreboard';
        return adaptivePage(
          state: state,
          child: DeviceSelectionScreen(selectedFeature: feature),
        );
      },
    ),

    /// ⚙️ Home Screen (Scoreboard Selection)
    GoRoute(
      path: AppPaths.home,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const HomeScreen(),
      ),
    ),

    // Bluetooth Screen
    GoRoute(
      path: AppPaths.ble_scan,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const BluetoothScanScreen(),
      ),
    ),

    GoRoute(
      path: AppPaths.ble_permission,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const PermissionGate(child: FeatureSelectionScreen()),
      ),
    ),
  ],
);
