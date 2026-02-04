import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/handball_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

import 'hand_ball_controller_state.dart';

class HandBallControlCubit extends Cubit<HandballControlState> {
  final BleService bleService;
  final HandBallBleMapper ballBleMapper;

  HandBallControlCubit({required this.bleService, required this.ballBleMapper})
      : super(HandballControlState.initial());

  /* ===== EXIT / RESET ===== */
  void exit() {
    emit(HandballControlState.initial());
    bleService.send(ballBleMapper.resetScreen());
  }

  /* ===== TEAM NAMES ===== */
  void setTeam1Name(String name) {
    emit(state.copyWith(team1Name: name));
    bleService.send(ballBleMapper.setTeam1Name(name));
  }

  void setTeam2Name(String name) {
    emit(state.copyWith(team2Name: name));
    bleService.send(ballBleMapper.setTeam2Name(name));
  }

  /* ===== SCORE ===== */
  void incTeam1Score() {
    final newScore = state.team1Score + 1;
    emit(state.copyWith(team1Score: newScore));
    bleService.send(ballBleMapper.setTeam1Score(newScore));
  }

  void decTeam1Score() {
    if (state.team1Score > 0) {
      final newScore = state.team1Score - 1;
      emit(state.copyWith(team1Score: newScore));
      bleService.send(ballBleMapper.setTeam1Score(newScore));
    }
  }

  void incTeam2Score() {
    final newScore = state.team2Score + 1;
    emit(state.copyWith(team2Score: newScore));
    bleService.send(ballBleMapper.setTeam2Score(newScore));
  }

  void decTeam2Score() {
    if (state.team2Score > 0) {
      final newScore = state.team2Score - 1;
      emit(state.copyWith(team2Score: newScore));
      bleService.send(ballBleMapper.setTeam2Score(newScore));
    }
  }

  /* ===== TIMEOUT (1-3) ===== */
  void incrementTeam1Timeout() {
    if (state.team1Timeout >= 3) return;
    final newTimeout = state.team1Timeout + 1;
    emit(state.copyWith(team1Timeout: newTimeout));
    bleService.send(ballBleMapper.setTeam1Timeout(newTimeout));
  }

  void decrementTeam1Timeout() {
    if (state.team1Timeout <= 0) return;
    final newTimeout = state.team1Timeout - 1;
    emit(state.copyWith(team1Timeout: newTimeout));
    bleService.send(ballBleMapper.setTeam1Timeout(newTimeout));
  }

  void incrementTeam2Timeout() {
    if (state.team2Timeout >= 3) return;
    final newTimeout = state.team2Timeout + 1;
    emit(state.copyWith(team2Timeout: newTimeout));
    bleService.send(ballBleMapper.setTeam2Timeout(newTimeout));
  }

  void decrementTeam2Timeout() {
    if (state.team2Timeout <= 0) return;
    final newTimeout = state.team2Timeout - 1;
    emit(state.copyWith(team2Timeout: newTimeout));
    bleService.send(ballBleMapper.setTeam2Timeout(newTimeout));
  }

  /* ===== 7 METER ===== */
  void incTeam1_7m() {
    final newValue = state.team1_7m + 1;
    emit(state.copyWith(team1_7m: newValue));
    bleService.send(ballBleMapper.setTeam1SevenMeter(newValue));
  }

  void decTeam1_7m() {
    if (state.team1_7m <= 0) return;
    final newValue = state.team1_7m - 1;
    emit(state.copyWith(team1_7m: newValue));
    bleService.send(ballBleMapper.setTeam1SevenMeter(newValue));
  }

  void incTeam2_7m() {
    final newValue = state.team2_7m + 1;
    emit(state.copyWith(team2_7m: newValue));
    bleService.send(ballBleMapper.setTeam2SevenMeter(newValue));
  }

  void decTeam2_7m() {
    if (state.team2_7m <= 0) return;
    final newValue = state.team2_7m - 1;
    emit(state.copyWith(team2_7m: newValue));
    bleService.send(ballBleMapper.setTeam2SevenMeter(newValue));
  }

