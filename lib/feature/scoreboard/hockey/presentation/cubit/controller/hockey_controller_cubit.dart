import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/hockey_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/utility/universal_method.dart';
import 'hockey_controller_state.dart';

class HockeyControllerCubit extends Cubit<HockeyControllerState> {
  final BleService bleService;
  final HockeyBleMapper bleMapper;
  final GlobalErrorCubit globalErrorCubit;

  HockeyControllerCubit({
    required this.bleService,
    required this.bleMapper,
    required this.globalErrorCubit,
  }) : super(HockeyControllerState.initial());

  // ---------------- TEAM NAMES ----------------
  void setTeam1Name(String name) {
    try {
      emit(state.copyWith(team1Name: name));
      bleService.send(bleMapper.setTeam1Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 1 name: $e');
    }
  }

  void setTeam2Name(String name) {
    try {
      emit(state.copyWith(team2Name: name));
      bleService.send(bleMapper.setTeam2Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 2 name: $e');
    }
  }

  // ---------------- SCORES ----------------
  void incTeam1Score() {
    try {
      final newValue = state.team1Score + 1;
      emit(state.copyWith(team1Score: newValue));
      bleService.send(bleMapper.setTeam1Score(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 score: $e');
    }
  }

  void decTeam1Score() {
    try {
      if (state.team1Score > 0) {
        final newValue = state.team1Score - 1;
        emit(state.copyWith(team1Score: newValue));
        bleService.send(bleMapper.setTeam1Score(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 score: $e');
    }
  }

  void incTeam2Score() {
    try {
      final newValue = state.team2Score + 1;
      emit(state.copyWith(team2Score: newValue));
      bleService.send(bleMapper.setTeam2Score(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 score: $e');
    }
  }

  void decTeam2Score() {
    try {
      if (state.team2Score > 0) {
        final newValue = state.team2Score - 1;
        emit(state.copyWith(team2Score: newValue));
        bleService.send(bleMapper.setTeam2Score(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 score: $e');
    }
  }

  // ---------------- PENALTY CORNERS ----------------
  void incTeam1PenaltyCorner() {
    try {
      final newValue = state.team1PenaltyCorner + 1;
      emit(state.copyWith(team1PenaltyCorner: newValue));
      bleService.send(bleMapper.setTeam1PenaltyCorner(newValue));
    } catch (e) {
      globalErrorCubit.showError(
        'Failed to increment team 1 penalty corner: $e',
      );
    }
  }

  void decTeam1PenaltyCorner() {
    try {
      if (state.team1PenaltyCorner > 0) {
        final newValue = state.team1PenaltyCorner - 1;
        emit(state.copyWith(team1PenaltyCorner: newValue));
        bleService.send(bleMapper.setTeam1PenaltyCorner(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError(
        'Failed to decrement team 1 penalty corner: $e',
      );
    }
  }

  void incTeam2PenaltyCorner() {
    try {
      final newValue = state.team2PenaltyCorner + 1;
      emit(state.copyWith(team2PenaltyCorner: newValue));
      bleService.send(bleMapper.setTeam2PenaltyCorner(newValue));
    } catch (e) {
      globalErrorCubit.showError(
        'Failed to increment team 2 penalty corner: $e',
      );
    }
  }

  void decTeam2PenaltyCorner() {
    try {
      if (state.team2PenaltyCorner > 0) {
        final newValue = state.team2PenaltyCorner - 1;
        emit(state.copyWith(team2PenaltyCorner: newValue));
        bleService.send(bleMapper.setTeam2PenaltyCorner(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError(
        'Failed to decrement team 2 penalty corner: $e',
      );
    }
  }

  // ---------------- Brightness ----------------
  void setBrightness(int value) {
    try {
      final clampedValue = value.clamp(0, 220);
      emit(state.copyWith(brightness: clampedValue));
      // bleService.send(bleMapper.setBrightness(clampedValue));
      bleService.send("BRIG${value.clamp(0, 220)}");
    } catch (e) {
      globalErrorCubit.showError('Failed to set brightness: $e');
    }
  }

  void setTempBrightness(int value) {
    try {
      emit(state.copyWith(tempbrightness: value.clamp(0, 220)));
    } catch (e) {
      globalErrorCubit.showError('Failed to set temp brightness: $e');
    }
  }

  // ---------------- Buzzer ----------------
  void toggleBuzzer() {
    try {
      emit(state.copyWith(buzzerOn: !state.buzzerOn));
      //bleService.send(bleMapper.setBuzzer(!state.buzzerOn));
    } catch (e) {
      globalErrorCubit.showError('Failed to toggle buzzer: $e');
    }
  }

  // ---------------- SHOOTOUTS ----------------
  void incTeam1Shootout() {
    try {
      final newValue = state.team1Shootout + 1;
      emit(state.copyWith(team1Shootout: newValue));
      bleService.send(bleMapper.setTeam1ShootOut(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 shootout: $e');
    }
  }

  void decTeam1Shootout() {
    try {
      if (state.team1Shootout > 0) {
        final newValue = state.team1Shootout - 1;
        emit(state.copyWith(team1Shootout: newValue));
        bleService.send(bleMapper.setTeam1ShootOut(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 shootout: $e');
    }
  }

  void incTeam2Shootout() {
    try {
      final newValue = state.team2Shootout + 1;
      emit(state.copyWith(team2Shootout: newValue));
      bleService.send(bleMapper.setTeam2ShootOut(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 shootout: $e');
    }
  }

  void decTeam2Shootout() {
    try {
      if (state.team2Shootout > 0) {
        final newValue = state.team2Shootout - 1;
        emit(state.copyWith(team2Shootout: newValue));
        bleService.send(bleMapper.setTeam2ShootOut(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 shootout: $e');
    }
  }

  void exit() {
    try {
      emit(HockeyControllerState.initial());
      bleService.send(bleMapper.resetScreen());
    } catch (e) {
      globalErrorCubit.showError('Failed to exit: $e');
    }
  }

  // ------- Color ----------
  void setTeam1Color(Color color) {
    try {
      emit(state.copyWith(team1Color: color));
      bleService.send(bleMapper.setTeam1NameColor(toRgb565(color).toRadixString(16).padLeft(4, '0').toUpperCase()));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 1 color: $e');
    }
  }

  void setTeam2Color(Color color) {
    try {
      emit(state.copyWith(team2Color: color));
      bleService.send(bleMapper.setTeam2NameColor(toRgb565(color).toRadixString(16).padLeft(4, '0').toUpperCase()));
   
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 2 color: $e');
    }
  }

  // ---------------- RESET ----------------
  void reset() {
    try {
      emit(HockeyControllerState.initial());
      bleService.send(bleMapper.resetScreen());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset: $e');
    }
  }
}
