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
      emit(KabaddiTimerState.initial());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset timer: $e');
    }
  }

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
      // bleService.send(ballBleMapper.setMinutes(totalSeconds));
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
