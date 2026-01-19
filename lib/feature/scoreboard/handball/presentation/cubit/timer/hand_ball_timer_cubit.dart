import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/handball_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'hand_ball_timer_state.dart';

class HandBallTimerCubit extends Cubit<HandBallTimerState> {
  Timer? _timer;
  static int totalSeconds = 5;
  final BleService bleService;
  final HandBallBleMapper ballBleMapper;
  HandBallTimerCubit({
    required this.bleService,
    required this.ballBleMapper
}) : super(HandBallTimerState.initial(totalSeconds));

  /* ================= TIMER CONTROLS ================= */

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
  }

  /// Start timer
  void start() {
    if (state.status == TimerStatus.running) return;

    emit(state.copyWith(status: TimerStatus.running));

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
    bleService.send(ballBleMapper.startTimer());
  }

  /// Pause timer
  void pause() {
    if (state.status != TimerStatus.running) return;

    _timer?.cancel();
    emit(state.copyWith(status: TimerStatus.paused));
    bleService.send(ballBleMapper.stopTimer());
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
    emit(HandBallTimerState.initial(totalSeconds));
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
    bleService.send(ballBleMapper.setQuarter(quarter));
    return true;
  }


  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
