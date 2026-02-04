import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/basketball_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/presentation/cubit/ble/ble_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

import '../../../../../../utility/universal_method.dart';
import 'controlPanalState.dart';

class BasketControlPanelCubit extends Cubit<ControlPanelState> {
  final BleService bleService;
  final BasketBallBleMapper basketBallBleMapper;
  final GlobalErrorCubit globalErrorCubit;
  BasketControlPanelCubit({
    required this.bleService,
    required this.basketBallBleMapper,
    required this.globalErrorCubit
}) : super(ControlPanelState.initial());

  // Team names
  void setTeam1Name(String name) {
    emit(state.copyWith(team1Name: name));
    bleService.send(basketBallBleMapper.setHomeTeamName(name));
  }

  void exit(){
    emit(ControlPanelState.initial());
  }

  void setTeam2Name(String name) {
    emit(state.copyWith(team2Name: name));
    bleService.send(basketBallBleMapper.setAwayTeamName(name));
  }

  // Team colors
  void setTeam1Color(Color color) {
    emit(state.copyWith(team1Color: color));
    bleService.send(basketBallBleMapper.setHomeTeamColor(toRgb565(color).toRadixString(16).padLeft(4, '0')
        .toUpperCase()));
  }

  void setTeam2Color(Color color) {
    emit(state.copyWith(team2Color: color));
    bleService.send(basketBallBleMapper.setAwayTeamColor(toRgb565(color).toRadixString(16).padLeft(4, '0')
        .toUpperCase()));
  }

  // Quarter
  void setQuarter(int quarter) {
    emit(state.copyWith(quarter: quarter));

    switch (quarter) {
      case 1:
        bleService.send(basketBallBleMapper.setQuarter1());
        break;
      case 2:
        bleService.send(basketBallBleMapper.setQuarter2());
        break;
      case 3:
        bleService.send(basketBallBleMapper.setQuarter3());
        break;
      case 4:
        bleService.send(basketBallBleMapper.setQuarter4());
        break;
      default:
      // optional safety
        return;
    }
  }


  // Scores
  void incrementTeam1() {
    emit(state.copyWith(team1Score: state.team1Score + 1));
    bleService.send(basketBallBleMapper.setHomeScore(state.team1Score));
  }

  void decrementTeam1() {
    if (state.team1Score > 0) {
      emit(state.copyWith(team1Score: state.team1Score - 1));
      bleService.send(basketBallBleMapper.setHomeScore(state.team1Score));
    }
  }

  void incrementTeam2() {
    emit(state.copyWith(team2Score: state.team2Score + 1));
    bleService.send(basketBallBleMapper.setAwayScore(state.team2Score));
  }

  void decrementTeam2() {
    if (state.team2Score > 0) {
      emit(state.copyWith(team2Score: state.team2Score - 1));
      bleService.send(basketBallBleMapper.setAwayScore(state.team2Score));
    }
  }

  // Brightness (0 - 255)
  void setBrightness(int value) {
    emit(state.copyWith(brightness: value.clamp(0, 220)));
    print("Code is ${"BRIG${value.clamp(0, 220)}"}");
    bleService.send("BRIG${value.clamp(0, 220)}");
  }

  void setTempBrightness(int value) {
    emit(state.copyWith(tempBrightness: value.clamp(0, 220)));
  }

  // Buzzer toggle
  void toggleBuzzer() {
    emit(state.copyWith(buzzerOn: !state.buzzerOn));
    bleService.send(state.buzzerOn ? "BBBUZZERON" : "BBBUZZEROFF");
  }

  // Reset scores only
  void resetScores() {
    emit(
      state.copyWith(
        team1Score: 0,
        team2Score: 0,
      ),
    );
  }
}
