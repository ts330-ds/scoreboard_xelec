import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/handball_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

import '../../../../../../utility/universal_method.dart';
import 'hand_ball_controller_state.dart';

class HandBallControlCubit extends Cubit<HandballControlState> {
  final BleService bleService;
  final HandBallBleMapper ballBleMapper;

  HandBallControlCubit({required this.bleService, required this.ballBleMapper}) : super(HandballControlState.initial());

  /* ===== TEAM NAMES ===== */

  void exit() {
    emit(HandballControlState.initial());
  }

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
    emit(state.copyWith(team1Score: state.team1Score + 1));
    bleService.send(ballBleMapper.setTeam1Score(state.team1Score));
  }

  void decTeam1Score() {
    if (state.team1Score > 0) {
      emit(state.copyWith(team1Score: state.team1Score - 1));
      bleService.send(ballBleMapper.setTeam1Score(state.team1Score));
    }
  }

  void incTeam2Score() {
    emit(state.copyWith(team2Score: state.team2Score + 1));
    bleService.send(ballBleMapper.setTeam2Score(state.team2Score));
  }

  void decTeam2Score() {
    if (state.team2Score > 0) {
      emit(state.copyWith(team2Score: state.team2Score - 1));
      bleService.send(ballBleMapper.setTeam2Score(state.team2Score));
    }
  }

  /* ===== TIMEOUT ===== */

  void incrementTeam1Timeout() {
    if (state.team1Timeout >= 3) return;

    emit(state.copyWith(team1Timeout: state.team1Timeout + 1));
    bleService.send(ballBleMapper.setTeam1Timeout(state.team1Timeout));
  }

  void decrementTeam1Timeout() {
    if (state.team1Timeout <= 0) return;

    emit(state.copyWith(team1Timeout: state.team1Timeout - 1));
    bleService.send(ballBleMapper.setTeam1Timeout(state.team1Timeout));
  }

  void incrementTeam2Timeout() {
    if (state.team2Timeout >= 3) return;

    emit(state.copyWith(team2Timeout: state.team2Timeout + 1));
    bleService.send(ballBleMapper.setTeam2Timeout(state.team2Timeout));
  }

  void decrementTeam2Timeout() {
    if (state.team2Timeout <= 0) return;

    emit(state.copyWith(team2Timeout: state.team2Timeout - 1));
    bleService.send(ballBleMapper.setTeam2Timeout(state.team2Timeout));
  }

  /* ===== 7m ===== */

  void incTeam1_7m() {
    emit(state.copyWith(team1_7m: state.team1_7m + 1));
    bleService.send(ballBleMapper.setTeam1SevenMinute(true));
  }

  void decTeam1_7m() {
    if (state.team1_7m <= 0) return;

    emit(state.copyWith(team1_7m: state.team1_7m - 1));
    bleService.send(ballBleMapper.setTeam1SevenMinute(false));
  }

  void incTeam2_7m() {
    emit(state.copyWith(team2_7m: state.team2_7m + 1));
    bleService.send(ballBleMapper.setTeam2SevenMinute(true));
  }

  void decTeam2_7m() {
    if (state.team2_7m <= 0) return;
    emit(state.copyWith(team2_7m: state.team2_7m - 1));
    bleService.send(ballBleMapper.setTeam2SevenMinute(false));
  }

  /* ===== SUSPENSION ===== */

  void incTeam1Suspension() {
    emit(state.copyWith(team1Suspension: state.team1Suspension + 2));
    bleService.send(ballBleMapper.setTeam1Suspension(true));
  }

  void incTeam2Suspension() {
    emit(state.copyWith(team2Suspension: state.team2Suspension + 2));
    bleService.send(ballBleMapper.setTeam2Suspension(true));
  }

  void decTeam1Suspension() {
    if (state.team1Suspension <= 0) return;
    emit(state.copyWith(team1Suspension: state.team1Suspension - 2));
    bleService.send(ballBleMapper.setTeam1Suspension(false));
  }

  void decTeam2Suspension() {
    if (state.team2Suspension <= 0) return;
    emit(state.copyWith(team2Suspension: state.team2Suspension - 2));
    bleService.send(ballBleMapper.setTeam2Suspension(false));
  }

  /* ===== QUARTER ===== */


  void setHalf(MatchHalf half) {
    emit(state.copyWith(matchHalf: half));
  }

  /* ===== update Color ===== */
  void updateTeam1Color(Color color) {
    emit(state.copyWith(team1Color: color));
    bleService.send(ballBleMapper.setTeam1Color(colorToHex(color)));
  }

  void updateTeam2Color(Color color) {
    emit(state.copyWith(team2Color: color));
    bleService.send(ballBleMapper.setTeam2Color(colorToHex(color)));
  }
}
