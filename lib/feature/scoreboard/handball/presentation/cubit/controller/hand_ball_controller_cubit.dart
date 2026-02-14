import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/handball_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';

import 'hand_ball_controller_state.dart';

class HandBallControlCubit extends Cubit<HandballControlState> {
  final BleService bleService;
  final HandBallBleMapper ballBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  HandBallControlCubit({
    required this.bleService,
    required this.ballBleMapper,
    required this.globalErrorCubit,
  }) : super(HandballControlState.initial());

  /* ===== EXIT / RESET ===== */
  void exit() {
    try {
      emit(HandballControlState.initial());
      bleService.send(ballBleMapper.resetScreen());
    } catch (e) {
      globalErrorCubit.showError('Failed to exit: $e');
    }
  }

  /* ===== TEAM NAMES ===== */
  void setTeam1Name(String name) {
    try {
      emit(state.copyWith(team1Name: name));
      bleService.send(ballBleMapper.setTeam1Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 1 name: $e');
    }
  }

  void setTeam2Name(String name) {
    try {
      emit(state.copyWith(team2Name: name));
      bleService.send(ballBleMapper.setTeam2Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 2 name: $e');
    }
  }

  /* ===== SCORE ===== */
  void incTeam1Score() {
    try {
      final newScore = state.team1Score + 1;
      emit(state.copyWith(team1Score: newScore));
      bleService.send(ballBleMapper.setTeam1Score(newScore));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 score: $e');
    }
  }

  void decTeam1Score() {
    try {
      if (state.team1Score > 0) {
        final newScore = state.team1Score - 1;
        emit(state.copyWith(team1Score: newScore));
        bleService.send(ballBleMapper.setTeam1Score(newScore));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 score: $e');
    }
  }

  void incTeam2Score() {
    try {
      final newScore = state.team2Score + 1;
      emit(state.copyWith(team2Score: newScore));
      bleService.send(ballBleMapper.setTeam2Score(newScore));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 score: $e');
    }
  }

  void decTeam2Score() {
    try {
      if (state.team2Score > 0) {
        final newScore = state.team2Score - 1;
        emit(state.copyWith(team2Score: newScore));
        bleService.send(ballBleMapper.setTeam2Score(newScore));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 score: $e');
    }
  }

  /* ===== TIMEOUT (1-3) ===== */
  void incrementTeam1Timeout() {
    try {
      if (state.team1Timeout >= 3) return;
      final newTimeout = state.team1Timeout + 1;
      emit(state.copyWith(team1Timeout: newTimeout));
      bleService.send(ballBleMapper.setTeam1Timeout(newTimeout));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 timeout: $e');
    }
  }

  void decrementTeam1Timeout() {
    try {
      if (state.team1Timeout <= 0) return;
      final newTimeout = state.team1Timeout - 1;
      emit(state.copyWith(team1Timeout: newTimeout));
      bleService.send(ballBleMapper.setTeam1Timeout(newTimeout));
      print(  'Decremented Team 1 Timeout to $newTimeout and sent BLE command');
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 timeout: $e');
    }
  }

  void incrementTeam2Timeout() {
    try {
      if (state.team2Timeout >= 3) return;
      final newTimeout = state.team2Timeout + 1;
      emit(state.copyWith(team2Timeout: newTimeout));
      bleService.send(ballBleMapper.setTeam2Timeout(newTimeout));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 timeout: $e');
    }
  }

  void decrementTeam2Timeout() {
    try {
      if (state.team2Timeout <= 0) return;
      final newTimeout = state.team2Timeout - 1;
      emit(state.copyWith(team2Timeout: newTimeout));
      bleService.send(ballBleMapper.setTeam2Timeout(newTimeout));
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 timeout: $e');
    }
  }

  /* ===== 7 METER ===== */
  void incTeam1_7m() {
    try {
      final newValue = state.team1_7m + 1;
      emit(state.copyWith(team1_7m: newValue));
      bleService.send(ballBleMapper.setTeam1SevenMeter(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 7m: $e');
    }
  }

  void decTeam1_7m() {
    try {
      if (state.team1_7m <= 0) return;
      final newValue = state.team1_7m - 1;
      emit(state.copyWith(team1_7m: newValue));
      bleService.send(ballBleMapper.setTeam1SevenMeter(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 7m: $e');
    }
  }

  void incTeam2_7m() {
    try {
      final newValue = state.team2_7m + 1;
      emit(state.copyWith(team2_7m: newValue));
      bleService.send(ballBleMapper.setTeam2SevenMeter(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 7m: $e');
    }
  }

  void decTeam2_7m() {
    try {
      if (state.team2_7m <= 0) return;
      final newValue = state.team2_7m - 1;
      emit(state.copyWith(team2_7m: newValue));
      bleService.send(ballBleMapper.setTeam2SevenMeter(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 7m: $e');
    }
  }

  /* ===== SUSPENSION TOGGLE (1 = Red, 2 = Green) ===== */
  void toggleTeam1Suspension() {
    try {
      final newState = !state.team1Suspension;
      emit(state.copyWith(team1Suspension: newState));
      bleService.send(ballBleMapper.setTeam1Suspension(newState ? 1 : 2));
    } catch (e) {
      globalErrorCubit.showError('Failed to toggle team 1 suspension: $e');
    }
  }

  void toggleTeam2Suspension() {
    try {
      final newState = !state.team2Suspension;
      emit(state.copyWith(team2Suspension: newState));
      bleService.send(ballBleMapper.setTeam2Suspension(newState ? 1 : 2));
    } catch (e) {
      globalErrorCubit.showError('Failed to toggle team 2 suspension: $e');
    }
  }

  /* ===== QUARTER / HALF ===== */
  void setQuarter(int quarter) {
    try {
      // Map MatchHalf to quarter for state
      MatchHalf half;
      switch (quarter) {
        case 1:
        case 2:
          half = MatchHalf.first;
          break;
        case 3:
        case 4:
          half = MatchHalf.second;
          break;
        default:
          half = MatchHalf.extra;
      }
      emit(state.copyWith(matchHalf: half));
      bleService.send(ballBleMapper.setQuarter(quarter));
    } catch (e) {
      globalErrorCubit.showError('Failed to set quarter: $e');
    }
  }

  void setHalf(MatchHalf half) {
    try {
      emit(state.copyWith(matchHalf: half));
      // Map MatchHalf to quarter for BLE
      int quarter;
      switch (half) {
        case MatchHalf.first:
          quarter = 1;
          break;
        case MatchHalf.second:
          quarter = 2;
          break;
        case MatchHalf.extra:
          quarter = 3;
          break;
      }
      bleService.send(ballBleMapper.setQuarter(quarter));
    } catch (e) {
      globalErrorCubit.showError('Failed to set half: $e');
    }
  }

  /* ===== COLOR ===== */
  void updateTeam1Color(Color color) {
    try {
      emit(state.copyWith(team1Color: color));
      // Note: No BLE command for color in Handball firmware
    } catch (e) {
      globalErrorCubit.showError('Failed to update team 1 color: $e');
    }
  }

  void updateTeam2Color(Color color) {
    try {
      emit(state.copyWith(team2Color: color));
      // Note: No BLE command for color in Handball firmware
    } catch (e) {
      globalErrorCubit.showError('Failed to update team 2 color: $e');
    }
  }

  /* ===== BRIGHTNESS ===== */
  void setBrightness(int value) {
    try {
      emit(state.copyWith(brightness: value.clamp(0, 220)));
      // Note: Brightness NOT supported in Handball firmware
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

  /* ===== BUZZER ===== */
  void toggleBuzzer() {
    try {
      emit(state.copyWith(buzzerOn: !state.buzzerOn));
      // Note: Buzzer NOT supported in Handball firmware
    } catch (e) {
      globalErrorCubit.showError('Failed to toggle buzzer: $e');
    }
  }

  /* ===== SYNC ALL TO BLE ===== */
  void syncAllToBle() {
    try {
      bleService.send(ballBleMapper.setTeam1Name(state.team1Name));
      bleService.send(ballBleMapper.setTeam2Name(state.team2Name));
      bleService.send(ballBleMapper.setTeam1Score(state.team1Score));
      bleService.send(ballBleMapper.setTeam2Score(state.team2Score));
      bleService.send(ballBleMapper.setTeam1Timeout(state.team1Timeout));
      bleService.send(ballBleMapper.setTeam2Timeout(state.team2Timeout));
      bleService.send(ballBleMapper.setTeam1SevenMeter(state.team1_7m));
      bleService.send(ballBleMapper.setTeam2SevenMeter(state.team2_7m));
      bleService.send(
        ballBleMapper.setTeam1Suspension(state.team1Suspension ? 1 : 2),
      );
      bleService.send(
        ballBleMapper.setTeam2Suspension(state.team2Suspension ? 1 : 2),
      );

      // Sync quarter based on match half
      int quarter = state.matchHalf == MatchHalf.first
          ? 1
          : (state.matchHalf == MatchHalf.second ? 2 : 3);
      bleService.send(ballBleMapper.setQuarter(quarter));
    } catch (e) {
      globalErrorCubit.showError('Failed to sync all to BLE: $e');
    }
  }

  /* ===== RESET MATCH ===== */
  void resetMatch() {
    try {
      emit(HandballControlState.initial());
      bleService.send(ballBleMapper.resetScreen());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset match: $e');
    }
  }
}
