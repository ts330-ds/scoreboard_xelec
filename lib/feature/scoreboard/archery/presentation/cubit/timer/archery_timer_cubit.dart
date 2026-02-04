import 'dart:async';


import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/error/screen/global_error_screen.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

part 'archery_timer_state.dart';

class ArcheryTimerCubit extends Cubit<ArcheryTimerState> {
  final BleService bleService;
  final ArcheryBleMapper archeryBleMapper;
  final GlobalErrorCubit globalErrorToastListener;
  Timer? _timer;

  // Fixed times
  static const int redTime = 10;
  static const int yellowThreshold = 30; // Yellow starts when timer <= 30

  // User configurable total match time (green + yellow combined)
  int _matchTime = 120; // Default 2 minutes

  // Callback when cycle completes
  void Function()? onCycleComplete;

  ArcheryTimerCubit({
    required this.bleService,
    required this.archeryBleMapper,
    required this.globalErrorToastListener
  }) : super(const ArcheryTimerState());

  /// Set total match time (green + yellow combined)
  /// Yellow phase automatically starts at last 30 seconds
  void setMatchTime(int seconds) {
    if(seconds < yellowThreshold){
      globalErrorToastListener.showError('Match time must be greater than $yellowThreshold seconds');
      return;
    }
    _matchTime = seconds;
  }

  int get matchTime => _matchTime;
  int get greenTime => _matchTime - yellowThreshold;
  int get yellowTime => yellowThreshold;

  void startCycle() {
    _startRedPhase();
    // Send total match time to firmware (it handles phase transitions internally)
    bleService.send(archeryBleMapper.startMatch(matchTime));
  }

  void _startRedPhase() {
    _cancelTimer();
    emit(state.copyWith(
      phase: TimerPhase.red,
      remainingSeconds: redTime,
      totalSeconds: redTime,
      isRunning: true,
      isPaused: false,
    ));
    _runTimer();
  }

  void _startMatchPhase() {
    // Start with green phase, will auto-switch to yellow at 30 seconds
    emit(state.copyWith(
      phase: TimerPhase.green,
      remainingSeconds: _matchTime,
      totalSeconds: _matchTime,
    ));
    _runTimer();
  }

  void _completeCycle() {
    _cancelTimer();
    emit(state.copyWith(
      phase: TimerPhase.stopped,
      isRunning: false,
      remainingSeconds: 0,
    ));
    onCycleComplete?.call();
  }

  void _runTimer() {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        final newSeconds = state.remainingSeconds - 1;

        // Determine phase based on current state
        if (state.phase == TimerPhase.red) {
          // Red phase countdown
          emit(state.copyWith(remainingSeconds: newSeconds));
        } else {
          // Match phase (green/yellow)
          // Auto-switch to yellow when <= 30 seconds
          final newPhase = newSeconds <= yellowThreshold
              ? TimerPhase.yellow
              : TimerPhase.green;

          emit(state.copyWith(
            remainingSeconds: newSeconds,
            phase: newPhase,
          ));
        }
      } else {
        // Timer reached 0
        _cancelTimer();

        if (state.phase == TimerPhase.red) {
          // Red phase complete, start match phase
          _startMatchPhase();
        } else {
          // Match complete (yellow ended)
          _completeCycle();
        }
      }
    });
  }

  void pauseTimer() {
    if (state.isRunning && !state.isPaused) {
      _cancelTimer();
      emit(state.copyWith(isPaused: true, isRunning: false));
      bleService.send(archeryBleMapper.pauseTimer());
    }
  }

  void resumeTimer() {
    if (state.isPaused) {
      emit(state.copyWith(isPaused: false, isRunning: true));
      bleService.send(archeryBleMapper.resumeTimer());
      _runTimer();
    }
  }

  void stopTimer() {
    _cancelTimer();
    emit(const ArcheryTimerState());
    bleService.send(archeryBleMapper.resetGame());
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}