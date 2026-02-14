import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/table_tennis_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/utility/universal_method.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'table_tennis_controller_state.dart';
import 'package:flutter/material.dart';

class TableTennisControllerCubit extends Cubit<TableTennisControllerState> {
  final BleService bleService;
  final TableTennisBleMapper tableTennisBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  TableTennisControllerCubit({
    required this.bleService,
    required this.tableTennisBleMapper,
    required this.globalErrorCubit,
  }) : super(TableTennisControllerState.initial());

  void exit() {
    try {
      emit(TableTennisControllerState.initial());
      bleService.send(tableTennisBleMapper.resetScreen());
    } catch (e) {
      globalErrorCubit.showError('Failed to exit: $e');
    }
  }

  // ------------------------------------------------
  // TEAM NAMES
  // ------------------------------------------------
  void setTeam1Name(String name) {
    try {
      emit(state.copyWith(team1Name: name));
      bleService.send(tableTennisBleMapper.setPlayer1Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 1 name: $e');
    }
  }

  void setTeam2Name(String name) {
    try {
      emit(state.copyWith(team2Name: name));
      bleService.send(tableTennisBleMapper.setPlayer2Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 2 name: $e');
    }
  }

  // ------------------------------------------------
  // Color (SAFE)
  // ------------------------------------------------
  void setTeam1Color(Color color) {
    try {
      emit(state.copyWith(team1Color: color));
      bleService.send(
        tableTennisBleMapper.setPlayer1BgColor(
          toRgb565(color).toRadixString(16).padLeft(4, '0').toUpperCase(),
        ),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 1 color: $e');
    }
  }

  void setTeam2Color(Color color) {
    try {
      emit(state.copyWith(team2Color: color));
      bleService.send(
        tableTennisBleMapper.setPlayer2BgColor(
          toRgb565(color).toRadixString(16).padLeft(4, '0').toUpperCase(),
        ),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 2 color: $e');
    }
  }

  // ------------------------------------------------
  // SCORES (SAFE)
  // ------------------------------------------------
  void incTeam1Score() {
    try {
      final newValue = state.team1Score + 1;
      emit(state.copyWith(team1Score: newValue));
      bleService.send(tableTennisBleMapper.setPlayer1Score(newValue));
      // Auto switch serve (every 2 points)
      _autoSwitchServe();
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 score: $e');
    }
  }

  void decTeam1Score() {
    try {
      if (state.team1Score > 0) {
        final newValue = state.team1Score - 1;
        emit(state.copyWith(team1Score: newValue));
        bleService.send(tableTennisBleMapper.setPlayer1Score(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 score: $e');
    }
  }

  void incTeam2Score() {
    try {
      final newValue = state.team2Score + 1;
      emit(state.copyWith(team2Score: newValue));
      bleService.send(tableTennisBleMapper.setPlayer2Score(newValue));
      _autoSwitchServe();
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 score: $e');
    }
  }

  void decTeam2Score() {
    try {
      if (state.team2Score > 0) {
        final newValue = state.team2Score - 1;
        emit(state.copyWith(team2Score: newValue));
        bleService.send(tableTennisBleMapper.setPlayer2Score(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 score: $e');
    }
  }

  // ------------------------------------------------
  // AUTO SERVE SWITCH (every 2 points)
  // ------------------------------------------------
  void _autoSwitchServe() {
    try {
      if (state.servingTeam == 0) return;

      final totalPoints = state.team1Score + state.team2Score;
      if (totalPoints % 2 == 0) {
        changeServe();
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to auto switch serve: $e');
    }
  }

  // ------------------------------------------------
  // MANUAL SERVE CONTROL
  // ------------------------------------------------
  void setInitialServe(int team) {
    try {
      // team = 1 or 2
      if (team == 1 || team == 2) {
        emit(state.copyWith(servingTeam: team));
        bleService.send(tableTennisBleMapper.setServing(team));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to set initial serve: $e');
    }
  }

  void changeServe() {
    try {
      if (state.servingTeam == 0) return;
      emit(state.copyWith(servingTeam: state.servingTeam == 1 ? 2 : 1));
      bleService.send(tableTennisBleMapper.setServing(state.servingTeam));
    } catch (e) {
      globalErrorCubit.showError('Failed to change serve: $e');
    }
  }

  void incTeam1GamesWon() {
    try {
      if (state.team1GamesWon < 4) {
        final newTeam1GamesWon = state.team1GamesWon + 1;
        emit(
          state.copyWith(
            team1GamesWon: newTeam1GamesWon,
            //roundPlayed: newTeam1GamesWon + state.team2GamesWon,
          ),
        );
        bleService.send(
          tableTennisBleMapper.setPlayer1GamesWon(newTeam1GamesWon),
        );
        _resetScoresForNextGame();
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 games won: $e');
    }
  }

  void decTeam1GamesWon() {
    try {
      if (state.team1GamesWon > 0) {
        final newTeam1GamesWon = state.team1GamesWon - 1;
        emit(
          state.copyWith(
            team1GamesWon: newTeam1GamesWon,
            //roundPlayed: newTeam1GamesWon + state.team2GamesWon,
          ),
        );
        bleService.send(
          tableTennisBleMapper.setPlayer1GamesWon(newTeam1GamesWon),
        );
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 games won: $e');
    }
  }

  void incTeam2GamesWon() {
    try {
      if (state.team2GamesWon < 4) {
        final newTeam2GamesWon = state.team2GamesWon + 1;
        emit(
          state.copyWith(
            team2GamesWon: newTeam2GamesWon,
           // roundPlayed: state.team1GamesWon + newTeam2GamesWon,
          ),
        );
        bleService.send(
          tableTennisBleMapper.setPlayer2GamesWon(newTeam2GamesWon),
        );
        _resetScoresForNextGame();
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 games won: $e');
    }
  }

  void decTeam2GamesWon() {
    try {
      if (state.team2GamesWon > 0) {
        final newTeam2GamesWon = state.team2GamesWon - 1;
        emit(
          state.copyWith(
            team2GamesWon: newTeam2GamesWon,
            //roundPlayed: state.team1GamesWon + newTeam2GamesWon,
          ),
        );
        bleService.send(
          tableTennisBleMapper.setPlayer2GamesWon(newTeam2GamesWon),
        );
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 games won: $e');
    }
  }

  void _resetScoresForNextGame() {
    try {
      emit(
        state.copyWith(
          team1Score: 0,
          team2Score: 0,
          //servingTeam: state.servingTeam == 1 ? 2 : 1, // alternate serve
        ),
      );
      bleService.send(tableTennisBleMapper.setPlayer1Score(0));
      bleService.send(tableTennisBleMapper.setPlayer2Score(0));
      //bleService.send(tableTennisBleMapper.setServing(state.servingTeam));
    } catch (e) {
      globalErrorCubit.showError('Failed to reset scores for next game: $e');
    }
  }

  // ------------------------------------------------
  // TIMEOUTS (ONLY ONE TEAM AT A TIME)
  // ------------------------------------------------
  
  void toggleTeam1Timeout() {
  try {
    // 1. Determine the new state
    final bool newTimeoutState = !state.team1Timeout;
    // 2. Convert boolean to int (1 for true, 0 for false)
    final int bleValue = newTimeoutState ? 1 : 2;

    // 3. Update UI and send to BLE
    emit(state.copyWith(team1Timeout: newTimeoutState));
    bleService.send(tableTennisBleMapper.setPlayer1Timeout(bleValue));
    
  } catch (e) {
    globalErrorCubit.showError('Failed to toggle team 1 timeout: $e');
  }
}

void toggleTeam2Timeout() {
  try {
    // 1. Determine the new state
    final bool newTimeoutState = !state.team2Timeout;
    // 2. Convert boolean to int (1 for true, 0 for false)
    final int bleValue = newTimeoutState ? 1 : 2;
    
    // 3. Update UI and send to BLE
    emit(state.copyWith(team2Timeout: newTimeoutState));
    bleService.send(tableTennisBleMapper.setPlayer2Timeout(bleValue));
    
  } catch (e) {
    globalErrorCubit.showError('Failed to toggle team 2 timeout: $e');
  }
}


  void clearTimeouts() {
    try {
      emit(state.copyWith(team1Timeout: false, team2Timeout: false));
      bleService.send(tableTennisBleMapper.setPlayer1Timeout(0));
      bleService.send(tableTennisBleMapper.setPlayer2Timeout(0));
    } catch (e) {
      globalErrorCubit.showError('Failed to clear timeouts: $e');
    }
  }

  // ------------------------------------------------
  // MATCH CONTROL
  // ------------------------------------------------
  void incrementMatchNumber() {
    try {
      int newValue = state.matchNumber + 1;
      emit(state.copyWith(matchNumber: newValue));
      bleService.send( tableTennisBleMapper.setMatchNumber(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment match number: $e');
    }
  }

  void decrementMatchNumber() {
    try {
      if (state.matchNumber > 1) {
        int newValue = state.matchNumber - 1;
        emit(state.copyWith(matchNumber: newValue));
        bleService.send( tableTennisBleMapper.setMatchNumber(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement match number: $e');
    }
  }

  void incrementRoundPlayed() {
    try {
      if (state.roundPlayed < state.totalGameRound) {
        int newValue = state.roundPlayed + 1;
        emit(state.copyWith(roundPlayed: newValue));
        bleService.send( tableTennisBleMapper.setMatchNumber(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to increment round played: $e');
    }
  }

  void decrementRoundPlayed() {
    try {
      if (state.roundPlayed > 0) {
        int newValue = state.roundPlayed - 1;
        emit(state.copyWith(roundPlayed: newValue));
        bleService.send(tableTennisBleMapper.setMatchNumber(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement round played: $e');
    }
  }

  // ------------------------------------------------
  // RESET MATCH
  // ------------------------------------------------
  void resetMatch() {
    try {
      emit(TableTennisControllerState.initial());
      bleService.send(tableTennisBleMapper.resetScreen());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset match: $e');
    }
  }

  // Brightness (0 - 255)
  void setBrightness(int value) {
    try {
      emit(state.copyWith(brightness: value.clamp(0, 220)));
      bleService.send("BRIG${value.clamp(0, 220)}");
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
}
