import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import '../../../../../bluetooth/mapper/basketball_ble_mapper.dart';
import 'shot_clock_state.dart';

class ShotClockCubit extends Cubit<ShotClockState> {
  Timer? _timer;
  final BleService bleService;
  final BasketBallBleMapper ballBleMapper;
  ShotClockCubit({
    required this.bleService,
    required this.ballBleMapper
}) : super(const ShotClockState());

  void start() {
    emit(state.copyWith(status: ShotClockStatus.running));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 24), (timer) {
      if (state.seconds <= 1) {
        timer.cancel();
        emit(state.copyWith(seconds: 0, status: ShotClockStatus.expired));
      } else {
        emit(state.copyWith(seconds: state.seconds - 1));
      }
    });
  }

  void pause() {
    _timer?.cancel();
    emit(state.copyWith(status: ShotClockStatus.paused));
    bleService.send(ballBleMapper.resetShotTimer());
  }

  void reset() {
    _timer?.cancel();
    // Reset to 24 and immediately emit running status
    emit(const ShotClockState(seconds: 24, status: ShotClockStatus.running));
    
    // Start the timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.seconds <= 1) {
        timer.cancel();
        emit(state.copyWith(seconds: 0, status: ShotClockStatus.expired));
      } else {
        emit(state.copyWith(seconds: state.seconds - 1));
      }
    });
    bleService.send(ballBleMapper.resetShotTimer());
  }

  void stop() {
    _timer?.cancel();
    emit(const ShotClockState(seconds: 24, status: ShotClockStatus.initial));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
