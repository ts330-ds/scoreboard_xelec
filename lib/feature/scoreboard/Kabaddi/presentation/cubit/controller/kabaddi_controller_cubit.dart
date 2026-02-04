import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/kabaddi_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/utility/universal_method.dart';
import 'kabaddi_controller_state.dart';
import 'package:flutter/material.dart';

class KabaddiControllerCubit extends Cubit<KabaddiControllerState> {
  final BleService bleService;
  final KabaddiBleMapper kabaddiBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  KabaddiControllerCubit({
    required this.bleService,
    required this.kabaddiBleMapper,
    required this.globalErrorCubit,
  }) : super(KabaddiControllerState.initial());

  void setTeam1Name(String name) {
    try {
      emit(state.copyWith(team1Name: name));
      bleService.send(kabaddiBleMapper.setTeam1Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 1 name: $e');
    }
  }

  void setTeam2Name(String name) {
    try {
      emit(state.copyWith(team2Name: name));
      bleService.send(kabaddiBleMapper.setTeam2Name(name));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 2 name: $e');
    }
  }


  // Team colors
  void setTeam1Color(Color color) {
    try {
      emit(state.copyWith(team1Color: color));
   bleService.send(kabaddiBleMapper.setTeam1Color(toRgb565(color).toRadixString(16).padLeft(4, '0').toUpperCase()));
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 1 color: $e');
    }
  }

  void setTeam2Color(Color color) {
    try {
      emit(state.copyWith(team2Color: color));
      bleService.send(kabaddiBleMapper.setTeam2Color(toRgb565(color).toRadixString(16).padLeft(4, '0').toUpperCase()));
          
    } catch (e) {
      globalErrorCubit.showError('Failed to set team 2 color: $e');
    }
  }

  void incrementTeam1Score() {
    try {
      final newScore = state.team1Score + 1;
      emit(state.copyWith(team1Score: newScore));
      bleService.send(kabaddiBleMapper.setTeam1Score(newScore));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 score: $e');
    }
  }

  void decrementTeam1Score() {
    try {
      if (state.team1Score > 0) {
        final newScore = state.team1Score - 1;
        emit(state.copyWith(team1Score: newScore));
        bleService.send(kabaddiBleMapper.setTeam1Score(newScore));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 score: $e');
    }
  }

  void incrementTeam2Score() {
    try {
      final newScore = state.team2Score + 1;
      emit(state.copyWith(team2Score: newScore));
      bleService.send(kabaddiBleMapper.setTeam2Score(newScore));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 score: $e');
    }
  }

  void decrementTeam2Score() {
    try {
      if (state.team2Score > 0) {
        final newScore = state.team2Score - 1;
        emit(state.copyWith(team2Score: newScore));
        bleService.send(kabaddiBleMapper.setTeam2Score(newScore));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 score: $e');
    }
  }

  void incrementTeam1Touch() {
    try {
      final newValue = state.team1Touch + 1;
      emit(state.copyWith(team1Touch: newValue));
      bleService.send(kabaddiBleMapper.setTeam1Touch(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 touch: $e');
    }
  }

  void decrementTeam1Touch() {
    try {
      if (state.team1Touch > 0) {
        final newValue = state.team1Touch - 1;
        emit(state.copyWith(team1Touch: newValue));
        bleService.send(kabaddiBleMapper.setTeam1Touch(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 touch: $e');
    }
  }

  void incrementTeam2Touch() {
    try {
      final newValue = state.team2Touch + 1;
      emit(state.copyWith(team2Touch: newValue));
      bleService.send(kabaddiBleMapper.setTeam2Touch(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 touch: $e');
    }
  }

  void decrementTeam2Touch() {
    try {
      if (state.team2Touch > 0) {
        final newValue = state.team2Touch - 1;
        emit(state.copyWith(team2Touch: newValue));
        bleService.send(kabaddiBleMapper.setTeam2Touch(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 touch: $e');
    }
  }

  void incrementTeam1Bonus() {
    try {
      final newValue = state.team1Bonus + 1;
      emit(state.copyWith(team1Bonus: newValue));
      bleService.send(kabaddiBleMapper.setTeam1Bonus(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 bonus: $e');
    }
  }

  void decrementTeam1Bonus() {
    try {
      if (state.team1Bonus > 0) {
        final newValue = state.team1Bonus - 1;
        emit(state.copyWith(team1Bonus: newValue));
        bleService.send(kabaddiBleMapper.setTeam1Bonus(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 bonus: $e');
    }
  }

  void incrementTeam2Bonus() {
    try {
      final newValue = state.team2Bonus + 1;
      emit(state.copyWith(team2Bonus: newValue));
      bleService.send(kabaddiBleMapper.setTeam2Bonus(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 bonus: $e');
    }
  }

  void decrementTeam2Bonus() {
    try {
      if (state.team2Bonus > 0) {
        final newValue = state.team2Bonus - 1;
        emit(state.copyWith(team2Bonus: newValue));
        bleService.send(kabaddiBleMapper.setTeam2Bonus(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 bonus: $e');
    }
  }

  void incrementTeam1AllOut() {
    try {
      final newValue = state.team1AllOut + 1;
      emit(state.copyWith(team1AllOut: newValue));
      bleService.send(kabaddiBleMapper.setTeam1AllOut(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 1 all out: $e');
    }
  }

  void decrementTeam1AllOut() {
    try {
      if (state.team1AllOut > 0) {
        final newValue = state.team1AllOut - 1;
        emit(state.copyWith(team1AllOut: newValue));
        bleService.send(kabaddiBleMapper.setTeam1AllOut(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 1 all out: $e');
    }
  }

  void incrementTeam2AllOut() {
    try {
      final newValue = state.team2AllOut + 1;
      emit(state.copyWith(team2AllOut: newValue));
      bleService.send(kabaddiBleMapper.setTeam2AllOut(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment team 2 all out: $e');
    }
  }

  void decrementTeam2AllOut() {
    try {
      if (state.team2AllOut > 0) {
        final newValue = state.team2AllOut - 1;
        emit(state.copyWith(team2AllOut: newValue));
        bleService.send(kabaddiBleMapper.setTeam2AllOut(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement team 2 all out: $e');
    }
  }

  void incrementRaidNumber() {
    try {
      final newValue = state.raidNumber + 1;
      emit(state.copyWith(raidNumber: newValue));
      bleService.send(kabaddiBleMapper.setRaidNumber(newValue));
    } catch (e) {
      globalErrorCubit.showError('Failed to increment raid number: $e');
    }
  }

  void decrementRaidNumber() {
    try {
      if (state.raidNumber > 1) {
        final newValue = state.raidNumber - 1;
        emit(state.copyWith(raidNumber: newValue));
        bleService.send(kabaddiBleMapper.setRaidNumber(newValue));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to decrement raid number: $e');
    }
  }

  void setQuarter(int quarter) {
    try {
      emit(state.copyWith(currentQuarter: quarter));
      bleService.send(kabaddiBleMapper.setQuarter(quarter));
    } catch (e) {
      globalErrorCubit.showError('Failed to set quarter: $e');
    }
  }

  void toggleRaider() {
    try {
      final newValue = !state.isRaiderOnTeam1;
      emit(state.copyWith(isRaiderOnTeam1: newValue));
      if (newValue) {
        bleService.send(kabaddiBleMapper.showRaiderOnTeam1());
      } else {
        bleService.send(kabaddiBleMapper.showRaiderOnTeam2());
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to toggle raider: $e');
    }
  }

  void resetScreen() {
    try {
      bleService.send(kabaddiBleMapper.resetScreen());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset screen: $e');
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

}
