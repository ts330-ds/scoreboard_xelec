import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/basketball_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'basketball_timer_state.dart';

class BasketBallTimerCubit extends Cubit<BasketBallTimerState> {
  Timer? _timer;

  /// Total time per quarter in seconds (default 15 min = 900s)
  int totalSeconds = 900;

  final BasketBallBleMapper ballBleMapper;
  final BleService bleService;
  final GlobalErrorCubit globalErrorCubit;

  BasketBallTimerCubit({
    required this.bleService,
    required this.ballBleMapper,
    required this.globalErrorCubit,
  }) : super(BasketBallTimerState.initial(900));

  /// Set match/quarter time manually (in seconds)
  void setTime(int seconds) {
    try {
      _timer?.cancel();

      totalSeconds = seconds*60;

      emit(
        state.copyWith(
          seconds: seconds*60,
          initialSeconds: seconds*60,
          status: TimerStatus.initial,
        ),
      );

      // Send formatted time MM:SS to BLE device
      bleService.send(ballBleMapper.setTimerMinutes(seconds));
    } catch (e) {
      globalErrorCubit.showError('Failed to set time: $e');
    }
  }

  /// Start timer
  void start() {
    try {
      if (state.status == TimerStatus.running) return;

      emit(state.copyWith(status: TimerStatus.running));
      bleService.send(ballBleMapper.startTimer());

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        try {
          if (isClosed) {
            timer.cancel();
            return;
          }
          if (state.seconds <= 1) {
            timer.cancel();
            emit(state.copyWith(seconds: 0, status: TimerStatus.finished));
            // Send final 00:00 to BLE device
            bleService.send(ballBleMapper.setTime(0));
          } else {
            final newSeconds = state.seconds - 1;
            emit(state.copyWith(seconds: newSeconds));
          }
        } catch (e) {
          globalErrorCubit.showError('Timer tick error: $e');
        }
      });
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

      start(); // already handles BLE
    } catch (e) {
      globalErrorCubit.showError('Failed to resume timer: $e');
    }
  }

  /// Reset timer to initial seconds
  void reset() {
    try {
      _timer?.cancel();
      emit(state.copyWith(
        seconds: state.initialSeconds,
        status: TimerStatus.initial,
      ));
      bleService.send(ballBleMapper.resetTimer());
      // Send reset time to BLE device
      bleService.send(ballBleMapper.setTime(state.initialSeconds));
    } catch (e) {
      globalErrorCubit.showError('Failed to reset timer: $e');
    }
  }

  /// Reset to default state (called on exit)
  void resetToDefault() {
    try {
      _timer?.cancel();
      emit(BasketBallTimerState.initial(900));
    } catch (e) {
      globalErrorCubit.showError('Failed to reset to default: $e');
    }
  }

  /// Manually set quarter (1–4)
  bool setQuarter(int quarter) {
    try {
      if (quarter < 1 || quarter > 4) return false;

      if (state.status == TimerStatus.running) {
        return false;
      }

      emit(
        state.copyWith(
          quarter: quarter,
          seconds: state.initialSeconds,
          status: TimerStatus.initial,
        ),
      );
      bleService.send(ballBleMapper.setQuarter(quarter));
      // Send reset time for the new quarter
      bleService.send(ballBleMapper.setTime(state.initialSeconds));
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
