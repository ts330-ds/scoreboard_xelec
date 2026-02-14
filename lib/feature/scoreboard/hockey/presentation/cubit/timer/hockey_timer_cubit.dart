import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/hockey_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/cubit/timer/hockey_timer_state.dart';

class HockeyTimerCubit extends Cubit<HockeyTimerState> {
  Timer? _timer;

  /// Base duration for each quarter (user configurable)
  int totalSeconds;

  final BleService bleService;
  final HockeyBleMapper hockeyBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  /// Default = 15 minutes (900 seconds)
  HockeyTimerCubit({
    required this.bleService,
    required this.hockeyBleMapper,
    required this.globalErrorCubit,
    int initialSeconds = 900,
  }) : totalSeconds = initialSeconds,
       super(HockeyTimerState.initial(initialSeconds));

  /// Set match/quarter time manually (from user input)
  void setTime(int seconds) {
    try {
      _timer?.cancel();

      totalSeconds = seconds;

      emit(
        state.copyWith(
          seconds: seconds,
          initialSeconds: seconds,
          status: TimerStatus.initial,
        ),
      );

      bleService.send(hockeyBleMapper.setTimerMinutes(seconds ~/ 60));
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
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        try {
          if (isClosed) {
            timer.cancel();
            return;
          }
          if (state.seconds <= 1) {
            timer.cancel();
            emit(state.copyWith(seconds: 0, status: TimerStatus.finished));
            bleService.send(hockeyBleMapper.resetTimer());
          } else {
            emit(state.copyWith(seconds: state.seconds - 1));
          }
        } catch (e) {
          globalErrorCubit.showError('Timer tick error: $e');
        }
      });
      bleService.send(hockeyBleMapper.startTimer());
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
      bleService.send(hockeyBleMapper.pauseTimer());
    } catch (e) {
      globalErrorCubit.showError('Failed to pause timer: $e');
    }
  }

  /// Resume timer
  void resume() {
    try {
      if (state.status != TimerStatus.paused) return;
      start();
    } catch (e) {
      globalErrorCubit.showError('Failed to resume timer: $e');
    }
  }

  /// Reset timer to initial configured duration
  void reset() {
    try {
      _timer?.cancel();
      emit(state.copyWith(
        seconds: state.initialSeconds,
        status: TimerStatus.initial,
      ));
      bleService.send(hockeyBleMapper.resetTimer());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset timer: $e');
    }
  }

  /// Reset to default state (called on exit)
  void resetToDefault() {
    try {
      _timer?.cancel();
      emit(HockeyTimerState.initial(900));
    } catch (e) {
      globalErrorCubit.showError('Failed to reset to default: $e');
    }
  }

  /// Set quarter (1–4)
  /// Allowed only when timer is NOT running
  bool setQuarter(int quarter) {
    try {
      if (quarter < 1 || quarter > 4) return false;
      if (state.status == TimerStatus.running) return false;

      emit(
        state.copyWith(
          quarter: quarter,
          seconds: state.initialSeconds,
          status: TimerStatus.initial,
        ),
      );

      bleService.send(hockeyBleMapper.setQuarter(quarter));
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
