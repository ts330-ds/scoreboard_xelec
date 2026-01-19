import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/hockey_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'hockey_controller_state.dart';

class HockeyControllerCubit extends Cubit<HockeyControllerState> {
  BleService bleService;
  HockeyBleMapper bleMapper;
  HockeyControllerCubit({
    required this.bleService,
    required this.bleMapper
}) : super(HockeyControllerState.initial());

  // ---------------- TEAM NAMES ----------------
  void setTeam1Name(String name) {
    emit(state.copyWith(team1Name: name));
    bleService.send(bleMapper.setHomeTeamName(name));
  }

  void setTeam2Name(String name) {
    emit(state.copyWith(team2Name: name));
    bleService.send(bleMapper.setAwayTeamName(name));
  }

  // ---------------- SCORES ----------------
  void incTeam1Score() {
    emit(state.copyWith(team1Score: state.team1Score + 1));
    bleService.send(bleMapper.incrementHomeScore());
  }

  void decTeam1Score() {
    if (state.team1Score > 0) {
      emit(state.copyWith(team1Score: state.team1Score - 1));
      bleService.send(bleMapper.incrementHomeScore());
    }
  }

  void incTeam2Score() {
    emit(state.copyWith(team2Score: state.team2Score + 1));
  }

  void decTeam2Score() {
    if (state.team2Score > 0) {
      emit(state.copyWith(team2Score: state.team2Score - 1));
    }
  }

  // ---------------- PENALTY CORNERS ----------------
  void incTeam1PenaltyCorner() {
    emit(state.copyWith(
      team1PenaltyCorner: state.team1PenaltyCorner + 1,
    ));
  }

  void decTeam1PenaltyCorner() {
    if (state.team1PenaltyCorner > 0) {
      emit(state.copyWith(
        team1PenaltyCorner: state.team1PenaltyCorner - 1,
      ));
    }
  }

  void incTeam2PenaltyCorner() {
    emit(state.copyWith(
      team2PenaltyCorner: state.team2PenaltyCorner + 1,
    ));
  }

  void decTeam2PenaltyCorner() {
    if (state.team2PenaltyCorner > 0) {
      emit(state.copyWith(
        team2PenaltyCorner: state.team2PenaltyCorner - 1,
      ));
    }
  }

  // ---------------- SHOOTOUTS ----------------
  void incTeam1Shootout() {
    emit(state.copyWith(team1Shootout: state.team1Shootout + 1));
  }

  void decTeam1Shootout() {
    if (state.team1Shootout > 0) {
      emit(state.copyWith(team1Shootout: state.team1Shootout - 1));
    }
  }

  void incTeam2Shootout() {
    emit(state.copyWith(team2Shootout: state.team2Shootout + 1));
  }

  void decTeam2Shootout() {
    if (state.team2Shootout > 0) {
      emit(state.copyWith(team2Shootout: state.team2Shootout - 1));
    }
  }
  void exit(){
    emit(HockeyControllerState.initial());
  }

  // ------- Color ----------
  void setTeam1Color(Color color) {
    emit(state.copyWith(team1Color: color));
  }
  void setTeam2Color(Color color){
    emit(state.copyWith(team2Color: color));
  }
  // ---------------- RESET ----------------
  void reset() {
    emit(HockeyControllerState.initial());
  }
}