  /* ===== SUSPENSION (1 = Red, 2 = Green) ===== */
  // Note: Firmware expects 1 or 2 for suspension color
  /* ===== SUSPENSION ===== */
  // Increment/Decrement suspension count by 2 (old behavior)
  void incTeam1Suspension() {
    final newValue = state.team1Suspension + 2;
    emit(state.copyWith(team1Suspension: newValue));
    // Firmware: 1 = Red (has suspension), 2 = Green (no suspension)
    bleService.send(ballBleMapper.setTeam1Suspension(1));
  }

  void decTeam1Suspension() {
    if (state.team1Suspension <= 0) return;
    final newValue = state.team1Suspension - 2;
    emit(state.copyWith(team1Suspension: newValue));
    bleService.send(ballBleMapper.setTeam1Suspension(newValue > 0 ? 1 : 2));
  }

  void incTeam2Suspension() {
    final newValue = state.team2Suspension + 2;
    emit(state.copyWith(team2Suspension: newValue));
    bleService.send(ballBleMapper.setTeam2Suspension(1));
  }

  void decTeam2Suspension() {
    if (state.team2Suspension <= 0) return;
    final newValue = state.team2Suspension - 2;
    emit(state.copyWith(team2Suspension: newValue));
    bleService.send(ballBleMapper.setTeam2Suspension(newValue > 0 ? 1 : 2));
  }


  /* ===== QUARTER / HALF ===== */
  void setQuarter(int quarter) {
    // Map MatchHalf to quarter for state
    MatchHalf half;
    switch (quarter) {
      case 1:
      case 2:
        half = MatchHalf.first;
        break;
      case 3:
      case 4:
        half = MatchHalf.second;
        break;
      default:
        half = MatchHalf.extra;
    }
    emit(state.copyWith(matchHalf: half));
    bleService.send(ballBleMapper.setQuarter(quarter));
  }

  void setHalf(MatchHalf half) {
    emit(state.copyWith(matchHalf: half));
    // Map MatchHalf to quarter for BLE
    int quarter;
    switch (half) {
      case MatchHalf.first:
        quarter = 1;
        break;
      case MatchHalf.second:
        quarter = 2;
        break;
      case MatchHalf.extra:
        quarter = 3;
        break;
    }
    bleService.send(ballBleMapper.setQuarter(quarter));
  }

  /* ===== COLOR ===== */
  void updateTeam1Color(Color color) {
    emit(state.copyWith(team1Color: color));
    // Note: No BLE command for color in Handball firmware
  }

  void updateTeam2Color(Color color) {
    emit(state.copyWith(team2Color: color));
    // Note: No BLE command for color in Handball firmware
  }

  /* ===== BRIGHTNESS ===== */
  void setBrightness(int value) {
    emit(state.copyWith(brightness: value.clamp(0, 220)));
    // Note: Brightness NOT supported in Handball firmware
  }

  void setTempBrightness(int value) {
    emit(state.copyWith(tempBrightness: value.clamp(0, 220)));
  }

  /* ===== BUZZER ===== */
  void toggleBuzzer() {
    emit(state.copyWith(buzzerOn: !state.buzzerOn));
    // Note: Buzzer NOT supported in Handball firmware
  }

  /* ===== SYNC ALL TO BLE ===== */
  void syncAllToBle() {
    bleService.send(ballBleMapper.setTeam1Name(state.team1Name));
    bleService.send(ballBleMapper.setTeam2Name(state.team2Name));
    bleService.send(ballBleMapper.setTeam1Score(state.team1Score));
    bleService.send(ballBleMapper.setTeam2Score(state.team2Score));
    bleService.send(ballBleMapper.setTeam1Timeout(state.team1Timeout));
    bleService.send(ballBleMapper.setTeam2Timeout(state.team2Timeout));
    bleService.send(ballBleMapper.setTeam1SevenMeter(state.team1_7m));
    bleService.send(ballBleMapper.setTeam2SevenMeter(state.team2_7m));
    bleService.send(ballBleMapper.setTeam1Suspension(state.team1Suspension));
    bleService.send(ballBleMapper.setTeam2Suspension(state.team2Suspension));

    // Sync quarter based on match half
    int quarter = state.matchHalf == MatchHalf.first ? 1 : (state.matchHalf == MatchHalf.second ? 2 : 3);
    bleService.send(ballBleMapper.setQuarter(quarter));
  }

  /* ===== RESET MATCH ===== */
  void resetMatch() {
    emit(HandballControlState.initial());
    bleService.send(ballBleMapper.resetScreen());
  }
}
