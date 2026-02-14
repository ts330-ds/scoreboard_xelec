import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

import 'ab_cd_timer_state.dart';

class Ab_CdTimerCubit extends Cubit<AbCdTimerState> {
  Timer? _timer;
  bool _hasPrestarted = false;
  final int _defaultInitialSeconds;
  final int _defaultSighterRounds;
  final int _defaultScoringRounds;
  final BleService bleService;
  final ArcheryBleMapper bleMapper;
  final GlobalErrorCubit globalErrorCubit;

  Ab_CdTimerCubit({
    int initialSeconds = 90,
    int sighterRounds = 0,
    int scoringRounds = 6,
    required this.bleService,
    required this.bleMapper,
    required this.globalErrorCubit,
  }) : _defaultInitialSeconds = initialSeconds,
       _defaultSighterRounds = sighterRounds,
       _defaultScoringRounds = scoringRounds,
       super(
         AbCdTimerState.initial(
           totalSeconds: initialSeconds,
           sighterRounds: sighterRounds,
           scoringRounds: scoringRounds,
         ),
       );

  void setInitialSeconds(int seconds) {
    final updated = seconds.clamp(1, 9999);
    _timer?.cancel();
    bleService.send(bleMapper.startMatch(updated));
    bleService.send(bleMapper.showFirstGroupShooting());
    emit(
      state.copyWith(
        seconds: updated,
        initialSeconds: updated,
        status: AbCdTimerStatus.initial,
        phase: AbCdTimerPhase.main,
        isComplete: false,
      ),
    );
  }

  void incrementSeconds() => setInitialSeconds(state.initialSeconds + 1);

  void decrementSeconds() =>
      setInitialSeconds((state.initialSeconds - 1).clamp(1, 9999));

  void setSighterRounds(int rounds) {
    final updated = rounds.clamp(0, 99);
    final roundPhase = updated > 0
        ? AbCdRoundPhase.sighter
        : AbCdRoundPhase.scoring;
    emit(
      state.copyWith(
        totalSighterRounds: updated,
        roundPhase: roundPhase,
        currentSighterRound: 1,
        currentScoringRound: 1,
        currentTeam: AbCdTeam.ab, // Reset to AB when changing config
        currentTurnInRound: 1,
        isComplete: false,
      ),
    );
  }

  void incrementSighterRounds() =>
      setSighterRounds(state.totalSighterRounds + 1);

  void decrementSighterRounds() =>
      setSighterRounds((state.totalSighterRounds - 1).clamp(0, 99));

  void setScoringRounds(int rounds) {
    final updated = rounds.clamp(1, 99);
    emit(
      state.copyWith(
        totalScoringRounds: updated,
        currentScoringRound: 1,
        isComplete: false,
      ),
    );
  }

  void incrementScoringRounds() =>
      setScoringRounds(state.totalScoringRounds + 1);

  void decrementScoringRounds() =>
      setScoringRounds((state.totalScoringRounds - 1).clamp(1, 99));

  void setCurrentSighterRound(int round) {
    if (state.totalSighterRounds <= 0) return;
    final updated = round.clamp(1, state.totalSighterRounds);
    emit(state.copyWith(currentSighterRound: updated));
    bleService.send(bleMapper.setEndInfo('SI END $updated'));
  }

  void incrementCurrentSighterRound() =>
      setCurrentSighterRound(state.currentSighterRound + 1);

  void decrementCurrentSighterRound() =>
      setCurrentSighterRound(state.currentSighterRound - 1);

  void setCurrentScoringRound(int round) {
    final updated = round.clamp(1, state.totalScoringRounds);
    emit(state.copyWith(currentScoringRound: updated));
    bleService.send(bleMapper.setEndInfo('SC END $updated'));
  }

  void incrementCurrentScoringRound() =>
      setCurrentScoringRound(state.currentScoringRound + 1);

  void decrementCurrentScoringRound() =>
      setCurrentScoringRound(state.currentScoringRound - 1);

  void setSelectedRoundPhase(AbCdRoundPhase phase) {
    if (state.roundPhase == phase) return;
    _timer?.cancel();
    emit(
      state.copyWith(
        roundPhase: phase,
        seconds: state.initialSeconds,
        status: AbCdTimerStatus.initial,
        phase: AbCdTimerPhase.main,
        isComplete: false,
      ),
    );
    if (phase == AbCdRoundPhase.sighter) {
      bleService.send(
        bleMapper.setEndInfo('SI END ${state.currentSighterRound}'),
      );
    } else {
      bleService.send(
        bleMapper.setEndInfo('SC END ${state.currentScoringRound}'),
      );
    }
  }

  void start() {
    if (state.status == AbCdTimerStatus.running) return;
    if (state.status == AbCdTimerStatus.paused) {
      resume();
      return;
    }
    _timer?.cancel();

    bleService.send(bleMapper.startAlternateTimer());

    // Send BLE command for current team
    _sendTeamBleCommand(state.currentTeam);

    if (!_hasPrestarted) {
      _hasPrestarted = true;
      emit(
        state.copyWith(
          status: AbCdTimerStatus.running,
          phase: AbCdTimerPhase.prestart,
          seconds: 10,
        ),
      );
      _startTicker();
      return;
    }

    emit(
      state.copyWith(
        status: AbCdTimerStatus.running,
        phase: AbCdTimerPhase.main,
        seconds: state.initialSeconds,
      ),
    );
    _startTicker();
  }

  void pause() {
    if (state.status != AbCdTimerStatus.running) return;
    _timer?.cancel();
    bleService.send(bleMapper.pauseAlternateTimer());
    emit(state.copyWith(status: AbCdTimerStatus.paused));
  }

