
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/universal_method.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';

import '../../../../../bluetooth/mapper/khokho_ble_mapper.dart';
import '../../../../../bluetooth/service/ble_service.dart';

part 'khokho_controller_state.dart';

class KhokhoControllerCubit extends Cubit<KhokhoControllerState> {
  final BleService bleService;
  final KhoKhoBleMapper khoBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  KhokhoControllerCubit({
    required this.bleService,
    required this.khoBleMapper,
    required this.globalErrorCubit,
  }) : super(const KhokhoControllerState());

  void updateTeam1Name(String name) {
    try {
      emit(state.copyWith(team1Name: name));
      bleService.send(khoBleMapper.setTeam1Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to update team 1 name: $e');
    }
  }

  void updateTeam2Name(String name) {
    try {
      emit(state.copyWith(team2Name: name));
      bleService.send(khoBleMapper.setTeam2Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to update team 2 name: $e');
    }
  }

  void incrementTeam1Score() {
    try {
      final newScore = state.team1Score + 1;
      emit(state.copyWith(team1Score: newScore));
      bleService.send(khoBleMapper.setTeam1Score(newScore));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 score: $e');
    }
  }

  void decrementTeam1Score() {
    try {
      if (state.team1Score > 0) {
        final newScore = state.team1Score - 1;
        emit(state.copyWith(team1Score: newScore));
        bleService.send(khoBleMapper.setTeam1Score(newScore));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 score: $e');
    }
  }

  void incrementTeam2Score() {
    try {
      final newScore = state.team2Score + 1;
      emit(state.copyWith(team2Score: newScore));
      bleService.send(khoBleMapper.setTeam2Score(newScore));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 score: $e');
    }
  }

  void decrementTeam2Score() {
    try {
      if (state.team2Score > 0) {
        final newScore = state.team2Score - 1;
        emit(state.copyWith(team2Score: newScore));
        bleService.send(khoBleMapper.setTeam2Score(newScore));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 score: $e');
    }
  }

  // ------ Color ------

  void updateTeam1Color(Color color) {
    try {
      emit(state.copyWith(team1Color: color));
      bleService.send(khoBleMapper.setTeam1Color(
        toRgb565(color).toRadixString(16).padLeft(4, '0').toUpperCase()
        ));
    } catch (e) {
      globalErrorCubit.showError('Failed to update team 1 color: $e');
    }
  }

  void updateTeam2Color(Color color) {
    try {
      emit(state.copyWith(team2Color: color));
      bleService.send(khoBleMapper.setTeam2Color(
        toRgb565(color).toRadixString(16).padLeft(4, '0').toUpperCase()
        ));
    } catch (e) {
      globalErrorCubit.showError('Failed to update team 2 color: $e');
    }
  }

  void incrementInn() {
    try {
      if (state.inn < 2) {
        final newInn = state.inn + 1;
        emit(state.copyWith(inn: newInn));
        bleService.send(khoBleMapper.setInning(newInn));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to increment innings: $e');
    }
  }

  void decrementInn() {
    try {
      if (state.inn > 1) {
        final newInn = state.inn - 1;
        emit(state.copyWith(inn: newInn));
        bleService.send(khoBleMapper.setInning(newInn));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement innings: $e');
    }
  }

  void incrementTurn() {
    try {
      if (state.turn < 4) {
        final newTurn = state.turn + 1;
        emit(state.copyWith(turn: newTurn));
        bleService.send(khoBleMapper.setTurn(newTurn));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to increment turn: $e');
    }
  }

  void decrementTurn() {
    try {
      if (state.turn > 1) {
        final newTurn = state.turn - 1;
        emit(state.copyWith(turn: newTurn));
        bleService.send(khoBleMapper.setTurn(newTurn));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement turn: $e');
    }
  }

  void updateMatchTime(String time) {
    try {
      emit(state.copyWith(matchTime: time));
      // Usually timer sync is handled by a timer cubit, but if it's just setting duration:
      final parts = time.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]);
        if (minutes != null) {
          bleService.send(khoBleMapper.setMatchTimerMinutes(minutes));
        }
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to update match time: $e');
    }
  }

  void toggleChasingTeam() {
    try {
      final newState = !state.isTeam1Chasing;
      emit(state.copyWith(isTeam1Chasing: newState));
      bleService.send(khoBleMapper.setChasingTeam(newState ? 1 : 2));
    } catch (e) {
      globalErrorCubit.showError('Failed to toggle chasing team: $e');
    }
  }

  void resetScreen() {
    try {
      emit(const KhokhoControllerState());
      bleService.send(khoBleMapper.resetScreen());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset screen: $e');
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
