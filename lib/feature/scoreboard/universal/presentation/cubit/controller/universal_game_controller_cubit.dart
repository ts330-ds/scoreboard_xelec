import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/cubit/controller/universal_game_controller_state.dart';

import '../../../../../../error/cubit/error_cubit.dart';
import '../../../../../bluetooth/mapper/universal_game_ble_mapper.dart';
import '../../../../../bluetooth/service/ble_service.dart';
import 'package:flutter/material.dart';

class UniversalGameControllerCubit extends Cubit<UniversalGameControllerState> {
  BleService bleService;
  UniversalGameBleMapper bleMapper;
  GlobalErrorCubit globalErrorCubit;

  UniversalGameControllerCubit({
    required this.bleService,
    required this.bleMapper,
    required this.globalErrorCubit,
  }) : super(UniversalGameControllerState.initial());

  // ------------------------------------------------
  // HELPER: Convert PlayerType to int for BLE
  // ------------------------------------------------
  int _playerTypeToInt(PlayerType? player) {
    if (player == null) return 0;
    return player == PlayerType.player1 ? 1 : 2;
  }

  // ------------------------------------------------
  // TEAM NAME SETTERS
  // ------------------------------------------------
  void setTeam1Name(String name) {
    emit(state.copyWith(team1Name: name));
    bleService.send(bleMapper.setPlayer1Name(name));
  }

  void setTeam2Name(String name) {
    emit(state.copyWith(team2Name: name));
    bleService.send(bleMapper.setPlayer2Name(name));
  }

  // ------------------------------------------------
  // TEAM COLOR SETTERS
  // ------------------------------------------------
  void setTeam1Color(Color color) {
    emit(state.copyWith(team1Color: color));
    // Note: No BLE command for color in firmware
  }

  void setTeam2Color(Color color) {
    emit(state.copyWith(team2Color: color));
    // Note: No BLE command for color in firmware
  }

  // ------------------------------------------------
  // TOTAL SETS (3 or 5)
  // ------------------------------------------------
  void setTotalSets(TotalSets sets) {
    emit(state.copyWith(
      totalSets: sets,
      selectedSet: 1,
    ));
    bleService.send(bleMapper.setTotalSets(sets.count));
  }

  // ------------------------------------------------
  // SELECT SET (S1..S5)
  // ------------------------------------------------
  void selectSet(int setNo) {
    if (setNo < 1 || setNo > state.maxSets) return;
    emit(state.copyWith(selectedSet: setNo));
  }

  // ------------------------------------------------
  // SELECT ACTIVE PLAYER
  // ------------------------------------------------
  void selectPlayer(PlayerType player) {
    emit(state.copyWith(activePlayer: player));
  }

  // ------------------------------------------------
  // INCREMENT SCORE (selectedSet + activePlayer)
  // ------------------------------------------------
  void incrementScore() {
    final idx = state.selectedSet - 1;

    if (state.activePlayer == PlayerType.player1) {
      final list = List<int>.from(state.p1Scores);
      list[idx]++;
      emit(state.copyWith(p1Scores: list));
      bleService.send(bleMapper.setPlayer1SetScore(state.selectedSet, list[idx]));
      bleService.send(bleMapper.setPlayer1Score(list[idx]));
    } else {
      final list = List<int>.from(state.p2Scores);
      list[idx]++;
      emit(state.copyWith(p2Scores: list));
      bleService.send(bleMapper.setPlayer2SetScore(state.selectedSet, list[idx]));
      bleService.send(bleMapper.setPlayer2Score(list[idx]));
    }
  }

  // ------------------------------------------------
  // DECREMENT SCORE (guarded)
  // ------------------------------------------------
  void decrementScore() {
    final idx = state.selectedSet - 1;

    if (state.activePlayer == PlayerType.player1) {
      final list = List<int>.from(state.p1Scores);
      if (list[idx] == 0) return;
      list[idx]--;
      emit(state.copyWith(p1Scores: list));
      bleService.send(bleMapper.setPlayer1SetScore(state.selectedSet, list[idx]));
      bleService.send(bleMapper.setPlayer1Score(list[idx]));
    } else {
      final list = List<int>.from(state.p2Scores);
      if (list[idx] == 0) return;
      list[idx]--;
      emit(state.copyWith(p2Scores: list));
      bleService.send(bleMapper.setPlayer2SetScore(state.selectedSet, list[idx]));
      bleService.send(bleMapper.setPlayer2Score(list[idx]));
    }
  }

  // ------------------------------------------------
  // SET WINNER
  // ------------------------------------------------
  void setWinner(int setNo, PlayerType winner) {
    final winners = List<PlayerType?>.from(state.setWinners);
    winners[setNo - 1] = winner;
    emit(state.copyWith(setWinners: winners));
    bleService.send(bleMapper.setSetWinner(setNo, _playerTypeToInt(winner)));
  }

  // ------------------------------------------------
  // CLEAR WINNER
  // ------------------------------------------------
  void clearWinner(int setNo) {
    final winners = List<PlayerType?>.from(state.setWinners);
    winners[setNo - 1] = null;
    emit(state.copyWith(setWinners: winners));
    bleService.send(bleMapper.setSetWinner(setNo, 0));
  }

  // ------------------------------------------------
  // BUZZER
  // ------------------------------------------------
  void triggerBuzzer() {
    bleService.send(bleMapper.triggerBuzzer());
  }

  // ------------------------------------------------
  // BRIGHTNESS (0-255)
  // ------------------------------------------------
  void setBrightness(int value) {
    final clampedValue = value.clamp(0, 255);
    bleService.send(bleMapper.setBrightness(clampedValue));
  }

  // ------------------------------------------------
  // RESET MATCH
  // ------------------------------------------------
  void resetMatch() {
    emit(UniversalGameControllerState.initial());
    bleService.send(bleMapper.resetScreen());
  }

  // ------------------------------------------------
  // SYNC ALL STATE TO BLE (after reconnection)
  // ------------------------------------------------
  void syncAllToBle() {
    // Total sets
    bleService.send(bleMapper.setTotalSets(state.totalSets.count));

    // Names
    bleService.send(bleMapper.setPlayer1Name(state.team1Name));
    bleService.send(bleMapper.setPlayer2Name(state.team2Name));

    // Current scores (from selected set)
    final p1CurrentScore = state.p1Scores[state.selectedSet - 1];
    final p2CurrentScore = state.p2Scores[state.selectedSet - 1];
    bleService.send(bleMapper.setPlayer1Score(p1CurrentScore));
    bleService.send(bleMapper.setPlayer2Score(p2CurrentScore));

    // All set scores
    for (int i = 0; i < state.maxSets; i++) {
      bleService.send(bleMapper.setPlayer1SetScore(i + 1, state.p1Scores[i]));
      bleService.send(bleMapper.setPlayer2SetScore(i + 1, state.p2Scores[i]));
      bleService.send(bleMapper.setSetWinner(i + 1, _playerTypeToInt(state.setWinners[i])));
    }
  }

  // ------------------------------------------------
  // EXIT / DISPOSE
  // ------------------------------------------------
  void exit() {
    emit(UniversalGameControllerState.initial());
  }
}
