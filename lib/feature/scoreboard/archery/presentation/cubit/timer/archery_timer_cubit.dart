import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/timer/archery_timer_state.dart';

class ArcheryTimerCubit extends Cubit<ArcheryTimerState> {
  final BleService bleService;
  final ArcheryBleMapper archeryBleMapper;
  final GlobalErrorCubit globalErrorToastListener;

  Timer? _timer;

  static const int redTime = 10;
  static const int yellowThreshold = 30;

  int _matchTime = 120;

  void Function()? onCycleComplete;

  ArcheryTimerCubit({
    required this.bleService,
    required this.archeryBleMapper,
    required this.globalErrorToastListener,
  }) : super(const ArcheryTimerState());

  void setMatchTime(int seconds) {
    try {
      if (seconds < yellowThreshold) {
        globalErrorToastListener.showError(
          'Match time must be greater than $yellowThreshold seconds',
        );
        return;
      }
      _matchTime = seconds;
      bleService.send(archeryBleMapper.startMatch(matchTime));
    } catch (e) {
      globalErrorToastListener.showError('Failed to set match time: $e');
    }
  }

  int get matchTime => _matchTime;
  int get greenTime => _matchTime - yellowThreshold;
  int get yellowTime => yellowThreshold;

  void startCycle() {
    try {
      _startRedPhase();
      bleService.send(archeryBleMapper.startMatch(matchTime));
    } catch (e) {
      globalErrorToastListener.showError('Failed to start cycle: $e');
    }
  }

  void _startRedPhase() {
    try {
      _cancelTimer();
      emit(state.copyWith(
        phase: TimerPhase.red,
        remainingSeconds: redTime,
        totalSeconds: redTime,
        isRunning: true,
        isPaused: false,
      ));
      _runTimer();
    } catch (e) {
      globalErrorToastListener.showError('Failed to start red phase: $e');
    }
  }

  void _startMatchPhase() {
    try {
      emit(state.copyWith(
        phase: TimerPhase.green,
        remainingSeconds: _matchTime,
        totalSeconds: _matchTime,
      ));
      _runTimer();
    } catch (e) {
      globalErrorToastListener.showError('Failed to start match phase: $e');
    }
  }

  void _completeCycle() {
    try {
      _cancelTimer();
      emit(state.copyWith(
        phase: TimerPhase.stopped,
        isRunning: false,
        remainingSeconds: 0,
      ));
      onCycleComplete?.call();
    } catch (e) {
      globalErrorToastListener.showError('Failed to complete cycle: $e');
    }
  }

  void _runTimer() {
    try {
      _cancelTimer();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        try {
          if (isClosed) {
            timer.cancel();
            return;
          }
          if (state.remainingSeconds > 1) {
            final newSeconds = state.remainingSeconds - 1;

            if (state.phase == TimerPhase.red) {
              emit(state.copyWith(remainingSeconds: newSeconds));
            } else {
              final newPhase = newSeconds <= yellowThreshold
                  ? TimerPhase.yellow
                  : TimerPhase.green;

              emit(state.copyWith(
                remainingSeconds: newSeconds,
                phase: newPhase,
              ));
            }
          } else {
            _cancelTimer();

            if (state.phase == TimerPhase.red) {
              _startMatchPhase();
            } else {
              _completeCycle();
            }
          }
        } catch (e) {
          globalErrorToastListener.showError('Timer tick error: $e');
        }
      });
    } catch (e) {
      globalErrorToastListener.showError('Failed to run timer: $e');
    }
  }

  void pauseTimer() {
    try {
      if (state.isRunning && !state.isPaused) {
        _cancelTimer();
        emit(state.copyWith(isPaused: true, isRunning: false));
        bleService.send(archeryBleMapper.pauseMatch());
      }
    } catch (e) {
      globalErrorToastListener.showError('Failed to pause timer: $e');
    }
  }

  void resumeTimer() {
    try {
      if (state.isPaused) {
        emit(state.copyWith(isPaused: false, isRunning: true));
        bleService.send(archeryBleMapper.resetMatch());
        _runTimer();
      }
    } catch (e) {
      globalErrorToastListener.showError('Failed to resume timer: $e');
    }
  }

  void stopTimer() {
    try {
      _cancelTimer();
      emit(const ArcheryTimerState());
      bleService.send(archeryBleMapper.resetMatch());
    } catch (e) {
      globalErrorToastListener.showError('Failed to stop timer: $e');
    }
  }

  /// Reset to default state (called on exit)
  void resetToDefault() {
    try {
      _cancelTimer();
      emit(const ArcheryTimerState());
    } catch (e) {
      globalErrorToastListener.showError('Failed to reset to default: $e');
    }
  }

  void _cancelTimer() {
    try {
      _timer?.cancel();
      _timer = null;
    } catch (_) {}
  }

  @override
  Future<void> close() {
    try {
      _cancelTimer();
    } catch (_) {}
    return super.close();
  }
}