  void resume() {
    if (state.status != AbCdTimerStatus.paused) return;
    bleService.send(bleMapper.resumeAlternateTimer());
    emit(state.copyWith(status: AbCdTimerStatus.running));
    _startTicker();
  }

  void reset() {
    _timer?.cancel();
    _hasPrestarted = false;
    bleService.send(bleMapper.startMatch(state.initialSeconds));
    emit(
      state.copyWith(
        seconds: state.initialSeconds,
        status: AbCdTimerStatus.initial,
        phase: AbCdTimerPhase.main,
        isComplete: false,
      ),
    );
  }

  void resetAll() {
    _timer?.cancel();
    _hasPrestarted = false;
    emit(
      AbCdTimerState.initial(
        totalSeconds: _defaultInitialSeconds,
        sighterRounds: _defaultSighterRounds,
        scoringRounds: _defaultScoringRounds,
      ),
    );
  }

  void toggleTeam() {
    final newTeam = state.currentTeam == AbCdTeam.ab
        ? AbCdTeam.cd
        : AbCdTeam.ab;

    emit(
      state.copyWith(
        currentTeam: newTeam,
        status: AbCdTimerStatus.initial,
        seconds: state.initialSeconds,
        phase: AbCdTimerPhase.main,
      ),
    );

    // Send BLE command for new team
    _sendTeamBleCommand(newTeam);
  }

  void setTempBrightness(int value) {
    try {
      final clamped = value.clamp(0, 220);
      emit(state.copyWith(tempBrightness: clamped));
      bleService.send("BRIG$clamped");
    } catch (e) {
      globalErrorCubit.showError('Failed to set temp brightness: $e');
    }
  }

  void setBrightness(int value) {
    try {
      final clamped = value.clamp(0, 220);
      emit(state.copyWith(brightness: clamped, tempBrightness: clamped));
    } catch (e) {
      globalErrorCubit.showError('Failed to set brightness: $e');
    }
  }

  /// Send appropriate BLE command based on team
  void _sendTeamBleCommand(AbCdTeam team) {
    try {
      if (team == AbCdTeam.ab) {
        bleService.send(bleMapper.showFirstGroupShooting());
      } else {
        bleService.send(bleMapper.showSecondGroupShooting());
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to send team BLE command: $e');
    }
  }

  /// Called when timer completes for one team
  void _handleTimerComplete() {
    if (state.currentTurnInRound == 1) {
      // First team completed, switch to second team
      _switchToSecondTeam();
    } else {
      // Second team completed, round is complete
      _advanceRound();
    }
  }

  /// Switch to second team in the current round
  void _switchToSecondTeam() {
    final currentRound = state.currentRoundNumber;
    final secondTeam = state.getSecondTeamForRound(currentRound);
    emit(
      state.copyWith(
        currentTurnInRound: 2,
        currentTeam: secondTeam,
        status: AbCdTimerStatus.initial,
        seconds: state.initialSeconds,
        phase: AbCdTimerPhase.main,
      ),
    );
    
    // Send BLE command for second team
    _sendTeamBleCommand(secondTeam);
  }

  /// Advance to next round after both teams complete
  void _advanceRound() {
    if (state.roundPhase == AbCdRoundPhase.sighter) {
      if (state.currentSighterRound >= state.totalSighterRounds) {
        // Sighter phase complete, move to scoring
        _transitionToScoring();
      } else {
        // Next sighter round
        _nextRound();
      }
    } else {
      if (state.currentScoringRound >= state.totalScoringRounds) {
        // Match complete
        _completeMatch();
      } else {
        // Next scoring round
        _nextRound();
      }
    }
  }

  void _nextRound() {
    final nextRoundNumber = state.currentRoundNumber + 1;
    final firstTeam = state.getFirstTeamForRound(nextRoundNumber);

    emit(
      state.copyWith(
        currentSighterRound: state.roundPhase == AbCdRoundPhase.sighter
            ? nextRoundNumber
            : state.currentSighterRound,
        currentScoringRound: state.roundPhase == AbCdRoundPhase.scoring
            ? nextRoundNumber
            : state.currentScoringRound,
        currentTeam: firstTeam,
        currentTurnInRound: 1,
        status: AbCdTimerStatus.initial,
        seconds: state.initialSeconds,
        phase: AbCdTimerPhase.main,
      ),
    );
  }

  void _transitionToScoring() {
    // Scoring round 1 always starts with AB
    final firstTeam = state.getFirstTeamForRound(1);

    emit(
      state.copyWith(
        roundPhase: AbCdRoundPhase.scoring,
        currentScoringRound: 1,
        currentTeam: firstTeam,
        currentTurnInRound: 1,
        status: AbCdTimerStatus.initial,
        seconds: state.initialSeconds,
        phase: AbCdTimerPhase.main,
      ),
    );
  }

  void _completeMatch() {
    emit(
      state.copyWith(
        status: AbCdTimerStatus.finished,
        seconds: 0,
        isComplete: true,
      ),
    );
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }

      if (state.status != AbCdTimerStatus.running) return;

      if (state.phase == AbCdTimerPhase.prestart) {
        if (state.seconds <= 0) {
          emit(
            state.copyWith(
              phase: AbCdTimerPhase.main,
              seconds: state.initialSeconds,
            ),
          );
        } else {
          emit(state.copyWith(seconds: state.seconds - 1));
        }
        return;
      }

      if (state.seconds <= 0) {
        timer.cancel();
        _handleTimerComplete();
      } else {
        emit(state.copyWith(seconds: state.seconds - 1));
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
