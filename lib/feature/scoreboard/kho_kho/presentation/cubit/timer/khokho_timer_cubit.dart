import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/khokho_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

part 'khokho_timer_state.dart';

class KhokhoTimerCubit extends Cubit<KhokhoTimerState> {
  final BleService bleService;
  final KhoKhoBleMapper khoBleMapper;

  KhokhoTimerCubit({
    required this.bleService,
    required this.khoBleMapper,
  }) : super(const KhokhoTimerState(duration: 540)); // 9 minutes = 540 seconds

  Timer? _timer;

  void setDuration(int durationInSeconds) {
    emit(state.copyWith(duration: durationInSeconds));
    bleService.send(khoBleMapper.setMatchMinutes(durationInSeconds ~/ 60));
  }

  void startTimer() {
    if (state.status == KhokhoTimerStatus.initial || state.status == KhokhoTimerStatus.paused) {
      _start();
      bleService.send(khoBleMapper.startMatchTimer());
    }
  }

  void resumeTimer() {
    startTimer();
  }

  void _start() {
    _timer?.cancel();
    emit(state.copyWith(status: KhokhoTimerStatus.inProgress));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.duration > 0) {
        emit(state.copyWith(duration: state.duration - 1));
      } else {
        _timer?.cancel();
        emit(state.copyWith(status: KhokhoTimerStatus.paused));
        bleService.send(khoBleMapper.pauseMatchTimer());
      }
    });
  }

  void pauseTimer() {
    if (state.status == KhokhoTimerStatus.inProgress) {
      _timer?.cancel();
      emit(state.copyWith(status: KhokhoTimerStatus.paused));
      bleService.send(khoBleMapper.pauseMatchTimer());
    }
  }

  void stopTimer() {
    _timer?.cancel();
    emit(state.copyWith(status: KhokhoTimerStatus.paused));
    bleService.send(khoBleMapper.pauseMatchTimer());
  }

  void resetTimer(int duration) {
    _timer?.cancel();
    emit(KhokhoTimerState(duration: duration, status: KhokhoTimerStatus.initial));
    bleService.send(khoBleMapper.resetMatchTimer());
    bleService.send(khoBleMapper.setMatchMinutes(duration ~/ 60));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
