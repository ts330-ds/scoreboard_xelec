import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/cubit/controller/universal_game_controller_state.dart';

import '../../../../../../error/cubit/error_cubit.dart';
import '../../../../../bluetooth/mapper/universal_game_ble_mapper.dart';
import '../../../../../bluetooth/service/ble_service.dart';
import 'package:flutter/material.dart';

class UniversalGameControllerCubit extends Cubit<UniversalGameControllerState> {
  final BleService bleService;
  final UniversalGameBleMapper bleMapper;
  final GlobalErrorCubit globalErrorCubit;

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
    try {
      emit(state.copyWith(team1Name: name));
      bleService.send(bleMapper.setPlayer1Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 1 name: $e');
    }
  }

  void setTeam2Name(String name) {
    try {
      emit(state.copyWith(team2Name: name));
      bleService.send(bleMapper.setPlayer2Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 2 name: $e');
    }
  }

  // ------------------------------------------------
  // TEAM COLOR SETTERS
  // ------------------------------------------------
  void setTeam1Color(Color color) {
    try {
      emit(state.copyWith(team1Color: color));
      // Note: No BLE command for color in firmware
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 1 color: $e');
    }
  }

  void setTeam2Color(Color color) {
    try {
      emit(state.copyWith(team2Color: color));
      // Note: No BLE command for color in firmware
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 2 color: $e');
    }
  }

  // ------------------------------------------------
  // TOTAL SETS (3 or 5)
  // ------------------------------------------------
  void setTotalSets(TotalSets sets) {
    try {
      emit(state.copyWith(
        totalSets: sets,
        selectedSet: 1,
      ));
      bleService.send(bleMapper.setTotalSets(sets.count));
    } catch (e) {
      globalErrorCubit.showError('Failed to set total sets: $e');
    }
  }

  // ------------------------------------------------
  // SELECT SET (S1..S5)
  // ------------------------------------------------
  void selectSet(int setNo) {
    try {
      if (setNo < 1 || setNo > state.maxSets) return;
      emit(state.copyWith(selectedSet: setNo));
    } catch (e) {
      globalErrorCubit.showError('Failed to select set: $e');
    }
  }

  // ------------------------------------------------
  // SELECT ACTIVE PLAYER
  // ------------------------------------------------
  void selectPlayer(PlayerType player) {
    try {
      emit(state.copyWith(activePlayer: player));
    } catch (e) {
      globalErrorCubit.showError('Failed to select player: $e');
    }
  }

  // ------------------------------------------------
  // INCREMENT SCORE (selectedSet + activePlayer)
  // ------------------------------------------------
  void incrementScore() {
    try {
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
    } catch (e) {
      globalErrorCubit.showError('Failed to increment score: $e');
    }
  }

  // ------------------------------------------------
  // DECREMENT SCORE (guarded)
  // ------------------------------------------------
  void decrementScore() {
    try {
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
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement score: $e');
    }
  }

  // ------------------------------------------------
  // SET WINNER
  // ------------------------------------------------
  void setWinner(int setNo, PlayerType winner) {
    try {
      final winners = List<PlayerType?>.from(state.setWinners);
      winners[setNo - 1] = winner;
      emit(state.copyWith(setWinners: winners));
      bleService.send(bleMapper.setSetWinner(setNo, _playerTypeToInt(winner)));
    } catch (e) {
      globalErrorCubit.showError('Failed to set winner: $e');
    }
  }

  // ------------------------------------------------
  // CLEAR WINNER
  // ------------------------------------------------
  void clearWinner(int setNo) {
    try {
      final winners = List<PlayerType?>.from(state.setWinners);
      winners[setNo - 1] = null;
      emit(state.copyWith(setWinners: winners));
      bleService.send(bleMapper.setSetWinner(setNo, 0));
    } catch (e) {
      globalErrorCubit.showError('Failed to clear winner: $e');
    }
  }

  // ------------------------------------------------
  // BUZZER
  // ------------------------------------------------
  void triggerBuzzer() {
    try {
      bleService.send(bleMapper.triggerBuzzer());
    } catch (e) {
      globalErrorCubit.showError('Failed to trigger buzzer: $e');
    }
  }

  // ------------------------------------------------
  // BRIGHTNESS (0-255)
  // ------------------------------------------------
  void setBrightness(int value) {
    try {
      final clampedValue = value.clamp(0, 220);
      bleService.send(bleMapper.setBrightness(clampedValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to set brightness: $e');
    }
  }

  void setTempBrightness(int value) {
    try {
      emit(state.copyWith(tempBrightness: value.clamp(0, 220)));
    } catch (e) {
      globalErrorCubit.showError('Failed to set temp brightness: $e');
    }
  }


  // ------------------------------------------------
  // RESET MATCH
  // ------------------------------------------------
  void resetMatch() {
    try {
      emit(UniversalGameControllerState.initial());
      bleService.send(bleMapper.resetScreen());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset match: $e');
    }
  }

  // ------------------------------------------------
  // SYNC ALL STATE TO BLE (after reconnection)
  // ------------------------------------------------
  void syncAllToBle() {
    try {
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
    } catch (e) {
      globalErrorCubit.showError('Failed to sync all to BLE: $e');
    }
  }




  // ------------------------------------------------
  // EXIT / DISPOSE
  // ------------------------------------------------
  void exit() {
    try {
      emit(UniversalGameControllerState.initial());
    } catch (e) {
      globalErrorCubit.showError('Failed to exit: $e');
    }
  }
}
