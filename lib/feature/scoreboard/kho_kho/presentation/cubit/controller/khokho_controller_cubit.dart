import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../../../../../bluetooth/mapper/khokho_ble_mapper.dart';
import '../../../../../bluetooth/service/ble_service.dart';

part 'khokho_controller_state.dart';

class KhokhoControllerCubit extends Cubit<KhokhoControllerState> {
  final BleService bleService;
  final KhoKhoBleMapper khoBleMapper;

  KhokhoControllerCubit({
    required this.bleService,
    required this.khoBleMapper,
  }) : super(const KhokhoControllerState());

  void updateTeam1Name(String name) {
    emit(state.copyWith(team1Name: name));
    bleService.send(khoBleMapper.setTeam1Name(name));
  }

  void updateTeam2Name(String name) {
    emit(state.copyWith(team2Name: name));
    bleService.send(khoBleMapper.setTeam2Name(name));
  }

  void incrementTeam1Score() {
    final newScore = state.team1Score + 1;
    emit(state.copyWith(team1Score: newScore));
    bleService.send(khoBleMapper.setTeam1Score(newScore));
  }

  void decrementTeam1Score() {
    if (state.team1Score > 0) {
      final newScore = state.team1Score - 1;
      emit(state.copyWith(team1Score: newScore));
      bleService.send(khoBleMapper.setTeam1Score(newScore));
    }
  }

  void incrementTeam2Score() {
    final newScore = state.team2Score + 1;
    emit(state.copyWith(team2Score: newScore));
    bleService.send(khoBleMapper.setTeam2Score(newScore));
  }

  void decrementTeam2Score() {
    if (state.team2Score > 0) {
      final newScore = state.team2Score - 1;
      emit(state.copyWith(team2Score: newScore));
      bleService.send(khoBleMapper.setTeam2Score(newScore));
    }
  }

  // ------ Color ------

  void updateTeam1Color(Color color) {
    emit(state.copyWith(team1Color: color));
    bleService.send(khoBleMapper.setTeam1Color(toRgb565(color)));
  }

  void updateTeam2Color(Color color) {
    emit(state.copyWith(team2Color: color));
    bleService.send(khoBleMapper.setTeam2Color(toRgb565(color)));
  }

  void incrementInn() {
    if (state.inn < 2) {
      final newInn = state.inn + 1;
      emit(state.copyWith(inn: newInn));
      bleService.send(khoBleMapper.setInning(newInn));
    }
  }

  void decrementInn() {
    if (state.inn > 1) {
      final newInn = state.inn - 1;
      emit(state.copyWith(inn: newInn));
      bleService.send(khoBleMapper.setInning(newInn));
    }
  }

  void incrementTurn() {
    if (state.turn < 4) {
      final newTurn = state.turn + 1;
      emit(state.copyWith(turn: newTurn));
      bleService.send(khoBleMapper.setTurn(newTurn));
    }
  }

  void decrementTurn() {
    if (state.turn > 1) {
      final newTurn = state.turn - 1;
      emit(state.copyWith(turn: newTurn));
      bleService.send(khoBleMapper.setTurn(newTurn));
    }
  }

  void updateMatchTime(String time) {
    emit(state.copyWith(matchTime: time));
    // Usually timer sync is handled by a timer cubit, but if it's just setting duration:
    final parts = time.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]);
      if (minutes != null) {
        bleService.send(khoBleMapper.setMatchMinutes(minutes));
      }
    }
  }

  void toggleChasingTeam() {
    final newState = !state.isTeam1Chasing;
    emit(state.copyWith(isTeam1Chasing: newState));
    bleService.send(khoBleMapper.setChaseTeam(newState ? 1 : 2));
  }

  void resetScreen() {
    bleService.send(khoBleMapper.resetScreen());
  }

  // Brightness (0 - 255)
  void setBrightness(int value) {
    emit(state.copyWith(brightness: value.clamp(0, 220)));
   // bleService.send(basketBallBleMapper.setBrightness(value));
  }

  void setTempBrightness(int value) {
    emit(state.copyWith(tempBrightness: value.clamp(0, 220)));
  }

  // Buzzer toggle
  void toggleBuzzer() {
    emit(state.copyWith(buzzerOn: !state.buzzerOn));
    //bleService.send(state.buzzerOn ? "BBBUZZERON" : "BBBUZZEROFF");
  }
}
