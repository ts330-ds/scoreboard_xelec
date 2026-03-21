import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/auth/presentation/screen/loginScreen.dart';
import 'package:xelex_esp/feature/bluetooth/presentation/screen/device_selection_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/presentation/screen/heart_rate_ble_selection_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/home_heart_rate/presentation/cubit/navigation_cubit/shell_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/home_heart_rate/presentation/layout/indivi_activity_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/home_heart_rate/presentation/layout/indivi_history_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/home_heart_rate/presentation/layout/indivi_home_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/home_heart_rate/presentation/layout/indivi_profile_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/home_heart_rate/presentation/screen/indivi_main_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/profile_registration/presentation/screen/profile_choose_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/profile_registration/presentation/screen/profile_registration_screen.dart';
import 'package:xelex_esp/feature/home/presentation/screen/home_screen.dart';
import 'package:xelex_esp/feature/feature_selection/presentation/screen/feature_selection_screen.dart';
import 'package:xelex_esp/feature/permission/bluetooth/presentation/permissoin_gate.dart';
import 'package:xelex_esp/feature/scoreboard/Kabaddi/presentation/screen/khabaddi_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/Kabaddi/presentation/screen/khabaddi_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/all_abcd_screens/ab_cd_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/all_abcd_screens/abc_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/all_abcd_screens/abcd_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/archery_alternate_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/archery_alternate_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/archery_idle_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/archery_individual_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/archery_individual_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/archery_mode_selection_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/archery_team_screen.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/controller/archery_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/archery_team_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/config_screen/ab_cd_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/config_screen/abc_config_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/config_screen/abcd_config_screen.dart';
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
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/archery_screen.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/screen/archery_config_screen.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/presentation/screen/timing_gate_main_screen.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/presentation/cubit/timing_gate_bluetooth_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/presentation/screen/timing_gate_ble_screen.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/presentation/layout/timing_gate_home_mobile.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/presentation/layout/timing_gate_results_mobile.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/presentation/layout/timing_gate_athletes_mobile.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/presentation/layout/timing_gate_profile_mobile.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/athletes/athletes_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/screen/session_detail_screen.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/screen/timing_session_screen.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/test_session_model.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import 'package:xelex_esp/router/timing_gate_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../feature/scoreboard/badminton/presentation/screen/badminton_config_screen.dart';
import '../feature/scoreboard/handball/presentation/screen/handball_config_screen.dart';
import '../feature/scoreboard/table_tennis/presentation/screen/table_tennis_config_screen.dart';
import '../feature/scoreboard/table_tennis/presentation/screen/table_tennis_screen.dart';
import '../responsive/adaptive_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppPaths.login,
  // redirect: (context, routerState) {
  //   final loc = routerState.matchedLocation;
  //   final isTimingGateRoute = loc.startsWith('/timing-gate');
  //   final isBleScreen = loc == TimingGatePaths.timingGateBle;
  //   final isConnected = sl<TimingGateBleCubit>().state.isConnected;

  //   // Already connected but landed on BLE screen → go straight to main
  //   if (isBleScreen && isConnected) {
  //     return TimingGatePaths.timingGateHomeMobile;
  //   }

  //   // Trying to reach any timing-gate route without being connected → gate it
  //   if (isTimingGateRoute && !isBleScreen && !isConnected) {
  //     return TimingGatePaths.timingGateBle;
  //   }

  //   return null;
  // },
  routes: [
    /// 🏀 Basketball Screen
    GoRoute(
      path: AppPaths.basketball,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const BasketBallScreen()),
    ),

    /// 🏀 Basketball Config Screen
    GoRoute(
      path: AppPaths.basketballConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const BasketBallConfigScreen()),
    ),

    /// Badminton Screen
    GoRoute(
      path: AppPaths.badminton,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const BadmintonScreen()),
    ),

    // Badminton Config Screen
    GoRoute(
      path: AppPaths.badmintonConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const BadmintonConfigScreen()),
    ),

    GoRoute(
      path: AppPaths.handball,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const HandBallScreen()),
    ),

    /// 🏀 Handball Config Screen
    GoRoute(
      path: AppPaths.handballConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const HandBallConfigScreen()),
    ),

    GoRoute(
      path: AppPaths.hockey,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const HockeyScreen()),
    ),

    GoRoute(
      path: AppPaths.hockeyConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const HockeyConfigScreen()),
    ),

    GoRoute(
      path: AppPaths.table_tennis,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const TableTennisScreen()),
    ),

    GoRoute(
      path: AppPaths.tableTennisConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const TableTennisConfigScreen()),
    ),

    GoRoute(
      path: AppPaths.kho_kho,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const KhoKhoScreen()),
    ),

    GoRoute(
      path: AppPaths.khoKhoConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const KhoKhoConfigScreen()),
    ),

    GoRoute(
      path: AppPaths.football,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const FootballScreen()),
    ),
    GoRoute(
      path: AppPaths.footballConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const FootballConfigScreen()),
    ),

    GoRoute(
      path: AppPaths.khabaddisConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const KhabaddiConfigScreen()),
    ),
    GoRoute(
      path: AppPaths.khabaddi,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const KhabaddiScreen()),
    ),

    /// Universal Game Screen
    GoRoute(
      path: AppPaths.universalConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const UniversalGameConfigScreen()),
    ),
    GoRoute(
      path: AppPaths.universal,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const UniversalGameScreen()),
    ),

    /// 🏹 Archery Screen
    ///
    GoRoute(
      path: AppPaths.archery,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: ArcheryIdleScreen(
          onLetsPlay: () =>
              context.pushReplacement(AppPaths.archeryModeSelection),
          bleService: sl<BleService>(),
          archeryBleMapper: sl<ArcheryBleMapper>(),
        ),
      ),
    ),
    GoRoute(
      path: AppPaths.archeryGame,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const ArcheryScreen()),
    ),
    GoRoute(
      path: AppPaths.archeryAlternateScreen,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const ArcheryAlternateScreen()),
    ),

    GoRoute(
      path: AppPaths.archeryIndividualRoundScreen,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const ArcheryIndividualScreen()),
    ),

    GoRoute(
      path: AppPaths.archeryAlternateScreen,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const ArcheryAlternateScreen()),
    ),

    /// 🏹 Archery Config Screen
    GoRoute(
      path: AppPaths.archeryConfig,
      pageBuilder: (context, state) {
        final initialMode = state.extra is ArcheryMode
            ? state.extra as ArcheryMode
            : ArcheryMode.abcd;
        return adaptivePage(
          state: state,
          child: ArcheryConfigScreen(initialMode: initialMode),
        );
      },
    ),

    GoRoute(
      path: AppPaths.archeryIndividualConfig,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const ArcheryIndividualConfigScreen(),
      ),
    ),

    GoRoute(
      path: AppPaths.archeryTeamConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const ArcheryTeamConfigScreen()),
    ),

    GoRoute(
      path: AppPaths.archeryTeamRoundScreen,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const ArcheryTeamScreen()),
    ),

    //// All ABCD Screens
    GoRoute(
      path: AppPaths.archeryAbcdScreen,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const AbcdScreen()),
    ),

    GoRoute(
      path: AppPaths.archeryAbcScreen,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const AbcScreen()),
    ),

    GoRoute(
      path: AppPaths.archeryAb_CdScreen,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const Ab_CdScreen()),
    ),

    /// All ABCD Config Screen
    GoRoute(
      path: AppPaths.archeryAbcdConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const AbcdConfigScreen()),
    ),

    GoRoute(
      path: AppPaths.archeryAbcConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const AbcConfigScreen()),
    ),

    GoRoute(
      path: AppPaths.archeryAb_CdConfig,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const Ab_CdConfigScreen()),
    ),

    /////////   Archery Mode Selection Screen /////////
    GoRoute(
      path: AppPaths.archeryModeSelection,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: ArcheryModeSelectionScreen(
          onQualificationAbcdSelected: () =>
              context.push(AppPaths.archeryAbcdConfig),
          onQualificationAbcSelected: () =>
              context.push(AppPaths.archeryAbcConfig),
          onQualificationAb_CdSelected: () =>
              context.push(AppPaths.archeryAb_CdConfig),
          onIndividualRoundSelected: () =>
              context.push(AppPaths.archeryIndividualConfig),
          onTeamRoundSelected: () => context.push(AppPaths.archeryTeamConfig),
        ),
      ),
    ),

    GoRoute(
      path: AppPaths.archeryAlternateConfig,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const ArcheryAlternateConfigScreen(),
      ),
    ),

    /// ⚙️ Login Screen
    GoRoute(
      path: AppPaths.login,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const LoginScreen()),
    ),

    /// 🛠 Feature Selection Screen
    GoRoute(
      path: AppPaths.featureSelection,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const FeatureSelectionScreen()),
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
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const HomeScreen()),
    ),

    // // Bluetooth Screen
    // GoRoute(
    //   path: AppPaths.ble_scan,
    //   pageBuilder: (context, state) =>
    //       adaptivePage(state: state, child: const BluetoothScanScreen()),
    // ),
    GoRoute(
      path: AppPaths.ble_permission,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const PermissionGate(child: FeatureSelectionScreen()),
      ),
    ),

    /// Heart Tracker Routes Start from Here
    ///
    GoRoute(
      path: HeartTrackerPaths.chooseProfile,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const ProfileChooseScreen()),
    ),

    GoRoute(
      path: HeartTrackerPaths.individualProfileRegistration,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const IndiviProfileRegistrationScreen(),
      ),
    ),

    ShellRoute(
      builder: (context, state, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ShellCubit()),
            BlocProvider.value(value: sl<HeartBleCubit>()),
          ],
          child: IndiviMainScreen(child: child),
        );
      },
      routes: [
        // Tab 0 — Feature Selection
        GoRoute(
          path: HeartTrackerPaths.indiviHomeMobile,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const IndiviHomeMobile()),
        ),
        // Tab 1 — Scoreboard Home
        GoRoute(
          path: HeartTrackerPaths.indiviActivityMobile,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const IndiviActivityMobile()),
        ),

        // Tab 2 — Heart Tracker
        GoRoute(
          path: HeartTrackerPaths.indiviProfileMobile,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const IndiviProfileMobile()),
        ),

        // Tab 3 — History
        GoRoute(
          path: HeartTrackerPaths.indiviHistoryMobile,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const IndiviHistoryMobile()),
        ),
      ],
    ),

    GoRoute(
      path: HeartTrackerPaths.heartBleSelectionScreen,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: const HeartRateBleSelectionScreen(),
      ),
    ),

    /// Timing Gate BLE Connection Screen (gate before main screen)
    GoRoute(
      path: TimingGatePaths.timingGateBle,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const TimingGateBleScreen()),
    ),

    /// Timing Gate Session Detail (full-screen, outside shell)
    GoRoute(
      path: TimingGatePaths.timingGateSessionDetail,
      pageBuilder: (context, state) {
        final session = state.extra as TestSessionModel;
        return adaptivePage(
          state: state,
          child: SessionDetailScreen(session: session),
        );
      },
    ),

    /// Timing Gate Session Wizard (full-screen, outside shell)
    GoRoute(
      path: TimingGatePaths.timingGateSession,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: BlocProvider(
          create: (ctx) => sl<TimingSessionCubit>(),
          child: const TimingSessionScreen(),
        ),
      ),
    ),

    /// Timing Gate Routes Start from Here
    ShellRoute(
      builder: (context, state, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ShellCubit()),
            BlocProvider.value(value: sl<TimingGateBleCubit>()),
            BlocProvider(
              create: (_) => sl<AthletesCubit>()..initialize(),
            ),
          ],
          child: BackButtonListener(
            onBackButtonPressed: () async {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
                return true;
              }
              final shouldExit = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Row(children: [
                    Icon(Icons.exit_to_app, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text('Exit Sports IQ?',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
                  content: const Text(
                      'Kya aap Sports IQ se bahar jaana chahte hain?',
                      style: TextStyle(color: Color(0xFF6B7A8D))),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Exit',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (shouldExit == true) SystemNavigator.pop();
              return true;
            },
            child: const TimingGateMainScreen(),
          ),
        );
      },
      routes: [
        GoRoute(
          path: TimingGatePaths.timingGateHomeMobile,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const TimingGateHomeMobile()),
        ),
        GoRoute(
          path: TimingGatePaths.timingGateResultsMobile,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const TimingGateResultsMobile()),
        ),
        GoRoute(
          path: TimingGatePaths.timingGateAthletesMobile,
          pageBuilder: (context, state) => adaptivePage(
            state: state,
            child: const TimingGateAthletesMobile(),
          ),
        ),
        GoRoute(
          path: TimingGatePaths.timingGateProfileMobile,
          pageBuilder: (context, state) => adaptivePage(
            state: state,
            child: const TimingGateProfileMobile(),
          ),
        ),
      ],
    ),
  ],
);
