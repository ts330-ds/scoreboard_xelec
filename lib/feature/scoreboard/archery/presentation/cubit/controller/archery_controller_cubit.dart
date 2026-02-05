
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';

part 'archery_controller_state.dart';

class ArcheryControllerCubit extends Cubit<ArcheryControllerState> {
  final BleService bleService;
  final ArcheryBleMapper archeryBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  ArcheryControllerCubit({
    required this.bleService,
    required this.archeryBleMapper,
    required this.globalErrorCubit,
  }) : super(const ArcheryControllerState());

  // ============ IDLE SCREEN ============

  void showIdleScreen() {
    try {
      emit(state.copyWith(isIdleScreen: true));
       bleService.send(archeryBleMapper.activateClockMode());
    } catch (e) {
      globalErrorCubit.showError('Failed to show idle screen: $e');
    }
  }

  void showGameScreen() {
    try {
      emit(state.copyWith(isIdleScreen: false));
      bleService.send("AR");
    } catch (e) {
      globalErrorCubit.showError('Failed to show game screen: $e');
    }
  }

  // ============ SETUP ============

  void setMode(ArcheryMode mode) {
    try {
      emit(state.copyWith(mode: mode));
      String modeString;
      if (mode == ArcheryMode.abcd) {
        modeString = 'ABCD';
        bleService.send(archeryBleMapper.showArchersABCD());
      } else if (mode == ArcheryMode.abc) {
        modeString = 'ABC';
        bleService.send(archeryBleMapper.showArchersABC());
      } else {
        modeString = 'AB-CD';
        bleService.send(archeryBleMapper.showFirstGroupShooting());
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to set mode: $e');
    }
  }

  void setPracticeEnds(int ends) {
    try {
      emit(state.copyWith(practiceEnds: ends));
      bleService.send(archeryBleMapper.setEndInfo("SIGHTER END $ends"));
    } catch (e) {
      globalErrorCubit.showError('Failed to set practice ends: $e');
    }
  }

  void setScoringEnds(int ends) {
    try {
      emit(state.copyWith(scoringEnds: ends));
      bleService.send(archeryBleMapper.setEndInfo("SCORING END $ends"));
    } catch (e) {
      globalErrorCubit.showError('Failed to set scoring ends: $e');
    }
  }

  void setGreenTime(int seconds) {
    try {
      emit(state.copyWith(greenTime: seconds));
      bleService.send(archeryBleMapper.startMatch(seconds)); 
    } catch (e) {
      globalErrorCubit.showError('Failed to set green time: $e');
    }
  }

  // ============ MATCH CONTROL ============

  void initializeMatch() {
    try {
      final initialPhase = state.practiceEnds > 0
          ? MatchPhase.sighter
          : MatchPhase.scoring;

      // Round 1 always starts with AB
      final firstTeam = _getFirstTeamForRound(1);

      emit(
        state.copyWith(
          matchPhase: initialPhase,
          currentEndNumber: 1,
          currentTeam: firstTeam,
          currentTurnInRound: 1,
          isMatchComplete: false,
          isPracticeSkipped: false,
          isIdleScreen: false,
        ),
      );

      // Send initial team for AB-CD mode
      if (state.mode == ArcheryMode.abCd) {
        _sendTeamBleCommand(firstTeam);
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to initialize match: $e');
    }
  }

  /// Called when a timer cycle completes (one team finishes their time)
  void onTimerCycleComplete() {
    try {
      if (state.mode == ArcheryMode.abCd) {
        _handleAbCdTimerComplete();
      } else {
        // For ABCD and ABC modes, one timer cycle = one round complete
        _handleRoundComplete();
      }
    } catch (e) {
      globalErrorCubit.showError('Failed on timer cycle complete: $e');
    }
  }

  /// Handle AB-CD mode: a round requires both AB and CD to complete
  /// Teams alternate who goes first each round:
  /// Round 1: AB -> CD
  /// Round 2: CD -> AB
  /// Round 3: AB -> CD
  /// ...
  void _handleAbCdTimerComplete() {
    try {
      if (state.currentTurnInRound == 1) {
        // First turn completed, now switch to second turn
        final secondTeam = _getSecondTeamForRound(state.currentEndNumber);
        emit(state.copyWith(
          currentTurnInRound: 2,
          currentTeam: secondTeam,
        ));
        _sendTeamBleCommand(secondTeam);
      } else {
        // Second turn completed, round is complete
        _handleRoundComplete();
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to handle AB-CD timer complete: $e');
    }
  }

  /// Get which team starts first for a given round
  /// Odd rounds (1, 3, 5...): AB starts first
  /// Even rounds (2, 4, 6...): CD starts first
  String _getFirstTeamForRound(int roundNumber) {
    return roundNumber.isOdd ? 'AB' : 'CD';
  }

  /// Get which team goes second for a given round
  String _getSecondTeamForRound(int roundNumber) {
    return roundNumber.isOdd ? 'CD' : 'AB';
  }

  /// Send appropriate BLE command based on team
  void _sendTeamBleCommand(String team) {
    try {
      if (team == 'AB') {
        bleService.send(archeryBleMapper.showFirstGroupShooting());
      } else {
        bleService.send(archeryBleMapper.showSecondGroupShooting());
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to send team BLE command: $e');
    }
  }

  /// Called when a full round is complete (both teams finished in AB-CD mode)
  void _handleRoundComplete() {
    try {
      if (state.matchPhase == MatchPhase.sighter) {
        _handlePracticeRoundComplete();
      } else if (state.matchPhase == MatchPhase.scoring) {
        _handleScoringRoundComplete();
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to handle round complete: $e');
    }
  }

  void _handlePracticeRoundComplete() {
    try {
      if (state.currentEndNumber >= state.practiceEnds) {
        // Practice complete, move to scoring
        _transitionToScoring();
      } else {
        // Next practice round
        _advanceToNextRound();
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to handle practice round complete: $e');
    }
  }

  void _handleScoringRoundComplete() {
    try {
      if (state.currentEndNumber >= state.scoringEnds) {
        // Match complete
        _completeMatch();
      } else {
        // Next scoring round
        _advanceToNextRound();
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to handle scoring round complete: $e');
    }
  }

  void _advanceToNextRound() {
    try {
      final nextRound = state.currentEndNumber + 1;

      if (state.mode == ArcheryMode.abCd) {
        // AB-CD mode: start new round with alternating first team
        final firstTeam = _getFirstTeamForRound(nextRound);
        emit(state.copyWith(
          currentEndNumber: nextRound,
          currentTeam: firstTeam,
          currentTurnInRound: 1,
        ));
        _sendTeamBleCommand(firstTeam);
      } else {
        // ABCD/ABC mode: just advance round
        emit(state.copyWith(currentEndNumber: nextRound));
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to advance to next round: $e');
    }
  }

  void _transitionToScoring() {
    try {
      // Scoring phase round 1 always starts with AB
      final firstTeam = _getFirstTeamForRound(1);

      emit(
        state.copyWith(
          matchPhase: MatchPhase.scoring,
          currentEndNumber: 1,
          currentTeam: firstTeam,
          currentTurnInRound: 1,
        ),
      );

      // Send team for AB-CD mode
      if (state.mode == ArcheryMode.abCd) {
        _sendTeamBleCommand(firstTeam);
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to transition to scoring: $e');
    }
  }

  void skipPractice() {
    try {
      emit(state.copyWith(isPracticeSkipped: true));
      _transitionToScoring();
    } catch (e) {
      globalErrorCubit.showError('Failed to skip practice: $e');
    }
  }

  void _completeMatch() {
    try {
      emit(
        state.copyWith(matchPhase: MatchPhase.completed, isMatchComplete: true),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to complete match: $e');
    }
  }

  // Legacy method - keeping for backward compatibility, redirects to new method
  void onEndComplete() {
    onTimerCycleComplete();
  }

  // ============ SETTINGS ============

  void setBrightness(int value) {
    try {
      final clampedValue = value.clamp(0, 220);
      emit(state.copyWith(brightness: clampedValue));
      bleService.send("BRIG$clampedValue");
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

  void resetScreen() {
    try {
      //bleService.send(archeryBleMapper.resetScreen());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset screen: $e');
    }
  }

  void resetMatch() {
    try {
      emit(const ArcheryControllerState());
       bleService.send(archeryBleMapper.resetMatch());
    } catch (e) {
      globalErrorCubit.showError('Failed to reset match: $e');
    }
  }
}
