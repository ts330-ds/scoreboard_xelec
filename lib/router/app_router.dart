import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/auth/presentation/screen/loginScreen.dart';
import 'package:xelex_esp/feature/bluetooth/presentation/screen/device_selection_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/auth/presentation/cubit/athlete_auth_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/cubit/shell_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/athlete_task_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/screen/athlete_task_detail_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/screen/task_result_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/screen/ble_fetch_demo_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_result_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/usecase/get_task_result_usecase.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/health_monitor/presentation/cubit/athlete_health_monitor_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/layout/athlete_activity_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/presentation/screen/athlete_history_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/layout/athlete_home_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/layout/athlete_profile_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/screen/athlete_main_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/screen/athlete_sleep_detail_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/screen/athlete_hrv_detail_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/notification/presentation/screen/athlete_notification_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/registration/presentation/screen/athlete_registration_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/auth/presentation/cubit/coach_auth_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/auth/presentation/screen/coach_login_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/dashboard/presentation/cubit/coach_shell_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/dashboard/presentation/layout/coach_home_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/dashboard/presentation/layout/coach_profile_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/dashboard/presentation/screen/coach_dashboard_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/registration/presentation/screen/coach_registration_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/my_athletes/domain/entity/my_athlete_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/my_athletes/presentation/cubit/my_athletes_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/my_athletes/presentation/screen/athlete_detail_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/my_athletes/presentation/screen/my_athletes_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/request/domain/entity/athlete_search_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_now/presentation/screen/coach_live_now_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/request/presentation/screen/coach_athlete_search_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/request/presentation/screen/coach_send_request_screen.dart';
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
import 'package:xelex_esp/feature/timing_gates/profile/presentation/cubit/profile_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/athletes/athletes_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/screen/session_detail_screen.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/screen/timing_session_screen.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/test_session_model.dart';
import 'package:xelex_esp/feature/splash/presentation/screen/splash_screen.dart';
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
  initialLocation: AppPaths.splash,
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
    /// Splash Screen
    GoRoute(
      path: AppPaths.splash,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const SplashScreen()),
    ),

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

    /// ── Athlete Notification ─────────────────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.athleteNotification,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const AthleteNotificationScreen()),
    ),

    /// ── Athlete Sleep Detail ─────────────────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.athleteSleepDetail,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: BlocProvider.value(
          value: sl<HeartBleCubit>(),
          child: const AthleteSleepDetailScreen(),
        ),
      ),
    ),

    /// ── Athlete HRV Detail ───────────────────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.athleteHrvDetail,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: BlocProvider.value(
          value: sl<HeartBleCubit>(),
          child: const AthleteHrvDetailScreen(),
        ),
      ),
    ),

    /// ── Athlete Task Detail (full-screen, outside ShellRoute — no bottom nav) ─
    GoRoute(
      path: HeartTrackerPaths.athleteTaskDetail,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final task = extra['task'] as AthleteTaskEntity;
        final activityCubit = extra['activityCubit'] as AthleteActivityCubit;
        return adaptivePage(
          state: state,
          child: BlocProvider.value(
            value: sl<HeartBleCubit>(),
            child: AthleteTaskDetailScreen(
              task: task,
              activityCubit: activityCubit,
            ),
          ),
        );
      },
    ),

    /// ── Athlete Task Result (completed task results screen) ──────────────────
    GoRoute(
      path: HeartTrackerPaths.athleteTaskResult,
      pageBuilder: (context, state) {
        final task = state.extra as AthleteTaskEntity;
        return adaptivePage(
          state: state,
          child: BlocProvider(
            create: (_) => TaskResultCubit(
              taskId: task.id,
              getTaskResult: sl<GetTaskResultUseCase>(),
            )..load(),
            child: TaskResultScreen(task: task),
          ),
        );
      },
    ),

    /// ── BLE Fetch Demo (testing screen) ───────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.bleFetchDemo,
      pageBuilder: (context, state) {
        return adaptivePage(
          state: state,
          child: const BleFetchDemoScreen(),
        );
      },
    ),

    /// ── Athlete Registration ─────────────────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.athleteRegistration,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const AthleteRegistrationScreen()),
    ),

    /// ── Athlete Dashboard (ShellRoute with bottom nav) ───────────────────────
    ShellRoute(
      builder: (context, state, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AthleteShellCubit()),
            BlocProvider(create: (_) => sl<AthleteAuthCubit>()),
            BlocProvider.value(value: sl<HeartBleCubit>()),
            // Health monitor — BLE connect hote hi 24/7 socket shuru ho jaata hai
            BlocProvider.value(value: sl<AthleteHealthMonitorCubit>()),
          ],
          child: BackButtonListener(
            onBackButtonPressed: () async {
              // Agar koi screen stack me hai toh pehle wo pop karo
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
                return true;
              }
              // Warna exit confirmation dialog dikhao
              final shouldExit = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Color(0xFF1565C0)),
                      SizedBox(width: 8),
                      Text(
                        'Exit App?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Are you sure you want to exit the app?',
                    style: TextStyle(color: Color(0xFF6B7A8D)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Exit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (shouldExit == true) SystemNavigator.pop();
              return true;
            },
            child: AthleteMainScreen(child: child),
          ),
        );
      },
      routes: [
        GoRoute(
          path: HeartTrackerPaths.athleteHome,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const AthleteHomeMobile()),
        ),
        GoRoute(
          path: HeartTrackerPaths.athleteActivity,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const AthleteActivityMobile()),
        ),
        GoRoute(
          path: HeartTrackerPaths.athleteProfile,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const AthleteProfileMobile()),
        ),
        GoRoute(
          path: HeartTrackerPaths.athleteHistory,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const AthleteHistoryScreen()),
        ),
      ],
    ),

    /// ── Coach Login ──────────────────────────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.coachLogin,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const CoachLoginScreen()),
    ),

    /// ── Coach Registration ───────────────────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.coachRegistration,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const CoachRegistrationScreen()),
    ),

    /// ── Coach Athlete Search ─────────────────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.coachAthleteSearch,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const CoachAthleteSearchScreen()),
    ),

    /// ── Coach Send Request ───────────────────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.coachSendRequest,
      pageBuilder: (context, state) {
        final athlete = state.extra as AthleteSearchEntity;
        return adaptivePage(
          state: state,
          child: CoachSendRequestScreen(athlete: athlete),
        );
      },
    ),

    /// ── Coach My Athletes ────────────────────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.coachMyAthletes,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const MyAthletesScreen()),
    ),

    /// ── Coach Athlete Detail ─────────────────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.coachAthleteDetail,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final preview = extra['preview'] as MyAthleteEntity;
        final listCubit = extra['listCubit'] as MyAthletesCubit;
        return adaptivePage(
          state: state,
          child: AthleteDetailScreen(preview: preview, listCubit: listCubit),
        );
      },
    ),

    /// ── Coach Live Now ───────────────────────────────────────────────────────
    GoRoute(
      path: HeartTrackerPaths.coachLiveNow,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const CoachLiveNowScreen()),
    ),

    /// ── Coach Dashboard (ShellRoute with bottom nav) ────────────────────────
    ShellRoute(
      builder: (context, state, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => CoachShellCubit()),
            BlocProvider(create: (_) => sl<CoachAuthCubit>()),
          ],
          child: CoachDashboardScreen(child: child),
        );
      },
      routes: [
        GoRoute(
          path: HeartTrackerPaths.coachHome,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const CoachHomeMobile()),
        ),
        GoRoute(
          path: HeartTrackerPaths.coachProfile,
          pageBuilder: (context, state) =>
              adaptivePage(state: state, child: const CoachProfileMobile()),
        ),
      ],
    ),

    /// Timing Gate BLE Connection Screen (gate before main screen)
    GoRoute(
      path: TimingGatePaths.timingGateBle,
      pageBuilder: (context, state) =>
          adaptivePage(state: state, child: const TimingGateBleScreen()),
    ),

    /// Timing Gate Session Detail (full-screen, outside shell)
    /// ProfileCubit needed for PDF export — conductor name in header
    GoRoute(
      path: TimingGatePaths.timingGateSessionDetail,
      pageBuilder: (context, state) {
        final session = state.extra as TestSessionModel;
        return adaptivePage(
          state: state,
          child: BlocProvider.value(
            value: sl<ProfileCubit>(),
            child: SessionDetailScreen(session: session),
          ),
        );
      },
    ),

    /// Timing Gate Session Wizard (full-screen, outside shell)
    /// ProfileCubit needed for PDF export in StepResults
    GoRoute(
      path: TimingGatePaths.timingGateSession,
      pageBuilder: (context, state) => adaptivePage(
        state: state,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (ctx) => sl<TimingSessionCubit>()),
            BlocProvider.value(value: sl<ProfileCubit>()),
          ],
          child: const TimingSessionScreen(),
        ),
      ),
    ),

    /// Timing Gate Routes — StatefulShellRoute.indexedStack
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: sl<TimingGateBleCubit>()),
            BlocProvider.value(value: sl<AthletesCubit>()),
            BlocProvider.value(value: sl<ProfileCubit>()),
          ],
          child: BackButtonListener(
            onBackButtonPressed: () async {
              // Agar session screen active hai to uska PopScope khud handle karega
              final currentPath = appRouter.state.uri.path;
              if (currentPath == TimingGatePaths.timingGateSession ||
                  currentPath == TimingGatePaths.timingGateSessionDetail) {
                return false;
              }
              
              // Shell ki root tab par hain — exit dialog dikhao
              final shouldExit = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Color(0xFF1565C0)),
                      SizedBox(width: 8),
                      Text(
                        'Exit Timing Gate?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Are you sure, you want to exit ?',
                    style: TextStyle(color: Color(0xFF6B7A8D)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Exit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (shouldExit == true) SystemNavigator.pop();
              return true;
            },
            child: TimingGateMainScreen(navigationShell: navigationShell),
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: TimingGatePaths.timingGateHomeMobile,
              pageBuilder: (context, state) => adaptivePage(
                state: state,
                child: const TimingGateHomeMobile(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: TimingGatePaths.timingGateResultsMobile,
              pageBuilder: (context, state) => adaptivePage(
                state: state,
                child: const TimingGateResultsMobile(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: TimingGatePaths.timingGateAthletesMobile,
              pageBuilder: (context, state) => adaptivePage(
                state: state,
                child: const TimingGateAthletesMobile(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
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
    ),
  ],
);
