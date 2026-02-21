import 'package:get_it/get_it.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/badminton_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/football_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/hockey_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/kabaddi_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/table_tennis_ble_mapper.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
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
import '../../feature/permission/bluetooth/cubit/bluetooth_cubit.dart';
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

void setupDI() {
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

  sl.registerLazySingleton<HeartBleCubit>(
    () => HeartBleCubit(errorCubit: sl()));
}
