import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/kabaddi_ble_mapper.dart';
import '../../../../../bluetooth/service/ble_service.dart';
import 'kabaddi_timer_state.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';

class KabaddiTimerCubit extends Cubit<KabaddiTimerState> {
  Timer? _timer;

  final BleService bleService;
  final KabaddiBleMapper ballBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  KabaddiTimerCubit({
    int startMinutes = 20,
    required this.bleService,
    required this.ballBleMapper,
    required this.globalErrorCubit,
  }) : super(KabaddiTimerState.initial(startMinutes: startMinutes));

  /// Start timer
  void start() {
    try {
      if (state.status == TimerStatus.running) return;

      emit(state.copyWith(status: TimerStatus.running));
      bleService.send(ballBleMapper.startTimer());
      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          try {
            if (isClosed) {
              timer.cancel();
              return;
            }
            if (state.seconds < 1) {
              timer.cancel();
              emit(
                state.copyWith(
                  seconds: 0,
                  status: TimerStatus.finished,
                ),
              );
              bleService.send(ballBleMapper.resetTimer());
            } else {
              emit(state.copyWith(seconds: state.seconds - 1));
            }
          } catch (e) {
            globalErrorCubit.showError('Timer tick error: $e');
          }
        },
      );
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
    } catch (e) {
      globalErrorCubit.showError('Failed to reset timer: $e');
    }
  }

  /// Reset to default state (called on exit)
  void resetToDefault() {
    try {
      _timer?.cancel();
      emit(KabaddiTimerState.initial());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset to default: $e');
    }
  }

  void setTime(int totalMinutes) {
    try {
      _timer?.cancel();
      final seconds = totalMinutes * 60;
      emit(
        state.copyWith(
          seconds: seconds,
          initialSeconds: seconds,
          status: TimerStatus.initial,
        ),
      );
       bleService.send(ballBleMapper.setTimerMinutes(totalMinutes));
    } catch (e) {
      globalErrorCubit.showError('Failed to set time: $e');
    }
  }

  /* =======================
   * Cleanup
   * ======================= */
  @override
  Future<void> close() {
    try {
      _timer?.cancel();
    } catch (_) {}
    return super.close();
  }
}
