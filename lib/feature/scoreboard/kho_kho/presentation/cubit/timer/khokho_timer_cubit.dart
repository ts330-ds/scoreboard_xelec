import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/khokho_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';

part 'khokho_timer_state.dart';

class KhokhoTimerCubit extends Cubit<KhokhoTimerState> {
  final BleService bleService;
  final KhoKhoBleMapper khoBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  KhokhoTimerCubit({
    required this.bleService,
    required this.khoBleMapper,
    required this.globalErrorCubit,
  }) : super(const KhokhoTimerState(duration: 540)); // 9 minutes

  Timer? _timer;

  void setDuration(int durationInSeconds) {
    try {
      emit(state.copyWith(duration: durationInSeconds));
      bleService.send(
        khoBleMapper.setMatchMinutes(durationInSeconds ~/ 60),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to set duration: $e');
    }
  }

  void startTimer() {
    try {
      if (state.status == KhokhoTimerStatus.initial ||
          state.status == KhokhoTimerStatus.paused) {
        _start();
        bleService.send(khoBleMapper.startMatchTimer());
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to start timer: $e');
    }
  }

  void resumeTimer() {
    try {
      startTimer();
    } catch (e) {
      globalErrorCubit.showError('Failed to resume timer: $e');
    }
  }

  void _start() {
    try {
      _timer?.cancel();
      emit(state.copyWith(status: KhokhoTimerStatus.inProgress));

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        try {
          if (state.duration > 0) {
            emit(state.copyWith(duration: state.duration - 1));
          } else {
            _timer?.cancel();
            emit(state.copyWith(status: KhokhoTimerStatus.paused));
            bleService.send(khoBleMapper.pauseMatchTimer());
          }
        } catch (e) {
          globalErrorCubit.showError('Timer tick error: $e');
        }
      });
    } catch (e) {
      globalErrorCubit.showError('Failed to init timer: $e');
    }
  }

  void pauseTimer() {
    try {
      if (state.status == KhokhoTimerStatus.inProgress) {
        _timer?.cancel();
        emit(state.copyWith(status: KhokhoTimerStatus.paused));
        bleService.send(khoBleMapper.pauseMatchTimer());
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to pause timer: $e');
    }
  }

  void stopTimer() {
    try {
      _timer?.cancel();
      emit(state.copyWith(status: KhokhoTimerStatus.paused));
      bleService.send(khoBleMapper.pauseMatchTimer());
    } catch (e) {
      globalErrorCubit.showError('Failed to stop timer: $e');
    }
  }

  void resetTimer(int duration) {
    try {
      _timer?.cancel();
      emit(
        KhokhoTimerState(
          duration: duration,
          status: KhokhoTimerStatus.initial,
        ),
      );
      bleService.send(khoBleMapper.resetMatchTimer());
      bleService.send(khoBleMapper.setMatchMinutes(duration ~/ 60));
    } catch (e) {
      globalErrorCubit.showError('Failed to reset timer: $e');
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
