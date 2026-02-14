import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import '../../../../../bluetooth/mapper/basketball_ble_mapper.dart';
import 'shot_clock_state.dart';

class ShotClockCubit extends Cubit<ShotClockState> {
  Timer? _timer;
  final BleService bleService;
  final BasketBallBleMapper ballBleMapper;
  ShotClockCubit({required this.bleService, required this.ballBleMapper})
    : super(const ShotClockState());

  void start() {
    _timer?.cancel();
    // If paused, resume from current time. If initial or expired, start from 24
    if (state.status == ShotClockStatus.initial ||
        state.status == ShotClockStatus.expired) {
      emit(const ShotClockState(seconds: 24, status: ShotClockStatus.initial));
    } else {
      emit(state.copyWith(status: ShotClockStatus.running));
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      if (state.seconds <= 1) {
        // Timer expired, restart from 24 automatically
        emit(
          const ShotClockState(seconds: 24, status: ShotClockStatus.running),
        );
      } else {
        emit(state.copyWith(seconds: state.seconds - 1));
      }
    });
    bleService.send(ballBleMapper.startShotClock());
  }

  void pause() {
    _timer?.cancel();
    emit(state.copyWith(status: ShotClockStatus.paused));
    bleService.send(ballBleMapper.resetShotClock());
  }

  void reset() {
    _timer?.cancel();
    // Reset to 24 without starting
    emit(const ShotClockState(seconds: 24, status: ShotClockStatus.initial));
    bleService.send(ballBleMapper.resetShotClock());
    start();
  }

  void stop() {
    _timer?.cancel();
    emit(const ShotClockState(seconds: 24, status: ShotClockStatus.initial));
  }

  /// Reset to default state (called on exit)
  void resetToDefault() {
    _timer?.cancel();
    emit(const ShotClockState(seconds: 24, status: ShotClockStatus.initial));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
