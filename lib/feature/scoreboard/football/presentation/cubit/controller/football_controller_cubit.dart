import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/football_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/utility/universal_method.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';

import 'football_controller_state.dart';

class FootballControllerCubit extends Cubit<FootballControllerState> {
  final BleService bleService;
  final FootballBleMapper footballBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  FootballControllerCubit({
    required this.bleService,
    required this.footballBleMapper,
    required this.globalErrorCubit,
  }) : super(const FootballControllerState());

  void updateTeam1Name(String name) {
    try {
      emit(state.copyWith(team1Name: name));
      bleService.send(footballBleMapper.setTeam1Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to update team 1 name: $e');
    }
  }

  void updateTeam2Name(String name) {
    try {
      emit(state.copyWith(team2Name: name));
      bleService.send(footballBleMapper.setTeam2Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to update team 2 name: $e');
    }
  }

  void updateTeam1Color(Color color) {
    try {
      emit(state.copyWith(team1Color: color));
      bleService.send(footballBleMapper.setTeam1Color(toRgb565(color)));
    } catch (e) {
      globalErrorCubit.showError('Failed to update team 1 color: $e');
    }
  }

  void updateTeam2Color(Color color) {
    try {
      emit(state.copyWith(team2Color: color));
      bleService.send(footballBleMapper.setTeam2Color(toRgb565(color)));
    } catch (e) {
      globalErrorCubit.showError('Failed to update team 2 color: $e');
    }
  }

  void incrementTeam1Score() {
    try {
      final newScore = state.team1Score + 1;
      emit(state.copyWith(team1Score: newScore));
      bleService.send(footballBleMapper.setTeam1Score(newScore));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 score: $e');
    }
  }

  void decrementTeam1Score() {
    try {
      if (state.team1Score > 0) {
        final newScore = state.team1Score - 1;
        emit(state.copyWith(team1Score: newScore));
        bleService.send(footballBleMapper.setTeam1Score(newScore));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 score: $e');
    }
  }

  void incrementTeam2Score() {
    try {
      final newScore = state.team2Score + 1;
      emit(state.copyWith(team2Score: newScore));
      bleService.send(footballBleMapper.setTeam2Score(newScore));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 score: $e');
    }
  }

  void decrementTeam2Score() {
    try {
      if (state.team2Score > 0) {
        final newScore = state.team2Score - 1;
        emit(state.copyWith(team2Score: newScore));
        bleService.send(footballBleMapper.setTeam2Score(newScore));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 score: $e');
    }
  }

  void incrementExtraTime() {
    try {
      final newExtra = state.extraTime + 1;
      emit(state.copyWith(extraTime: newExtra));
      bleService.send(footballBleMapper.setExtraTime("$newExtra'"));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment extra time: $e');
    }
  }

  void decrementExtraTime() {
    try {
      if (state.extraTime > 0) {
        final newExtra = state.extraTime - 1;
        emit(state.copyWith(extraTime: newExtra));
        bleService.send(footballBleMapper.setExtraTime(newExtra == 0 ? " " : "$newExtra'"));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement extra time: $e');
    }
  }

  void setHalf(int half) {
    try {
      emit(state.copyWith(currentHalf: half));
      if (half == 1) {
        bleService.send(footballBleMapper.setFirstHalf());
      } else {
        bleService.send(footballBleMapper.setSecondHalf());
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to set half: $e');
    }
  }

  void resetScreen() {
    try {
      bleService.send(footballBleMapper.resetScreen());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset screen: $e');
    }
  }

  void triggerBuzzer() {
    try {
     // bleService.send(footballBleMapper.triggerBuzzer());
    } catch (e) {
      globalErrorCubit.showError('Failed to trigger buzzer: $e');
    }
  }

  // Brightness (0 - 255)
  void setBrightness(int value) {
    try {
      emit(state.copyWith(brightness: value.clamp(0, 220)));
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
    } catch (e) {
      globalErrorCubit.showError('Failed to toggle buzzer: $e');
    }
  }

  void exit() {
    try {
      emit(const FootballControllerState());
    } catch (e) {
      globalErrorCubit.showError('Failed to exit: $e');
    }
  }
}
