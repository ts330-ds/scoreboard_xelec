import 'package:get_it/get_it.dart';
import 'package:xelex_esp/service/api/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/data/repository/sport_repository_impl.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/data/source/sport_local_datasource.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/data/source/sport_remote_datasource.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/domain/repository/sport_repository.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/domain/usecase/get_sports_usecase.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_cubit.dart';
import 'package:xelex_esp/feature/auth/data/datasource/auth_remote_datasource.dart';
import 'package:xelex_esp/feature/auth/data/repository/auth_repository_impl.dart';
import 'package:xelex_esp/feature/auth/domain/repository/auth_repository.dart';
import 'package:xelex_esp/feature/auth/domain/usecase/sign_in_with_google_usecase.dart';
import 'package:xelex_esp/feature/auth/domain/usecase/sign_in_with_linkedin_usecase.dart';
import 'package:xelex_esp/feature/auth/domain/usecase/sign_in_with_microsoft_usecase.dart';
import 'package:xelex_esp/feature/auth/domain/usecase/sign_in_with_apple_usecase.dart';
import 'package:xelex_esp/feature/auth/domain/usecase/sign_out_usecase.dart';
import 'package:xelex_esp/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/badminton_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/football_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/hockey_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/kabaddi_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/table_tennis_ble_mapper.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/data/cubit/bluetooth_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/profile/data/repository/profile_repository.dart';
import 'package:xelex_esp/feature/timing_gates/profile/presentation/cubit/profile_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/athletes/athletes_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/repository/athlete_repository.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/repository/session_repository.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/data/timing_gate_ble_service.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/presentation/cubit/timing_gate_bluetooth_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/profile_registration/presentation/cubit/indivi_profile_registration_cubit/profile_registration_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/ab_cd_cubit/ab_cd_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/abc_cubit/abc_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/abcd_cubit/abcd_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/alternate_game_controller/archery_alternate_game_controller.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/alternate_game_timer/archery_alternate_game_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/individual_cubit/timer/archery_individual_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/teams_cubit/timer/archery_team_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/cubit/controller/universal_game_controller_cubit.dart';
import '../../feature/bluetooth/mapper/basketball_ble_mapper.dart';
import '../../feature/bluetooth/mapper/handball_ble_mapper.dart';
import '../../feature/bluetooth/mapper/khokho_ble_mapper.dart';
import '../../feature/bluetooth/mapper/universal_game_ble_mapper.dart';
import '../../feature/scoreboard/archery/presentation/cubit/controller/archery_controller_cubit.dart';
import '../../feature/scoreboard/archery/presentation/cubit/timer/archery_timer_cubit.dart';
import '../../feature/bluetooth/presentation/cubit/ble/ble_cubit.dart';
import '../../feature/bluetooth/presentation/cubit/scan/ble_scan_cubit.dart';
import '../../feature/bluetooth/service/ble_service.dart';
import '../../feature/scoreboard/Kabaddi/presentation/cubit/controller/kabaddi_controller_cubit.dart';
import '../../feature/scoreboard/Kabaddi/presentation/cubit/timer/kabaddi_timer_cubit.dart';
import '../../feature/scoreboard/badminton/presentation/cubit/controller/badminton_controller_cubit.dart';
import '../../feature/scoreboard/basketball/presentation/cubit/controlPanal/controlPanalCubit.dart';
import '../../feature/scoreboard/basketball/presentation/cubit/shot_clock/shot_clock_cubit.dart';
import '../../feature/scoreboard/basketball/presentation/cubit/timer/basketball_timer_cubit.dart';
import '../../feature/scoreboard/football/presentation/cubit/controller/football_controller_cubit.dart';
import '../../feature/scoreboard/football/presentation/cubit/timer/football_timer_cubit.dart';
import '../../feature/scoreboard/handball/presentation/cubit/controller/hand_ball_controller_cubit.dart';
import '../../feature/scoreboard/handball/presentation/cubit/timer/hand_ball_timer_cubit.dart';
import '../../feature/scoreboard/hockey/presentation/cubit/controller/hockey_controller_cubit.dart';
import '../../feature/scoreboard/hockey/presentation/cubit/timer/hockey_timer_cubit.dart';
import '../../feature/scoreboard/kho_kho/presentation/cubit/controller/khokho_controller_cubit.dart';
import '../../feature/scoreboard/kho_kho/presentation/cubit/match_timer/match_timer_cubit.dart';
import '../../feature/scoreboard/kho_kho/presentation/cubit/timer/khokho_timer_cubit.dart';
import '../../feature/scoreboard/table_tennis/presentation/cubit/controller/table_tennis_controller_cubit.dart';
import '../permission/bluetooth_permission_service.dart';

