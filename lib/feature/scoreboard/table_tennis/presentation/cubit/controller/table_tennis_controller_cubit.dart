import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/table_tennis_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/utility/universal_method.dart';
import 'table_tennis_controller_state.dart';
import 'package:flutter/material.dart';

class TableTennisControllerCubit extends Cubit<TableTennisControllerState> {
  BleService bleService;
  TableTennisBleMapper tableTennisBleMapper;
  TableTennisControllerCubit({
    required this.bleService,
    required this.tableTennisBleMapper
}) : super(TableTennisControllerState.initial());


  void exit(){
    emit(TableTennisControllerState.initial());
  }
  // ------------------------------------------------
  // TEAM NAMES
  // ------------------------------------------------
  void setTeam1Name(String name) {
    emit(state.copyWith(team1Name: name));
    bleService.send(tableTennisBleMapper.setTeam1Name(name));
  }

  void setTeam2Name(String name) {
    emit(state.copyWith(team2Name: name));
    bleService.send(tableTennisBleMapper.setTeam2Name(name));
  }

  // ------------------------------------------------
  // Color (SAFE)
  // ------------------------------------------------
  void setTeam1Color(Color color) {
    emit(state.copyWith(team1Color: color));
    bleService.send(tableTennisBleMapper.setTeam1Color(toRgb565(color)));

  }

  void setTeam2Color(Color color) {
    emit(state.copyWith(team2Color: color));
    bleService.send(tableTennisBleMapper.setTeam2Color(toRgb565(color)));
  }

  // ------------------------------------------------
  // SCORES (SAFE)
  // ------------------------------------------------
  void incTeam1Score() {
    emit(state.copyWith(team1Score: state.team1Score + 1));
    bleService.send(tableTennisBleMapper.setTeam1Score(state.team1Score));
    // Auto switch serve (every 2 points)
    _autoSwitchServe();
  }

  void decTeam1Score() {
    if (state.team1Score > 0) {
      emit(state.copyWith(team1Score: state.team1Score - 1));
      bleService.send(tableTennisBleMapper.setTeam1Score(state.team1Score));
    }
  }

  void incTeam2Score() {
    emit(state.copyWith(team2Score: state.team2Score + 1));
    bleService.send(tableTennisBleMapper.setTeam2Score(state.team2Score));
    _autoSwitchServe();
  }

  void decTeam2Score() {
    if (state.team2Score > 0) {
      emit(state.copyWith(team2Score: state.team2Score - 1));
      bleService.send(tableTennisBleMapper.setTeam2Score(state.team2Score));
    }
  }

  // ------------------------------------------------
  // AUTO SERVE SWITCH (every 2 points)
  // ------------------------------------------------
  void _autoSwitchServe() {
    if (state.servingTeam == 0) return;

    final totalPoints = state.team1Score + state.team2Score;
    if (totalPoints % 2 == 0) {
      changeServe();
    }
  }

  // ------------------------------------------------
  // MANUAL SERVE CONTROL
  // ------------------------------------------------
  void setInitialServe(int team) {
    // team = 1 or 2
    if (team == 1 || team == 2) {
      emit(state.copyWith(servingTeam: team));
      bleService.send(tableTennisBleMapper.setServe(team));
    }
  }

  void changeServe() {
    if (state.servingTeam == 0) return;
    emit(state.copyWith(servingTeam: state.servingTeam == 1 ? 2 : 1));
    bleService.send(tableTennisBleMapper.setServe(state.servingTeam));

  }

  void incTeam1GamesWon() {
    if (state.team1GamesWon < 4) {
      final newTeam1GamesWon = state.team1GamesWon + 1;

      emit(
        state.copyWith(
          team1GamesWon: newTeam1GamesWon,
          roundPlayed: newTeam1GamesWon + state.team2GamesWon,
        ),
      );
      _resetScoresForNextGame();
    }
  }


  void decTeam1GamesWon() {
    if (state.team1GamesWon > 0) {
      final newTeam1GamesWon = state.team1GamesWon - 1;

      emit(
        state.copyWith(
          team1GamesWon: newTeam1GamesWon,
          roundPlayed: newTeam1GamesWon + state.team2GamesWon,
        ),
      );
    }
  }


  void incTeam2GamesWon() {
    if (state.team2GamesWon < 4) {
      final newTeam2GamesWon = state.team2GamesWon + 1;

      emit(
        state.copyWith(
          team2GamesWon: newTeam2GamesWon,
          roundPlayed: state.team1GamesWon + newTeam2GamesWon,
        ),
      );

      _resetScoresForNextGame();
    }
  }


  void decTeam2GamesWon() {
    if (state.team2GamesWon > 0) {
      final newTeam2GamesWon = state.team2GamesWon - 1;

      emit(
        state.copyWith(
          team2GamesWon: newTeam2GamesWon,
          roundPlayed: state.team1GamesWon + newTeam2GamesWon,
        ),
      );
    }
  }


  void _resetScoresForNextGame() {
    emit(
      state.copyWith(
        team1Score: 0,
        team2Score: 0,
        servingTeam: state.servingTeam == 1 ? 2 : 1, // alternate serve
      ),
    );
  }

  // ------------------------------------------------
  // TIMEOUTS (ONLY ONE TEAM AT A TIME)
  // ------------------------------------------------
  void toggleTeam1Timeout() {
    emit(state.copyWith(team1Timeout: !state.team1Timeout));
  }

  void toggleTeam2Timeout() {
    emit(state.copyWith(team2Timeout: !state.team2Timeout));
  }

  void clearTimeouts() {
    emit(state.copyWith(team1Timeout: false, team2Timeout: false));
  }

  // ------------------------------------------------
  // MATCH CONTROL
  // ------------------------------------------------
  void incrementMatchNumber() {
    emit(state.copyWith(matchNumber: state.matchNumber + 1));
  }

  void decrementMatchNumber() {
    if (state.matchNumber > 1) {
      emit(state.copyWith(matchNumber: state.matchNumber - 1));
    }
  }

  void incrementRoundPlayed() {
    if (state.roundPlayed < state.totalGameRound) {
      emit(state.copyWith(roundPlayed: state.roundPlayed + 1));
    }
  }

  void decrementRoundPlayed() {
    if (state.roundPlayed > 0) {
      emit(state.copyWith(roundPlayed: state.roundPlayed - 1));
    }
  }

  /* void incrementTotalGameRound() {
    if (state.totalGameRound < 7) {
      emit(state.copyWith(
        totalGameRound: state.totalGameRound + 1,
      ));
    }
  }

  void decrementTotalGameRound() {
    if (state.totalGameRound > 1) {
      emit(state.copyWith(
        totalGameRound: state.totalGameRound - 1,
      ));
    }
  }*/

  // ------------------------------------------------
  // RESET MATCH
  // ------------------------------------------------
  void resetMatch() {
    emit(TableTennisControllerState.initial());
  }

  // Brightness (0 - 255)
  void setBrightness(int value) {
    emit(state.copyWith(brightness: value.clamp(0, 255)));
    //bleService.send(basketBallBleMapper.setBrightness(value));
  }

  void setTempBrightness(int value) {
    emit(state.copyWith(tempBrightness: value.clamp(0, 255)));
  }

  // Buzzer toggle
  void toggleBuzzer() {
    emit(state.copyWith(buzzerOn: !state.buzzerOn));
    //bleService.send(state.buzzerOn ? "BBBUZZERON" : "BBBUZZEROFF");
  }
}
