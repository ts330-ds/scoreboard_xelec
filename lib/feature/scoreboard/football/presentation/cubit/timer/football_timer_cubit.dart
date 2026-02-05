import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/football_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';

part 'football_timer_state.dart';

class FootballTimerCubit extends Cubit<FootballTimerState> {
  final BleService bleService;
  final FootballBleMapper footballBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  FootballTimerCubit({
    required this.bleService,
    required this.footballBleMapper,
    required this.globalErrorCubit,
  }) : super(const FootballTimerState(duration: 0));

  Timer? _timer;

  void setDuration(int durationInSeconds) {
    try {
      emit(state.copyWith(duration: durationInSeconds));
      // Hardware uses minutes
      bleService.send(
        footballBleMapper.setTimerMinutes(durationInSeconds ~/ 60),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to set duration: $e');
    }
  }

  void startTimer() {
    try {
      if (state.status != FootballTimerStatus.inProgress) {
        _timer?.cancel();

        emit(state.copyWith(status: FootballTimerStatus.inProgress));
        bleService.send(footballBleMapper.startTimer());

        _timer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            try {
              if (isClosed) {
                timer.cancel();
                return;
              }
              emit(state.copyWith(duration: state.duration + 1));
            } catch (e) {
              globalErrorCubit.showError('Timer tick error: $e');
            }
          },
        );
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to start timer: $e');
    }
  }

  void pauseTimer() {
    try {
      _timer?.cancel();
      emit(state.copyWith(status: FootballTimerStatus.paused));
      bleService.send(footballBleMapper.pauseTimer());
    } catch (e) {
      globalErrorCubit.showError('Failed to pause timer: $e');
    }
  }

  void resumeTimer() {
    try {
      startTimer();
    } catch (e) {
      globalErrorCubit.showError('Failed to resume timer: $e');
    }
  }

  void resetTimer() {
    try {
      _timer?.cancel();
      emit(const FootballTimerState(
        duration: 0,
        status: FootballTimerStatus.initial,
      ));
      bleService.send(footballBleMapper.resetTimer());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset timer: $e');
    }
  }

  /// Reset to default state (called on exit)
  void resetToDefault() {
    try {
      _timer?.cancel();
      emit(const FootballTimerState(
        duration: 0,
        status: FootballTimerStatus.initial,
      ));
    } catch (e) {
      globalErrorCubit.showError('Failed to reset to default: $e');
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
