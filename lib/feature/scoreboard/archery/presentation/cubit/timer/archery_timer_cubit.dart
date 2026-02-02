import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

part 'archery_timer_state.dart';

class ArcheryTimerCubit extends Cubit<ArcheryTimerState> {
  final BleService bleService;
  final ArcheryBleMapper archeryBleMapper;

  Timer? _timer;

  // Fixed times
  static const int redTime = 10;
  static const int yellowTime = 30;

  // User configurable green time
  int _greenTime = 90;

  // Callback when cycle completes
  void Function()? onCycleComplete;

  ArcheryTimerCubit({
    required this.bleService,
    required this.archeryBleMapper,
  }) : super(const ArcheryTimerState());

  void setGreenTime(int seconds) {
    _greenTime = seconds;
    //bleService.send(archeryBleMapper.setGreenTime(seconds));
  }

  int get greenTime => _greenTime;

  void startCycle() {
    _startRedPhase();
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
   // bleService.send(archeryBleMapper.setTimerPhase('RED'));
   // bleService.send(archeryBleMapper.startTimer());
    _runTimer(() => _startGreenPhase());
  }

  void _startGreenPhase() {
    emit(state.copyWith(
      phase: TimerPhase.green,
      remainingSeconds: _greenTime,
      totalSeconds: _greenTime,
    ));
   // bleService.send(archeryBleMapper.setTimerPhase('GREEN'));
    _runTimer(() => _startYellowPhase());
  }

  void _startYellowPhase() {
    emit(state.copyWith(
      phase: TimerPhase.yellow,
      remainingSeconds: yellowTime,
      totalSeconds: yellowTime,
    ));
   // bleService.send(archeryBleMapper.setTimerPhase('YELLOW'));
    _runTimer(() => _completeCycle());
  }

  void _completeCycle() {
    _cancelTimer();
    emit(state.copyWith(
      phase: TimerPhase.stopped,
      isRunning: false,
      remainingSeconds: 0,
    ));
    //bleService.send(archeryBleMapper.triggerBuzzer());
    onCycleComplete?.call();
  }

  void _runTimer(VoidCallback onComplete) {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        final newSeconds = state.remainingSeconds - 1;
        emit(state.copyWith(remainingSeconds: newSeconds));
   //     bleService.send(archeryBleMapper.setTimerSeconds(newSeconds));
      } else {
        _cancelTimer();
        onComplete();
      }
    });
  }

  void pauseTimer() {
    if (state.isRunning && !state.isPaused) {
      _cancelTimer();
      emit(state.copyWith(isPaused: true, isRunning: false));
      //bleService.send(archeryBleMapper.pauseTimer());
    }
  }

  void resumeTimer() {
    if (state.isPaused) {
      emit(state.copyWith(isPaused: false, isRunning: true));
      //bleService.send(archeryBleMapper.startTimer());

      switch (state.phase) {
        case TimerPhase.red:
          _runTimer(() => _startGreenPhase());
          break;
        case TimerPhase.green:
          _runTimer(() => _startYellowPhase());
          break;
        case TimerPhase.yellow:
          _runTimer(() => _completeCycle());
          break;
        case TimerPhase.stopped:
          break;
      }
    }
  }

  void stopTimer() {
    _cancelTimer();
    emit(const ArcheryTimerState());
   // bleService.send(archeryBleMapper.resetTimer());
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
