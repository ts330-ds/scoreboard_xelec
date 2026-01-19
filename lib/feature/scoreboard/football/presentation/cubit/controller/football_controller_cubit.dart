import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'football_controller_state.dart';


class FootballControllerCubit extends Cubit<FootballControllerState> {
  FootballControllerCubit() : super(const FootballControllerState());

  void updateTeam1Name(String name) => emit(state.copyWith(team1Name: name));
  void updateTeam2Name(String name) => emit(state.copyWith(team2Name: name));

  void updateTeam1Color(Color color) => emit(state.copyWith(team1Color: color));
  void updateTeam2Color(Color color) => emit(state.copyWith(team2Color: color));

  void incrementTeam1Score() => emit(state.copyWith(team1Score: state.team1Score + 1));
  void decrementTeam1Score() {
    if (state.team1Score > 0) emit(state.copyWith(team1Score: state.team1Score - 1));
  }

  void incrementTeam2Score() => emit(state.copyWith(team2Score: state.team2Score + 1));
  void decrementTeam2Score() {
    if (state.team2Score > 0) emit(state.copyWith(team2Score: state.team2Score - 1));
  }

  void incrementExtraTime() => emit(state.copyWith(extraTime: state.extraTime + 1));
  void decrementExtraTime() {
    if (state.extraTime > 0) emit(state.copyWith(extraTime: state.extraTime - 1));
  }

  void exit(){
    emit(const FootballControllerState());
  }
  void setHalf(int half) => emit(state.copyWith(currentHalf: half));
}
