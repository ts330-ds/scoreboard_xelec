import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'khokho_controller_state.dart';

class KhokhoControllerCubit extends Cubit<KhokhoControllerState> {
  KhokhoControllerCubit() : super(const KhokhoControllerState());

  void updateTeam1Name(String name) => emit(state.copyWith(team1Name: name));
  void updateTeam2Name(String name) => emit(state.copyWith(team2Name: name));

  void incrementTeam1Score() => emit(state.copyWith(team1Score: state.team1Score + 1));
  void decrementTeam1Score() {
    if (state.team1Score > 0) {
      emit(state.copyWith(team1Score: state.team1Score - 1));
    }
  }

  // ------ Color ------

  void updateTeam1Color(Color color) => emit(state.copyWith(team1Color: color));
  void updateTeam2Color(Color color) => emit(state.copyWith(team2Color: color));

  void incrementTeam2Score() => emit(state.copyWith(team2Score: state.team2Score + 1));
  void decrementTeam2Score() {
    if (state.team2Score > 0) {
      emit(state.copyWith(team2Score: state.team2Score - 1));
    }
  }

  void incrementInn() {
    if (state.inn < 2) {
      emit(state.copyWith(inn: state.inn + 1));
    }
  }

  void decrementInn() {
    if (state.inn > 1) {
      emit(state.copyWith(inn: state.inn - 1));
    }
  }

  void incrementTurn() {
    if (state.turn < 4) {
      emit(state.copyWith(turn: state.turn + 1));
    }
  }

  void decrementTurn() {
    if (state.turn > 1) {
      emit(state.copyWith(turn: state.turn - 1));
    }
  }

  void updateMatchTime(String time) => emit(state.copyWith(matchTime: time));

  void toggleChasingTeam() => emit(state.copyWith(isTeam1Chasing: !state.isTeam1Chasing));
}
