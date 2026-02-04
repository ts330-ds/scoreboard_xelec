import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/basketball_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'basketball_timer_state.dart';

class BasketBallTimerCubit extends Cubit<BasketBallTimerState> {
  Timer? _timer;
  static int totalSeconds = 900;

  final BasketBallBleMapper ballBleMapper;
  final BleService bleService;
  final GlobalErrorCubit globalErrorCubit;

  BasketBallTimerCubit({
    required this.bleService,
    required this.ballBleMapper,
    required this.globalErrorCubit,
  }) : super(BasketBallTimerState.initial(totalSeconds));

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

      bleService.send(ballBleMapper.setTimerMinutes(totalSeconds));
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
          if (state.seconds <= 1) {
            timer.cancel();
            emit(state.copyWith(seconds: 0, status: TimerStatus.finished));
          } else {
            emit(state.copyWith(seconds: state.seconds - 1));
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

  /// Reset everything
  void reset() {
    try {
      _timer?.cancel();
      emit(BasketBallTimerState.initial(totalSeconds));
      bleService.send(ballBleMapper.resetTimer());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset timer: $e');
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
      }
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
