import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/handball_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'hand_ball_timer_state.dart';

class HandBallTimerCubit extends Cubit<HandBallTimerState> {
  Timer? _timer;
  static int totalSeconds = 5;

  final BleService bleService;
  final HandBallBleMapper ballBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  HandBallTimerCubit({
    required this.bleService,
    required this.ballBleMapper,
    required this.globalErrorCubit,
  }) : super(HandBallTimerState.initial(totalSeconds));

  /* ================= TIMER CONTROLS ================= */

  /// Set match/quarter time manually
  void setTime(int totalSeconds) {
    try {
      _timer?.cancel();
      emit(
        state.copyWith(
          seconds: totalSeconds,
          initialSeconds: totalSeconds,
          status: TimerStatus.initial,
        ),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to set time: $e');
    }
  }

  /// Start timer
  void start() {
    try {
      if (state.status == TimerStatus.running) return;

      emit(state.copyWith(status: TimerStatus.running));

      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          try {
            if (state.seconds <= 1) {
              timer.cancel();
              emit(
                state.copyWith(
                  seconds: 0,
                  status: TimerStatus.finished,
                ),
              );
            } else {
              emit(state.copyWith(seconds: state.seconds - 1));
            }
          } catch (e) {
            globalErrorCubit.showError('Timer tick error: $e');
          }
        },
      );

      bleService.send(ballBleMapper.startTimer());
    } catch (e) {
      globalErrorCubit.showError('Failed to start timer: $e');
    }
  }

  /// Pause timer
  void pause() {
    try {
      if (state.status != TimerStatus.running) return;

      _timer?.cancel();
      emit(state.copyWith(status: TimerStatus.paused));
      bleService.send(ballBleMapper.pauseTimer());
    } catch (e) {
      globalErrorCubit.showError('Failed to pause timer: $e');
    }
  }

  /// Resume timer
  void resume() {
    try {
      if (state.status != TimerStatus.paused) return;
      start();
      bleService.send(ballBleMapper.startTimer());
    } catch (e) {
      globalErrorCubit.showError('Failed to resume timer: $e');
    }
  }

  /// Reset everything
  void reset() {
    try {
      _timer?.cancel();
      emit(HandBallTimerState.initial(totalSeconds));
    } catch (e) {
      globalErrorCubit.showError('Failed to reset timer: $e');
    }
  }

  /// Manually set quarter (1–4)
  /// Allowed only when timer is NOT running
  bool setQuarter(int quarter) {
    try {
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
    } catch (e) {
      globalErrorCubit.showError('Failed to set quarter: $e');
      return false;
    }
  }

  @override
  Future<void> close() {
    try {
      _timer?.cancel();
    } catch (_) {}
    return super.close();
  }
}
