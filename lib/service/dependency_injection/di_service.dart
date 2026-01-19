import 'package:get_it/get_it.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/game_select_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/hockey_ble_mapper.dart';
import '../../feature/bluetooth/mapper/basketball_ble_mapper.dart';
import '../../feature/bluetooth/mapper/handball_ble_mapper.dart';
import '../../feature/bluetooth/presentation/cubit/ble/ble_cubit.dart';
import '../../feature/bluetooth/presentation/cubit/scan/ble_scan_cubit.dart';
import '../../feature/bluetooth/service/ble_service.dart';
import '../../feature/permission/bluetooth/cubit/bluetooth_cubit.dart';
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
  sl.registerLazySingleton<BluetoothPermissionService>(() => BluetoothPermissionService());
  
  // Mappers
  sl.registerLazySingleton<BasketBallBleMapper>(() => BasketBallBleMapper());
  sl.registerLazySingleton<HandBallBleMapper>(() => HandBallBleMapper());
  sl.registerLazySingleton<GameSelectBleMapper>(() => GameSelectBleMapper());
  sl.registerLazySingleton<HockeyBleMapper>(()=> HockeyBleMapper());

  // Bluetooth Cubits
  sl.registerLazySingleton<BleCubit>(() => BleCubit(sl(),sl()));
  sl.registerLazySingleton<BluetoothScanCubit>(() => BluetoothScanCubit());
  sl.registerLazySingleton<PermissionCubit>(() => PermissionCubit(sl()));

  // Basketball Cubits
  sl.registerLazySingleton<BasketControlPanelCubit>(
    () => BasketControlPanelCubit(
      bleService: sl(), 
      basketBallBleMapper: sl(),
    ),
  );
  sl.registerLazySingleton<ShotClockCubit>(() => ShotClockCubit(
    bleService: sl(),
    ballBleMapper: sl(),
  ));
  sl.registerLazySingleton<BasketBallTimerCubit>(() => BasketBallTimerCubit(
    bleService: sl(),
    ballBleMapper: sl(),
  ));

  // Football Cubits
  sl.registerLazySingleton<FootballControllerCubit>(() => FootballControllerCubit());
  sl.registerLazySingleton<FootballTimerCubit>(() => FootballTimerCubit());

  // Handball Cubits
  sl.registerLazySingleton<HandBallControlCubit>(() => HandBallControlCubit(bleService: sl(), ballBleMapper: sl()));
  sl.registerLazySingleton<HandBallTimerCubit>(() => HandBallTimerCubit(
    bleService: sl(),
    ballBleMapper: sl(),
  ));

  // Hockey Cubits
  sl.registerLazySingleton<HockeyControllerCubit>(() => HockeyControllerCubit(
    bleService: sl(),
    bleMapper: sl(),
  ));
  sl.registerLazySingleton<HockeyTimerCubit>(() => HockeyTimerCubit());

  // Kho Kho Cubits
  sl.registerLazySingleton<KhokhoControllerCubit>(() => KhokhoControllerCubit());
  sl.registerLazySingleton<MatchTimerCubit>(() => MatchTimerCubit());
  sl.registerLazySingleton<KhokhoTimerCubit>(() => KhokhoTimerCubit());

  // Table Tennis Cubits
  sl.registerLazySingleton<TableTennisControllerCubit>(() => TableTennisControllerCubit());
}
