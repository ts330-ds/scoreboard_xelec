import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/hockey_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'hockey_controller_state.dart';

class HockeyControllerCubit extends Cubit<HockeyControllerState> {
  final BleService bleService;
  final HockeyBleMapper bleMapper;

  HockeyControllerCubit({
    required this.bleService,
    required this.bleMapper,
  }) : super(HockeyControllerState.initial());

  // ---------------- TEAM NAMES ----------------
  void setTeam1Name(String name) {
    emit(state.copyWith(team1Name: name));
    bleService.send(bleMapper.setTeam1Name(name));
  }

  void setTeam2Name(String name) {
    emit(state.copyWith(team2Name: name));
    bleService.send(bleMapper.setTeam2Name(name));
  }

  // ---------------- SCORES ----------------
  void incTeam1Score() {
    final newValue = state.team1Score + 1;
    emit(state.copyWith(team1Score: newValue));
    bleService.send(bleMapper.setTeam1Score(newValue));
  }

  void decTeam1Score() {
    if (state.team1Score > 0) {
      final newValue = state.team1Score - 1;
      emit(state.copyWith(team1Score: newValue));
      bleService.send(bleMapper.setTeam1Score(newValue));
    }
  }

  void incTeam2Score() {
    final newValue = state.team2Score + 1;
    emit(state.copyWith(team2Score: newValue));
    bleService.send(bleMapper.setTeam2Score(newValue));
  }

  void decTeam2Score() {
    if (state.team2Score > 0) {
      final newValue = state.team2Score - 1;
      emit(state.copyWith(team2Score: newValue));
      bleService.send(bleMapper.setTeam2Score(newValue));
    }
  }

  // ---------------- PENALTY CORNERS ----------------
  void incTeam1PenaltyCorner() {
    final newValue = state.team1PenaltyCorner + 1;
    emit(state.copyWith(team1PenaltyCorner: newValue));
    bleService.send(bleMapper.setTeam1PenaltyCorner(newValue));
  }

  void decTeam1PenaltyCorner() {
    if (state.team1PenaltyCorner > 0) {
      final newValue = state.team1PenaltyCorner - 1;
      emit(state.copyWith(team1PenaltyCorner: newValue));
      bleService.send(bleMapper.setTeam1PenaltyCorner(newValue));
    }
  }

  void incTeam2PenaltyCorner() {
    final newValue = state.team2PenaltyCorner + 1;
    emit(state.copyWith(team2PenaltyCorner: newValue));
    bleService.send(bleMapper.setTeam2PenaltyCorner(newValue));
  }

  void decTeam2PenaltyCorner() {
    if (state.team2PenaltyCorner > 0) {
      final newValue = state.team2PenaltyCorner - 1;
      emit(state.copyWith(team2PenaltyCorner: newValue));
      bleService.send(bleMapper.setTeam2PenaltyCorner(newValue));
    }
  }

  // ---------------- Brightness ----------------
  void setBrightness(int value) {
    final clampedValue = value.clamp(0, 255);
    emit(state.copyWith(brightness: clampedValue));
   // bleService.send(bleMapper.setBrightness(clampedValue));
  }

  void setTempBrightness(int value) {
    emit(state.copyWith(tempbrightness: value.clamp(0, 255)));
  }

  // ---------------- Buzzer ----------------
  void toggleBuzzer() {
    emit(state.copyWith(buzzerOn: !state.buzzerOn));
    bleService.send(bleMapper.setBuzzer(!state.buzzerOn));
  }

  // ---------------- SHOOTOUTS ----------------
  void incTeam1Shootout() {
    final newValue = state.team1Shootout + 1;
    emit(state.copyWith(team1Shootout: newValue));
    bleService.send(bleMapper.setTeam1ShootOut(newValue));
  }

  void decTeam1Shootout() {
    if (state.team1Shootout > 0) {
      final newValue = state.team1Shootout - 1;
      emit(state.copyWith(team1Shootout: newValue));
      bleService.send(bleMapper.setTeam1ShootOut(newValue));
    }
  }

  void incTeam2Shootout() {
    final newValue = state.team2Shootout + 1;
    emit(state.copyWith(team2Shootout: newValue));
    bleService.send(bleMapper.setTeam2ShootOut(newValue));
  }

  void decTeam2Shootout() {
    if (state.team2Shootout > 0) {
      final newValue = state.team2Shootout - 1;
      emit(state.copyWith(team2Shootout: newValue));
      bleService.send(bleMapper.setTeam2ShootOut(newValue));
    }
  }

  void exit() {
    emit(HockeyControllerState.initial());
    bleService.send(bleMapper.resetScreen());
  }

  // ------- Color ----------
  void setTeam1Color(Color color) {
    emit(state.copyWith(team1Color: color));
    // Implementation for sending color if needed by mapper
  }

  void setTeam2Color(Color color) {
    emit(state.copyWith(team2Color: color));
  }

  // ---------------- RESET ----------------
  void reset() {
    emit(HockeyControllerState.initial());
    bleService.send(bleMapper.resetScreen());
  }
}
