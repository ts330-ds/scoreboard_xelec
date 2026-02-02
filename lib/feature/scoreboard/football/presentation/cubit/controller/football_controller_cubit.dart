import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/football_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import 'football_controller_state.dart';

class FootballControllerCubit extends Cubit<FootballControllerState> {
  final BleService bleService;
  final FootballBleMapper footballBleMapper;

  FootballControllerCubit({
    required this.bleService,
    required this.footballBleMapper,
  }) : super(const FootballControllerState());

  void updateTeam1Name(String name) {
    emit(state.copyWith(team1Name: name));
    bleService.send(footballBleMapper.setTeam1Name(name));
  }

  void updateTeam2Name(String name) {
    emit(state.copyWith(team2Name: name));
    bleService.send(footballBleMapper.setTeam2Name(name));
  }

  void updateTeam1Color(Color color) {
    emit(state.copyWith(team1Color: color));
    bleService.send(footballBleMapper.setTeam1Color(toRgb565(color)));
  }

  void updateTeam2Color(Color color) {
    emit(state.copyWith(team2Color: color));
    bleService.send(footballBleMapper.setTeam2Color(toRgb565(color)));
  }

  void incrementTeam1Score() {
    final newScore = state.team1Score + 1;
    emit(state.copyWith(team1Score: newScore));
    bleService.send(footballBleMapper.setTeam1Score(newScore));
  }

  void decrementTeam1Score() {
    if (state.team1Score > 0) {
      final newScore = state.team1Score - 1;
      emit(state.copyWith(team1Score: newScore));
      bleService.send(footballBleMapper.setTeam1Score(newScore));
    }
  }

  void incrementTeam2Score() {
    final newScore = state.team2Score + 1;
    emit(state.copyWith(team2Score: newScore));
    bleService.send(footballBleMapper.setTeam2Score(newScore));
  }

  void decrementTeam2Score() {
    if (state.team2Score > 0) {
      final newScore = state.team2Score - 1;
      emit(state.copyWith(team2Score: newScore));
      bleService.send(footballBleMapper.setTeam2Score(newScore));
    }
  }

  void incrementExtraTime() {
    final newExtra = state.extraTime + 1;
    emit(state.copyWith(extraTime: newExtra));
    bleService.send(footballBleMapper.setExtraTime("$newExtra'"));
  }

  void decrementExtraTime() {
    if (state.extraTime > 0) {
      final newExtra = state.extraTime - 1;
      emit(state.copyWith(extraTime: newExtra));
      bleService.send(footballBleMapper.setExtraTime(newExtra == 0 ? " " : "$newExtra'"));
    }
  }

  void setHalf(int half) {
    emit(state.copyWith(currentHalf: half));
    if (half == 1) {
      bleService.send(footballBleMapper.setFirstHalf());
    } else {
      bleService.send(footballBleMapper.setSecondHalf());
    }
  }

  void resetScreen() {
    bleService.send(footballBleMapper.resetScreen());
  }

  void triggerBuzzer() {
   // bleService.send(footballBleMapper.triggerBuzzer());
  }

  // Brightness (0 - 255)
  void setBrightness(int value) {
    emit(state.copyWith(brightness: value.clamp(0, 255)));
  }

  void setTempBrightness(int value) {
    emit(state.copyWith(tempBrightness: value.clamp(0, 255)));
  }

  // Buzzer toggle
  void toggleBuzzer() {
    emit(state.copyWith(buzzerOn: !state.buzzerOn));
  }
  void exit() {
    emit(const FootballControllerState());
  }
}
