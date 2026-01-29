import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/basketball_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'basketball_timer_state.dart';

class BasketBallTimerCubit extends Cubit<BasketBallTimerState> {
  Timer? _timer;

  static int totalSeconds = 900;
  final BasketBallBleMapper ballBleMapper;
  final BleService bleService;
  BasketBallTimerCubit({
    required this.bleService,
    required this.ballBleMapper
}) : super(BasketBallTimerState.initial(totalSeconds));

  /// Set match/quarter time manually
  void setTime(int totalSeconds) {
    _timer?.cancel();
    emit(
      state.copyWith(
        seconds: totalSeconds,
        initialSeconds: totalSeconds,
        status: TimerStatus.initial,
      ),
    );
    bleService.send(ballBleMapper.setTimerMinutes(totalSeconds));
  }

  /// Start timer
  void start() {
    if (state.status == TimerStatus.running) return;

    emit(state.copyWith(status: TimerStatus.running));
    bleService.send(ballBleMapper.startTimer());
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (state.seconds <= 1) {
          timer.cancel();
          emit(
            state.copyWith(
              seconds: 0,
              status: TimerStatus.finished, // timer stopped
            ),
          );
        } else {
          emit(state.copyWith(seconds: state.seconds - 1));
        }
      },
    );
  }

  /// Pause timer
  void pause() {
    if (state.status != TimerStatus.running) return;

    _timer?.cancel();
    emit(state.copyWith(status: TimerStatus.paused));
    bleService.send(ballBleMapper.pauseTimer());
  }

  /// Resume timer
  void resume() {
    if (state.status != TimerStatus.paused) return;
    start();
    bleService.send(ballBleMapper.startTimer());
  }

  /// Reset everything
  void reset() {
    _timer?.cancel();
    emit(BasketBallTimerState.initial(totalSeconds));
    bleService.send(ballBleMapper.resetTimer());
  }

  /// Manually set quarter (1–4)
  /// Allowed only when timer is NOT running
  bool setQuarter(int quarter) {
    if (quarter < 1 || quarter > 4) return false;

    if (state.status == TimerStatus.running) {
      print("Yaa its false");
      return false;
    }

    emit(
      state.copyWith(
        quarter: quarter,
        seconds: totalSeconds,
        status: TimerStatus.initial,
      ),
    );
    switch (quarter) {
      case 1:
        bleService.send(ballBleMapper.setQuarter1());
        break;
      case 2:
        bleService.send(ballBleMapper.setQuarter2());
        break;
      case 3:
        bleService.send(ballBleMapper.setQuarter3());
        break;
      case 4:
        bleService.send(ballBleMapper.setQuarter4());
        break;
      default:
        return false;
    }
    return true;
  }


  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
