import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/football_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

part 'football_timer_state.dart';

class FootballTimerCubit extends Cubit<FootballTimerState> {
  final BleService bleService;
  final FootballBleMapper footballBleMapper;

  FootballTimerCubit({
    required this.bleService,
    required this.footballBleMapper,
  }) : super(const FootballTimerState(duration: 0));

  Timer? _timer;

  void setDuration(int durationInSeconds) {
    emit(state.copyWith(duration: durationInSeconds));
    // Usually football hardware takes minutes for FO TN, 
    // but if it supports seconds or specific format, we adjust.
    // Assuming minutes for now as per mapper.
    bleService.send(footballBleMapper.setTimerMinutes(durationInSeconds ~/ 60));
  }

  void startTimer() {
    if (state.status != FootballTimerStatus.inProgress) {
      _timer?.cancel();
      emit(state.copyWith(status: FootballTimerStatus.inProgress));
      bleService.send(footballBleMapper.startTimer());
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        emit(state.copyWith(duration: state.duration + 1));
      });
    }
  }

  void pauseTimer() {
    _timer?.cancel();
    emit(state.copyWith(status: FootballTimerStatus.paused));
    bleService.send(footballBleMapper.pauseTimer());
  }

  void resumeTimer() {
    startTimer();
  }

  void resetTimer() {
    _timer?.cancel();
    emit(const FootballTimerState(duration: 0, status: FootballTimerStatus.initial));
    bleService.send(footballBleMapper.resetTimer());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
