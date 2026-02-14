import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

import 'abc_timer_state.dart';

class AbcTimerCubit extends Cubit<AbcTimerState> {
  Timer? _timer;
  bool _hasPrestarted = false;
  final int _defaultInitialSeconds;
  final int _defaultSighterRounds;
  final int _defaultScoringRounds;
  final BleService bleService;
  final ArcheryBleMapper bleMapper;
  final GlobalErrorCubit globalErrorCubit;

  AbcTimerCubit({
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
         AbcTimerState.initial(
           totalSeconds: initialSeconds,
           sighterRounds: sighterRounds,
           scoringRounds: scoringRounds,
         ),
       );

  void setInitialSeconds(int seconds) {
    final updated = seconds.clamp(1, 9999);
    _timer?.cancel();
    bleService.send(bleMapper.showArchersABC());
    bleService.send(bleMapper.startMatch(updated));
    emit(
      state.copyWith(
        seconds: updated,
        initialSeconds: updated,
        status: AbcTimerStatus.initial,
        phase: AbcTimerPhase.main,
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
        ? AbcRoundPhase.sighter
        : AbcRoundPhase.scoring;
    final selectedRoundView = updated > 0
        ? AbcRoundView.sighter
        : AbcRoundView.scoring;
    emit(
      state.copyWith(
        totalSighterRounds: updated,
        roundPhase: roundPhase,
        selectedRoundView: selectedRoundView,
        currentSighterRound: 1,
        currentScoringRound: 1,
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
    final shouldStartScoring =
        state.roundPhase == AbcRoundPhase.sighter &&
        state.currentSighterRound >= state.totalSighterRounds;
    emit(
      state.copyWith(
        totalScoringRounds: updated,
        currentSighterRound: shouldStartScoring ? state.currentSighterRound : 1,
        currentScoringRound: 1,
        roundPhase: shouldStartScoring
            ? AbcRoundPhase.scoring
            : state.roundPhase,
        isComplete: false,
      ),
    );
  }

  void incrementScoringRounds() =>
      setScoringRounds(state.totalScoringRounds + 1);

  void decrementScoringRounds() =>
      setScoringRounds((state.totalScoringRounds - 1).clamp(1, 99));

  void setSelectedRoundView(AbcRoundView view) {
    if (view == AbcRoundView.sighter && state.totalSighterRounds <= 0) return;
    if (state.selectedRoundView == view) return;
    final nextRoundPhase = view == AbcRoundView.sighter
        ? AbcRoundPhase.sighter
        : AbcRoundPhase.scoring;
    _timer?.cancel();
    emit(
      state.copyWith(
        selectedRoundView: view,
        roundPhase: nextRoundPhase,
        status: AbcTimerStatus.initial,
        phase: AbcTimerPhase.main,
        seconds: state.initialSeconds,
        isComplete: false,
      ),
    );
    if (view == AbcRoundView.sighter) {
      bleService.send(
        bleMapper.setEndInfo('SI END ${state.currentSighterRound}'),
      );
    } else {
      bleService.send(
        bleMapper.setEndInfo('SC END ${state.currentScoringRound}'),
      );
    }
    reset();
  }

  void setCurrentSighterRound(int round) {
    if (state.totalSighterRounds <= 0) return;
    final updated = round.clamp(1, state.totalSighterRounds);
    emit(state.copyWith(currentSighterRound: updated));
    bleService.send(bleMapper.setEndInfo('SI END $updated'));
    reset();
  }

  void endGame() {
    try {
      _timer?.cancel();
      emit(
        state.copyWith(
          status: AbcTimerStatus.finished,
          seconds: 0,
          isComplete: true,
        ),
      );
      bleService.send(bleMapper.endGame());
    } catch (e) {
      globalErrorCubit.showError('Failed to end game: $e');
    }
  }

  void incrementCurrentSighterRound() =>
      setCurrentSighterRound(state.currentSighterRound + 1);

  void decrementCurrentSighterRound() =>
      setCurrentSighterRound(state.currentSighterRound - 1);

  void setCurrentScoringRound(int round) {
    final updated = round.clamp(1, state.totalScoringRounds);
    emit(state.copyWith(currentScoringRound: updated));
    bleService.send(bleMapper.setEndInfo('SC END $updated'));
    reset();
  }

  void incrementCurrentScoringRound() =>
      setCurrentScoringRound(state.currentScoringRound + 1);

  void decrementCurrentScoringRound() =>
      setCurrentScoringRound(state.currentScoringRound - 1);

  void start() {
    if (state.status == AbcTimerStatus.running) return;
    if (state.status == AbcTimerStatus.paused) {
      resume();
      return;
    }
    _timer?.cancel();
    bleService.send(bleMapper.startAlternateTimer());
    if (!_hasPrestarted) {
      _hasPrestarted = true;
      emit(
        state.copyWith(
          status: AbcTimerStatus.running,
          phase: AbcTimerPhase.prestart,
          seconds: 10,
        ),
      );
      _startTicker();
      return;
    }

    emit(
      state.copyWith(
        status: AbcTimerStatus.running,
        phase: AbcTimerPhase.main,
        seconds: state.initialSeconds,
      ),
    );
    _startTicker();
  }

  void pause() {
    if (state.status != AbcTimerStatus.running) return;
    _timer?.cancel();
    bleService.send(bleMapper.pauseAlternateTimer());
    emit(state.copyWith(status: AbcTimerStatus.paused));
  }

  void resume() {
    if (state.status != AbcTimerStatus.paused) return;
    bleService.send(bleMapper.resumeAlternateTimer());
    emit(state.copyWith(status: AbcTimerStatus.running));
    _startTicker();
  }

  void reset() {
    _timer?.cancel();
    _hasPrestarted = false;
    bleService.send(bleMapper.startMatch(state.initialSeconds));
    emit(
      state.copyWith(
        seconds: state.initialSeconds,
        status: AbcTimerStatus.initial,
        phase: AbcTimerPhase.main,
        isComplete: false,
      ),
    );
  }

  void resetAll() {
    _timer?.cancel();
    _hasPrestarted = false;
    emit(
      AbcTimerState.initial(
        totalSeconds: _defaultInitialSeconds,
        sighterRounds: _defaultSighterRounds,
        scoringRounds: _defaultScoringRounds,
      ),
    );
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

  void _advanceRound() {
    if (state.roundPhase == AbcRoundPhase.sighter) {
      if (state.currentSighterRound >= state.totalSighterRounds) {
        emit(
          state.copyWith(
            roundPhase: AbcRoundPhase.scoring,
            currentScoringRound: 1,
            status: AbcTimerStatus.initial,
            seconds: state.initialSeconds,
            phase: AbcTimerPhase.main,
          ),
        );
      } else {
        emit(
          state.copyWith(
            currentSighterRound: state.currentSighterRound + 1,
            status: AbcTimerStatus.initial,
            seconds: state.initialSeconds,
            phase: AbcTimerPhase.main,
          ),
        );
      }
      return;
    }

    if (state.currentScoringRound >= state.totalScoringRounds) {
      emit(
        state.copyWith(
          status: AbcTimerStatus.finished,
          seconds: 0,
          isComplete: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          currentScoringRound: state.currentScoringRound + 1,
          status: AbcTimerStatus.initial,
          seconds: state.initialSeconds,
          phase: AbcTimerPhase.main,
        ),
      );
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }

      if (state.status != AbcTimerStatus.running) return;

      if (state.phase == AbcTimerPhase.prestart) {
        if (state.seconds <= 1) {
          emit(
            state.copyWith(
              phase: AbcTimerPhase.main,
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
        // _advanceRound();
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
