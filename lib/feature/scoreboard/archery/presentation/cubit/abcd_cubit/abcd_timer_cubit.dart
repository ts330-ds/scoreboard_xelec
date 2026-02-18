import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

import 'abcd_timer_state.dart';

class AbcdTimerCubit extends Cubit<AbcdTimerState> {
  Timer? _timer;
  bool _hasPrestarted = false;
  final int _defaultInitialSeconds;
  final int _defaultSighterRounds;
  final int _defaultScoringRounds;
  final BleService bleService;
  final ArcheryBleMapper bleMapper;
  final GlobalErrorCubit globalErrorCubit;

  AbcdTimerCubit({
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
         AbcdTimerState.initial(
           totalSeconds: initialSeconds,
           sighterRounds: sighterRounds,
           scoringRounds: scoringRounds,
         ),
       );

  void setInitialSeconds(int seconds) {
    final updated = seconds.clamp(1, 9999);
    _timer?.cancel();
    bleService.send(bleMapper.showArchersABCD());
    bleService.send(bleMapper.startMatch(updated));
    emit(
      state.copyWith(
        seconds: updated,
        initialSeconds: updated,
        status: AbcdTimerStatus.initial,
        phase: AbcdTimerPhase.main,
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
        ? AbcdRoundPhase.sighter
        : AbcdRoundPhase.scoring;
    final selectedRoundView = updated > 0
        ? AbcdRoundView.sighter
        : AbcdRoundView.scoring;
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
        state.roundPhase == AbcdRoundPhase.sighter &&
        state.currentSighterRound >= state.totalSighterRounds;

    emit(
      state.copyWith(
        totalScoringRounds: updated,
        currentSighterRound: shouldStartScoring ? state.currentSighterRound : 1,
        currentScoringRound: 1,
        roundPhase: shouldStartScoring
            ? AbcdRoundPhase.scoring
            : state.roundPhase,
        isComplete: false,
      ),
    );
  }

  void incrementScoringRounds() =>
      setScoringRounds(state.totalScoringRounds + 1);

  void decrementScoringRounds() =>
      setScoringRounds((state.totalScoringRounds - 1).clamp(1, 99));

  void setSelectedRoundView(AbcdRoundView view) {
    if (view == AbcdRoundView.sighter && state.totalSighterRounds <= 0) return;
    if (state.selectedRoundView == view) return;
    final nextRoundPhase = view == AbcdRoundView.sighter
        ? AbcdRoundPhase.sighter
        : AbcdRoundPhase.scoring;
    _timer?.cancel();
    emit(
      state.copyWith(
        selectedRoundView: view,
        roundPhase: nextRoundPhase,
        status: AbcdTimerStatus.initial,
        phase: AbcdTimerPhase.main,
        seconds: state.initialSeconds,
        isComplete: false,
      ),
    );
    if (view == AbcdRoundView.sighter) {
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
    _playBuzzerPattern(count: 3, intervalMs: 500);
    reset();
  }

  void incrementCurrentSighterRound() =>
      setCurrentSighterRound(state.currentSighterRound + 1);

  void decrementCurrentSighterRound() =>
      setCurrentSighterRound(state.currentSighterRound - 1);

  void setCurrentScoringRound(int round) {
    final updated = round.clamp(1, state.totalScoringRounds);
    emit(state.copyWith(currentScoringRound: updated));
    bleService.send(bleMapper.setEndInfo('SC END $updated'));
    _playBuzzerPattern(count: 3, intervalMs: 500);
    reset();
  }

  void incrementCurrentScoringRound() =>
      setCurrentScoringRound(state.currentScoringRound + 1);

  void decrementCurrentScoringRound() =>
      setCurrentScoringRound(state.currentScoringRound - 1);

  void start() {
    if (state.status == AbcdTimerStatus.running) return;
    if (state.status == AbcdTimerStatus.paused) {
      resume();
      return;
    }
    _timer?.cancel();
    bleService.send(bleMapper.startAlternateTimer());
    if (!_hasPrestarted) {
      _hasPrestarted = true;
      emit(
        state.copyWith(
          status: AbcdTimerStatus.running,
          phase: AbcdTimerPhase.prestart,
          seconds: 10,
        ),
      );
      _startTicker();
      return;
    }

    emit(
      state.copyWith(
        status: AbcdTimerStatus.running,
        phase: AbcdTimerPhase.main,
        seconds: state.initialSeconds,
      ),
    );
    _startTicker();
  }

  void pause() {
    if (state.status != AbcdTimerStatus.running) return;
    _timer?.cancel();
    bleService.send(bleMapper.pauseAlternateTimer());
    emit(state.copyWith(status: AbcdTimerStatus.paused));
  }

  void resume() {
    if (state.status != AbcdTimerStatus.paused) return;
    bleService.send(bleMapper.resumeAlternateTimer());
    emit(state.copyWith(status: AbcdTimerStatus.running));
    _startTicker();
  }

  void reset() {
    _timer?.cancel();
    _hasPrestarted = false;
    bleService.send(bleMapper.startMatch(state.initialSeconds));
    print("reeset button called");
    emit(
      state.copyWith(
        seconds: state.initialSeconds,
        status: AbcdTimerStatus.initial,
        phase: AbcdTimerPhase.main,
        isComplete: false,
      ),
    );
  }

  void resetAll() {
    _timer?.cancel();
    _hasPrestarted = false;
    emit(
      AbcdTimerState.initial(
        totalSeconds: _defaultInitialSeconds,
        sighterRounds: _defaultSighterRounds,
        scoringRounds: _defaultScoringRounds,
      ),
    );
  }

  void _playBuzzerPattern({int count = 3, int intervalMs = 500}) {
    for (var i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: intervalMs), () {
        try {
          bleService.send(bleMapper.triggerBuzzer());
        } catch (e) {
          globalErrorCubit.showError('Failed to trigger buzzer: $e');
        }
      });
    }
  }

  void triggerBuzzer() {
    _playBuzzerPattern();
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

  void endGame() {
    try {
      _timer?.cancel();
      emit(
        state.copyWith(
          status: AbcdTimerStatus.finished,
          seconds: 0,
          isComplete: true,
        ),
      );
      bleService.send(bleMapper.endGame());
    } catch (e) {
      globalErrorCubit.showError('Failed to end game: $e');
    }
  }

  void _advanceRound() {
    _playBuzzerPattern();

    if (state.roundPhase == AbcdRoundPhase.sighter) {
      // Round khatam -> timer, koi auto-round/phase change nahi
      emit(
        state.copyWith(
          status: AbcdTimerStatus.initial,
          seconds: state.initialSeconds,
          phase: AbcdTimerPhase.main,
        ),
      );
      return;
    }

    if (state.currentScoringRound > state.totalScoringRounds) {
      emit(
        state.copyWith(
          status: AbcdTimerStatus.finished,
          seconds: 0,
          isComplete: true,
        ),
      );
      bleService.send(bleMapper.endGame());
    } else {
      // Scoring round khatam, lekin ab bhi manual selection
      emit(
        state.copyWith(
          status: AbcdTimerStatus.initial,
          seconds: state.initialSeconds,
          phase: AbcdTimerPhase.main,
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

      if (state.status != AbcdTimerStatus.running) return;

      if (state.phase == AbcdTimerPhase.prestart) {
        if (state.seconds <= 1) {
          emit(
            state.copyWith(
              phase: AbcdTimerPhase.main,
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
        _playBuzzerPattern();
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