final sl = GetIt.instance;

void setupDI({required SharedPreferences sharedPreferences}) {
  // Core
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<ApiService>(() => ApiService.instance);

  // Auth
  sl.registerLazySingleton<GoogleSignIn>(
    () => GoogleSignIn(scopes: ['email', 'profile']),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<SignInWithGoogleUseCase>(
    () => SignInWithGoogleUseCase(sl()),
  );
  sl.registerLazySingleton<SignInWithLinkedInUseCase>(
    () => SignInWithLinkedInUseCase(sl()),
  );
  sl.registerLazySingleton<SignInWithMicrosoftUseCase>(
    () => SignInWithMicrosoftUseCase(sl()),
  );
  sl.registerLazySingleton<SignInWithAppleUseCase>(
    () => SignInWithAppleUseCase(sl()),
  );
  sl.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(sl()),
  );
  sl.registerFactory<AuthCubit>(
    () => AuthCubit(
      signInWithGoogle: sl(),
      signInWithLinkedIn: sl(),
      signInWithMicrosoft: sl(),
      signInWithApple: sl(),
      signOut: sl(),
      pref: sl(),
    ),
  );

  // Services
  sl.registerLazySingleton<BleService>(() => BleService());
  sl.registerLazySingleton<BluetoothPermissionService>(
    () => BluetoothPermissionService(),
  );

  // -------    Mappers- --------
  sl.registerLazySingleton<BasketBallBleMapper>(() => BasketBallBleMapper());
  sl.registerLazySingleton<HandBallBleMapper>(() => HandBallBleMapper());
  sl.registerLazySingleton<HockeyBleMapper>(() => HockeyBleMapper());
  sl.registerLazySingleton<TableTennisBleMapper>(() => TableTennisBleMapper());
  sl.registerLazySingleton<KhoKhoBleMapper>(() => KhoKhoBleMapper());
  sl.registerLazySingleton<FootballBleMapper>(() => FootballBleMapper());
  sl.registerLazySingleton<KabaddiBleMapper>(() => KabaddiBleMapper());
  sl.registerLazySingleton<ArcheryBleMapper>(() => ArcheryBleMapper());
  sl.registerLazySingleton<BadmintonBleMapper>(() => BadmintonBleMapper());
  sl.registerLazySingleton<UniversalGameBleMapper>(
    () => UniversalGameBleMapper(),
  );

  // Bluetooth Cubits
  sl.registerLazySingleton<BleCubit>(() => BleCubit(sl()));
  sl.registerLazySingleton<BluetoothScanCubit>(() => BluetoothScanCubit());
  sl.registerLazySingleton<PermissionCubit>(() => PermissionCubit(sl()));
  sl.registerLazySingleton<GlobalErrorCubit>(() => GlobalErrorCubit());

  // Basketball Cubits
  sl.registerLazySingleton<BasketControlPanelCubit>(
    () => BasketControlPanelCubit(
      bleService: sl(),
      basketBallBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );
  sl.registerLazySingleton<ShotClockCubit>(
    () => ShotClockCubit(bleService: sl(), ballBleMapper: sl()),
  );
  sl.registerLazySingleton<BasketBallTimerCubit>(
    () => BasketBallTimerCubit(
      bleService: sl(),
      ballBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  // Football Cubits
  sl.registerLazySingleton<FootballControllerCubit>(
    () => FootballControllerCubit(
      bleService: sl(),
      footballBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  sl.registerLazySingleton<FootballTimerCubit>(
    () => FootballTimerCubit(
      bleService: sl(),
      footballBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  // Handball Cubits
  sl.registerLazySingleton<HandBallControlCubit>(
    () => HandBallControlCubit(
      bleService: sl(),
      ballBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );
  sl.registerLazySingleton<HandBallTimerCubit>(
    () => HandBallTimerCubit(
      bleService: sl(),
      ballBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  // Hockey Cubits
  sl.registerLazySingleton<HockeyControllerCubit>(
    () => HockeyControllerCubit(
      bleService: sl(),
      bleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );
  sl.registerLazySingleton<HockeyTimerCubit>(
    () => HockeyTimerCubit(
      bleService: sl(),
      hockeyBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  // Kho Kho Cubits
  sl.registerLazySingleton<KhokhoControllerCubit>(
    () => KhokhoControllerCubit(
      bleService: sl(),
      khoBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );
  sl.registerLazySingleton<MatchTimerCubit>(
    () => MatchTimerCubit(bleService: sl(), khoBleMapper: sl()),
  );
  sl.registerLazySingleton<KhokhoTimerCubit>(
    () => KhokhoTimerCubit(
      bleService: sl(),
      khoBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  // Table Tennis Cubits
  sl.registerLazySingleton<TableTennisControllerCubit>(
    () => TableTennisControllerCubit(
      bleService: sl(),
      tableTennisBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  // Kabaddi Cubits
  sl.registerLazySingleton<KabaddiControllerCubit>(
    () => KabaddiControllerCubit(
      bleService: sl(),
      kabaddiBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );
  sl.registerLazySingleton<KabaddiTimerCubit>(
    () => KabaddiTimerCubit(
      bleService: sl(),
      ballBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  sl.registerLazySingleton<BadmintonControllerCubit>(
    () => BadmintonControllerCubit(
      bleService: sl(),
      badmintonBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  sl.registerLazySingleton<UniversalGameControllerCubit>(
    () => UniversalGameControllerCubit(
      bleService: sl(),
      globalErrorCubit: sl(),
      bleMapper: sl(),
    ),
  );

  // Archery Cubits
  sl.registerLazySingleton<ArcheryControllerCubit>(
    () => ArcheryControllerCubit(
      bleService: sl(),
      archeryBleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );
  sl.registerLazySingleton<ArcheryTimerCubit>(
    () => ArcheryTimerCubit(
      bleService: sl(),
      archeryBleMapper: sl(),
      globalErrorToastListener: sl(),
    ),
  );

  sl.registerLazySingleton<ArcheryAlternateGameControllerCubit>(
    () => ArcheryAlternateGameControllerCubit(
      bleService: sl(),
      globalErrorCubit: sl(),
      bleMapper: sl(),
    ),
  );
  sl.registerLazySingleton<ArcheryAlternateGameTimerCubit>(
    () => ArcheryAlternateGameTimerCubit(
      bleService: sl(),
      globalErrorCubit: sl(),
      bleMapper: sl(),
    ),
  );
  sl.registerLazySingleton<ArcheryIndividualTimerCubit>(
    () => ArcheryIndividualTimerCubit(
      bleService: sl(),
      bleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );
  sl.registerLazySingleton<ArcheryTeamTimerCubit>(
    () => ArcheryTeamTimerCubit(
      bleService: sl(),
      bleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  /// ALL ABCD Cubits can be registered here in the future

  sl.registerLazySingleton<AbcdTimerCubit>(
    () => AbcdTimerCubit(
      bleService: sl(),
      bleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  sl.registerLazySingleton<AbcTimerCubit>(
    () => AbcTimerCubit(
      bleService: sl(),
      bleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  sl.registerLazySingleton<Ab_CdTimerCubit>(
    () => Ab_CdTimerCubit(
      bleService: sl(),
      bleMapper: sl(),
      globalErrorCubit: sl(),
    ),
  );

  sl.registerLazySingleton<IndiviProfileRegistrationCubit>(
    () => IndiviProfileRegistrationCubit(),
  );

  // Sport (Common - Heart Rate Tracker)
  sl.registerLazySingleton<SportRemoteDataSource>(
    () => SportRemoteDataSourceImpl(sl<ApiService>()),
  );
  sl.registerLazySingleton<SportLocalDataSource>(
    () => SportLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<SportRepository>(
    () => SportRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<GetSportsUseCase>(
    () => GetSportsUseCase(sl()),
  );
  sl.registerFactory<SportCubit>(
    () => SportCubit(getSports: sl()),
  );

  sl.registerLazySingleton<HeartBleCubit>(
    () => HeartBleCubit(errorCubit: sl()));

  // Timing Gate — BLE
  sl.registerLazySingleton<TimingGateBleService>(() => TimingGateBleService());
  sl.registerLazySingleton<TimingGateBleCubit>(
    () => TimingGateBleCubit(errorCubit: sl(), bleService: sl()),
  );

  // Timing Gate — Athletes
  sl.registerLazySingleton<AthleteRepository>(() => AthleteRepository());
  sl.registerLazySingleton<AthletesCubit>(
    () => AthletesCubit(repository: sl(), errorCubit: sl())..initialize(),
  );

  // Timing Gate — Profile
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepository());
  sl.registerLazySingleton<ProfileCubit>(
    () => ProfileCubit(repository: sl())..loadProfile(),
  );

  // Timing Gate — Sessions
  sl.registerLazySingleton<SessionRepository>(() => SessionRepository());
  sl.registerFactory<TimingSessionCubit>(
    () => TimingSessionCubit(
      errorCubit: sl(),
      sessionRepository: sl(),
      bleService: sl(),
    ),
  );
}
