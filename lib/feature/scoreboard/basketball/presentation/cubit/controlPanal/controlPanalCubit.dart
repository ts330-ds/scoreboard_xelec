import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/basketball_ble_mapper.dart';
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
    required this.globalErrorCubit,
  }) : super(ControlPanelState.initial());

  // Team names
  void setTeam1Name(String name) {
    try {
      emit(state.copyWith(team1Name: name));
      bleService.send(basketBallBleMapper.setHomeTeamName(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 1 name: $e');
    }
  }

  void exit() {
    try {
      emit(ControlPanelState.initial());
    } catch (e) {
      globalErrorCubit.showError('Failed to exit: $e');
    }
  }

  void setTeam2Name(String name) {
    try {
      emit(state.copyWith(team2Name: name));
      bleService.send(basketBallBleMapper.setAwayTeamName(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 2 name: $e');
    }
  }

  // Team colors
  void setTeam1Color(Color color) {
    try {
      emit(state.copyWith(team1Color: color));
      bleService.send(
        basketBallBleMapper.setHomeTeamColor(
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
        basketBallBleMapper.setAwayTeamColor(
          toRgb565(color).toRadixString(16).padLeft(4, '0').toUpperCase(),
        ),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 2 color: $e');
    }
  }

  // Quarter
  void setQuarter(int quarter) {
    try {
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
          return;
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to set quarter: $e');
    }
  }

  // Scores
  void incrementTeam1() {
    try {
      emit(state.copyWith(team1Score: state.team1Score + 1));
      bleService.send(basketBallBleMapper.setHomeScore(state.team1Score));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 score: $e');
    }
  }

  void decrementTeam1() {
    try {
      if (state.team1Score > 0) {
        emit(state.copyWith(team1Score: state.team1Score - 1));
        bleService.send(basketBallBleMapper.setHomeScore(state.team1Score));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 score: $e');
    }
  }

  void incrementTeam2() {
    try {
      emit(state.copyWith(team2Score: state.team2Score + 1));
      bleService.send(basketBallBleMapper.setAwayScore(state.team2Score));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 score: $e');
    }
  }

  void decrementTeam2() {
    try {
      if (state.team2Score > 0) {
        emit(state.copyWith(team2Score: state.team2Score - 1));
        bleService.send(basketBallBleMapper.setAwayScore(state.team2Score));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 score: $e');
    }
  }

  // Brightness (0 - 255)
  void setBrightness(int value) {
    try {
      emit(state.copyWith(brightness: value.clamp(0, 220)));
      debugPrint("Code is ${"BRIG${value.clamp(0, 220)}"}");
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

  // Buzzer toggle
  void toggleBuzzer() {
    try {
      emit(state.copyWith(buzzerOn: !state.buzzerOn));
      bleService.send(state.buzzerOn ? "BUZZON" : "BUZZOFF");
    } catch (e) {
      globalErrorCubit.showError('Failed to toggle buzzer: $e');
    }
  }

  // Reset scores only
  void resetScores() {
    try {
      emit(state.copyWith(team1Score: 0, team2Score: 0));
    } catch (e) {
      globalErrorCubit.showError('Failed to reset scores: $e');
    }
  }
}
