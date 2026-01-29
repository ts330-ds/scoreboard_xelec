import 'package:bloc/bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/kabaddi_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'kabaddi_controller_state.dart';
import 'package:flutter/material.dart';

class KabaddiControllerCubit extends Cubit<KabaddiControllerState> {
  final BleService bleService;
  final KabaddiBleMapper kabaddiBleMapper;

  KabaddiControllerCubit({
    required this.bleService,
    required this.kabaddiBleMapper,
  }) : super(KabaddiControllerState.initial());

  void setTeam1Name(String name) {
    emit(state.copyWith(team1Name: name));
    bleService.send(kabaddiBleMapper.setTeam1Name(name));
  }

  void setTeam2Name(String name) {
    emit(state.copyWith(team2Name: name));
    bleService.send(kabaddiBleMapper.setTeam2Name(name));
  }


  // Team colors
  void setTeam1Color(Color color) {
    emit(state.copyWith(team1Color: color));
   // bleService.send(basketBallBleMapper.setHomeTeamColor(toRgb565(color).toRadixString(16).padLeft(4, '0')
      //  .toUpperCase()));
  }

  void setTeam2Color(Color color) {
    emit(state.copyWith(team2Color: color));
    ///bleService.send(basketBallBleMapper.setAwayTeamColor(toRgb565(color).toRadixString(16).padLeft(4, '0')
      //  .toUpperCase()));
  }

  void incrementTeam1Score() {
    final newScore = state.team1Score + 1;
    emit(state.copyWith(team1Score: newScore));
    bleService.send(kabaddiBleMapper.setTeam1Score(newScore));
  }

  void decrementTeam1Score() {
    if (state.team1Score > 0) {
      final newScore = state.team1Score - 1;
      emit(state.copyWith(team1Score: newScore));
      bleService.send(kabaddiBleMapper.setTeam1Score(newScore));
    }
  }

  void incrementTeam2Score() {
    final newScore = state.team2Score + 1;
    emit(state.copyWith(team2Score: newScore));
    bleService.send(kabaddiBleMapper.setTeam2Score(newScore));
  }

  void decrementTeam2Score() {
    if (state.team2Score > 0) {
      final newScore = state.team2Score - 1;
      emit(state.copyWith(team2Score: newScore));
      bleService.send(kabaddiBleMapper.setTeam2Score(newScore));
    }
  }

  void incrementTeam1Touch() {
    final newValue = state.team1Touch + 1;
    emit(state.copyWith(team1Touch: newValue));
    bleService.send(kabaddiBleMapper.setTeam1Touch(newValue));
  }

  void decrementTeam1Touch() {
    if (state.team1Touch > 0) {
      final newValue = state.team1Touch - 1;
      emit(state.copyWith(team1Touch: newValue));
      bleService.send(kabaddiBleMapper.setTeam1Touch(newValue));
    }
  }

  void incrementTeam2Touch() {
    final newValue = state.team2Touch + 1;
    emit(state.copyWith(team2Touch: newValue));
    bleService.send(kabaddiBleMapper.setTeam2Touch(newValue));
  }

  void decrementTeam2Touch() {
    if (state.team2Touch > 0) {
      final newValue = state.team2Touch - 1;
      emit(state.copyWith(team2Touch: newValue));
      bleService.send(kabaddiBleMapper.setTeam2Touch(newValue));
    }
  }

  void incrementTeam1Bonus() {
    final newValue = state.team1Bonus + 1;
    emit(state.copyWith(team1Bonus: newValue));
    bleService.send(kabaddiBleMapper.setTeam1Bonus(newValue));
  }

  void decrementTeam1Bonus() {
    if (state.team1Bonus > 0) {
      final newValue = state.team1Bonus - 1;
      emit(state.copyWith(team1Bonus: newValue));
      bleService.send(kabaddiBleMapper.setTeam1Bonus(newValue));
    }
  }

  void incrementTeam2Bonus() {
    final newValue = state.team2Bonus + 1;
    emit(state.copyWith(team2Bonus: newValue));
    bleService.send(kabaddiBleMapper.setTeam2Bonus(newValue));
  }

  void decrementTeam2Bonus() {
    if (state.team2Bonus > 0) {
      final newValue = state.team2Bonus - 1;
      emit(state.copyWith(team2Bonus: newValue));
      bleService.send(kabaddiBleMapper.setTeam2Bonus(newValue));
    }
  }

  void incrementTeam1AllOut() {
    final newValue = state.team1AllOut + 1;
    emit(state.copyWith(team1AllOut: newValue));
    bleService.send(kabaddiBleMapper.setTeam1AllOut(newValue));
  }

  void decrementTeam1AllOut() {
    if (state.team1AllOut > 0) {
      final newValue = state.team1AllOut - 1;
      emit(state.copyWith(team1AllOut: newValue));
      bleService.send(kabaddiBleMapper.setTeam1AllOut(newValue));
    }
  }

  void incrementTeam2AllOut() {
    final newValue = state.team2AllOut + 1;
    emit(state.copyWith(team2AllOut: newValue));
    bleService.send(kabaddiBleMapper.setTeam2AllOut(newValue));
  }

  void decrementTeam2AllOut() {
    if (state.team2AllOut > 0) {
      final newValue = state.team2AllOut - 1;
      emit(state.copyWith(team2AllOut: newValue));
      bleService.send(kabaddiBleMapper.setTeam2AllOut(newValue));
    }
  }

  void incrementRaidNumber() {
    final newValue = state.raidNumber + 1;
    emit(state.copyWith(raidNumber: newValue));
    bleService.send(kabaddiBleMapper.setRaidNumber(newValue));
  }

  void decrementRaidNumber() {
    if (state.raidNumber > 1) {
      final newValue = state.raidNumber - 1;
      emit(state.copyWith(raidNumber: newValue));
      bleService.send(kabaddiBleMapper.setRaidNumber(newValue));
    }
  }

  void setQuarter(int quarter) {
    emit(state.copyWith(currentQuarter: quarter));
    bleService.send(kabaddiBleMapper.setQuarter(quarter));
  }

  void toggleRaider() {
    final newValue = !state.isRaiderOnTeam1;
    emit(state.copyWith(isRaiderOnTeam1: newValue));
    if (newValue) {
      bleService.send(kabaddiBleMapper.showRaiderOnTeam1());
    } else {
      bleService.send(kabaddiBleMapper.showRaiderOnTeam2());
    }
  }

  void resetScreen() {
    bleService.send(kabaddiBleMapper.resetScreen());
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

}
