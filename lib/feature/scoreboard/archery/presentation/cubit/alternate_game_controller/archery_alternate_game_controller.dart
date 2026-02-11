import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'archery_alternate_game_controller_state.dart';

class ArcheryAlternateGameControllerCubit
    extends Cubit<ArcheryAlternateGameControllerState> {
  final BleService bleService;
  GlobalErrorCubit globalErrorCubit;
  final ArcheryBleMapper bleMapper;

  ArcheryAlternateGameControllerCubit({
    required this.bleService,
    required this.globalErrorCubit,
    required this.bleMapper,
  }) : super(ArcheryAlternateGameControllerState.initial());

  void selectLeft() {
    try {
      emit(state.copyWith(activeSide: ArcheryAlternateSide.left));
    } catch (e) {
      globalErrorCubit.showError('Failed to select left side: $e');
    }
  }

  void selectRight() {
    try {
      emit(state.copyWith(activeSide: ArcheryAlternateSide.right));
    } catch (e) {
      globalErrorCubit.showError('Failed to select right side: $e');
    }
  }

  void setActiveSide(ArcheryAlternateSide side) {
    try {
      emit(state.copyWith(activeSide: side));
    } catch (e) {
      globalErrorCubit.showError('Failed to set active side: $e');
    }
  }

  void registerLeftWin() {
    try {
      if (state.isComplete) return;
      final nextSide = ArcheryAlternateSide.left;
      _applyRoundResult(
        state.copyWith(activeSide: nextSide, leftWonInRound: true),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to register left win: $e');
    }
  }

  void registerRightWin() {
    try {
      if (state.isComplete) return;
      final nextSide = ArcheryAlternateSide.right;
      _applyRoundResult(
        state.copyWith(activeSide: nextSide, rightWonInRound: true),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to register right win: $e');
    }
  }

  void setTotalRounds(int rounds, ArcheryGameMode mode) {
    try {
      // if (mode == ArcheryGameMode.alternatingFinals) {
      //   bleService.send(bleMapper.setSelection(rounds));
      // } else {
      //   bleService.send(bleMapper.setNumberOfSets(rounds));
      // }
      emit(
        state.copyWith(
          totalRounds: rounds,
          currentRound: 1,
          leftWonInRound: false,
          rightWonInRound: false,
          isComplete: false,
        ),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to set total rounds: $e');
    }
  }

  void setGameMode(ArcheryGameMode mode) {
    try {
      if (mode == ArcheryGameMode.alternatingFinals) {
        bleService.send(bleMapper.setTeamMode());
        emit(state.copyWith(gameMode: mode));
      } else {
        bleService.send(bleMapper.setIndividualMode());
        emit(state.copyWith(gameMode: mode));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to set game mode: $e');
    }
  }

  void _applyRoundResult(ArcheryAlternateGameControllerState nextState) {
    try {
      if (nextState.leftWonInRound && nextState.rightWonInRound) {
        final nextRound = nextState.currentRound + 1;
        final completed = nextRound > nextState.totalRounds;
        final displayRound = completed ? nextState.totalRounds : nextRound;
        bleService.send(bleMapper.setNumberOfSets(displayRound));
        emit(
          nextState.copyWith(
            currentRound: completed ? nextState.totalRounds : nextRound,
            leftWonInRound: false,
            rightWonInRound: false,
            isComplete: completed,
          ),
        );
        return;
      }

      emit(nextState);
    } catch (e) {
      globalErrorCubit.showError('Failed to apply round result: $e');
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
      emit(state.copyWith(setTempBrightness: value.clamp(0, 220)));
    } catch (e) {
      globalErrorCubit.showError('Failed to set temp brightness: $e');
    }
  }
}
