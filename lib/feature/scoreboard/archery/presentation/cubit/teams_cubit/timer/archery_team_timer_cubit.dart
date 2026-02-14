import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

import 'archery_team_timer_state.dart';

class ArcheryTeamTimerCubit extends Cubit<ArcheryTeamTimerState> {
  Timer? _timer;
  bool _hasPrestarted = false;
  final BleService bleService;
  final ArcheryBleMapper bleMapper;
  final GlobalErrorCubit globalErrorCubit;

  ArcheryTeamTimerCubit({
    int initialSeconds = 120,
    int totalRounds = 1,
    ArcheryTeamSide initialSide = ArcheryTeamSide.left,
    int brightness = 100,
    required this.bleService,
    required this.bleMapper,
    required this.globalErrorCubit,
  }) : super(
         ArcheryTeamTimerState.initial(
           totalSeconds: initialSeconds,
           totalRounds: totalRounds,
           side: initialSide,
           brightness: brightness,
         ),
       );

  void setInitialSeconds(int seconds) {
    try {
      final updatedSeconds = seconds.clamp(0, 9999);
      _timer?.cancel();
      _hasPrestarted = false;
      bleService.send(bleMapper.setTeamMode());
      bleService.send(bleMapper.setTeamTimer(updatedSeconds));

      emit(
        state.copyWith(
          seconds: updatedSeconds,
          initialSeconds: updatedSeconds,
          leftRemainingSeconds: updatedSeconds,
          rightRemainingSeconds: updatedSeconds,
          status: ArcheryTeamTimerStatus.initial,
          phase: ArcheryTeamTimerPhase.main,
          isComplete: false,
        ),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to set team timer: $e');
    }
  }

  void setTotalRounds(int rounds) {
    try {
      final updatedRounds = rounds.clamp(1, 999);
      bleService.send(bleMapper.setNumberOfSets(1));
      emit(
        state.copyWith(
          totalRounds: updatedRounds,
          currentRound: 1,
          isComplete: false,
        ),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to set rounds: $e');
    }
  }

  void setStartSide(ArcheryTeamSide side) {
    try {
      side == ArcheryTeamSide.left
          ? bleService.send(bleMapper.arrowLeft())
          : bleService.send(bleMapper.arrowRight());
      emit(
        state.copyWith(
          startSide: side,
          activeSide: side,
          currentRound: 1,
          isComplete: false,
        ),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to set start side: $e');
    }
  }

  void setActiveSide(ArcheryTeamSide side) {
    emit(state.copyWith(activeSide: side));
  }

  void switchSide(ArcheryTeamSide side, {bool autoStart = false}) {
    try {
      final wasRunning = state.status == ArcheryTeamTimerStatus.running;
      final wasPaused = state.status == ArcheryTeamTimerStatus.paused;
      _timer?.cancel();

      bleService.send(bleMapper.switchSide());

      var leftRemaining = state.leftRemainingSeconds;
      var rightRemaining = state.rightRemainingSeconds;
      if (state.phase == ArcheryTeamTimerPhase.main) {
        if (state.activeSide == ArcheryTeamSide.left) {
          leftRemaining = (state.seconds - 1).clamp(0, 9999);
        } else {
          rightRemaining = (state.seconds - 1).clamp(0, 9999);
        }
      }

      final shouldIncrement =
          side == state.startSide && state.activeSide != state.startSide;
      final nextRound = shouldIncrement
          ? (state.currentRound + 1)
          : state.currentRound;
      final isComplete = nextRound > state.totalRounds;

      if (isComplete) {
        bleService.send(bleMapper.endGame());
        emit(
          state.copyWith(
            status: ArcheryTeamTimerStatus.finished,
            seconds: 0,
            isComplete: true,
            leftRemainingSeconds: leftRemaining,
            rightRemainingSeconds: rightRemaining,
          ),
        );
        return;
      }

      final nextSeconds = side == ArcheryTeamSide.left
          ? leftRemaining
          : rightRemaining;
      bleService.send(bleMapper.setNumberOfSets(nextRound));

      emit(
        state.copyWith(
          activeSide: side,
          seconds: nextSeconds,
          leftRemainingSeconds: leftRemaining,
          rightRemainingSeconds: rightRemaining,
          currentRound: nextRound,
          status: wasRunning
              ? ArcheryTeamTimerStatus.running
              : wasPaused
              ? ArcheryTeamTimerStatus.paused
              : ArcheryTeamTimerStatus.initial,
          phase: ArcheryTeamTimerPhase.main,
          isComplete: false,
        ),
      );

      if (wasRunning) {
        _startTicker();
        return;
      }

      if (autoStart) {
        start();
      }
    } catch (e) {
      globalErrorCubit.showError('Failed to switch side: $e');
    }
  }

  void start() {
    try {
      bleService.send(bleMapper.startAlternateTimer());
      if (state.status == ArcheryTeamTimerStatus.running) return;
      if (state.status == ArcheryTeamTimerStatus.paused) {
        resume();
        return;
      }
      _timer?.cancel();
      if (!_hasPrestarted) {
        _hasPrestarted = true;
        emit(
          state.copyWith(
            status: ArcheryTeamTimerStatus.running,
            phase: ArcheryTeamTimerPhase.prestart,
            seconds: 10,
          ),
        );
        _startTicker();
        return;
      }

      final nextSeconds = state.activeSide == ArcheryTeamSide.left
          ? state.leftRemainingSeconds
          : state.rightRemainingSeconds;

      emit(
        state.copyWith(
          status: ArcheryTeamTimerStatus.running,
          phase: ArcheryTeamTimerPhase.main,
          seconds: nextSeconds,
        ),
      );
      _startTicker();
    } catch (e) {
      globalErrorCubit.showError('Failed to start timer: $e');
    }
  }

  void pause() {
    try {
      if (state.status != ArcheryTeamTimerStatus.running) return;
      _timer?.cancel();
      bleService.send(bleMapper.pauseAlternateTimer());
      emit(state.copyWith(status: ArcheryTeamTimerStatus.paused));
    } catch (e) {
      globalErrorCubit.showError('Failed to pause timer: $e');
    }
  }

  void resume() {
    try {
      if (state.status != ArcheryTeamTimerStatus.paused) return;
      emit(state.copyWith(status: ArcheryTeamTimerStatus.running));
      bleService.send(bleMapper.resumeAlternateTimer());
      _startTicker();
    } catch (e) {
      globalErrorCubit.showError('Failed to resume timer: $e');
    }
  }

  void reset() {
    try {
      _timer?.cancel();
      _hasPrestarted = false;
      emit(
        state.copyWith(
          seconds: state.initialSeconds,
          leftRemainingSeconds: state.initialSeconds,
          rightRemainingSeconds: state.initialSeconds,
          currentRound: 1,
          status: ArcheryTeamTimerStatus.initial,
          phase: ArcheryTeamTimerPhase.main,
          isComplete: false,
        ),
      );
    } catch (e) {
      globalErrorCubit.showError('Failed to reset timer: $e');
    }
  }

  void setTempBrightness(int value) {
    try {
      final clamped = value.clamp(0, 220);
      emit(state.copyWith(tempBrightness: clamped));
      bleService.send("BRIG${value.clamp(0, 220)}");
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

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }

      if (state.status != ArcheryTeamTimerStatus.running) return;
      if (state.phase == ArcheryTeamTimerPhase.prestart) {
        if (state.seconds <= 1) {
          final nextSeconds = state.activeSide == ArcheryTeamSide.left
              ? state.leftRemainingSeconds
              : state.rightRemainingSeconds;
          emit(
            state.copyWith(
              phase: ArcheryTeamTimerPhase.main,
              seconds: nextSeconds,
            ),
          );
        } else {
          emit(state.copyWith(seconds: state.seconds - 1));
        }
        return;
      }

      if (state.seconds <= 1) {
        timer.cancel();
        final leftRemaining = state.activeSide == ArcheryTeamSide.left
            ? 0
            : state.leftRemainingSeconds;
        final rightRemaining = state.activeSide == ArcheryTeamSide.right
            ? 0
            : state.rightRemainingSeconds;
        emit(
          state.copyWith(
            seconds: 0,
            leftRemainingSeconds: leftRemaining,
            rightRemainingSeconds: rightRemaining,
            status: ArcheryTeamTimerStatus.finished,
          ),
        );
      } else {
        final nextSeconds = state.seconds - 1;
        if (state.activeSide == ArcheryTeamSide.left) {
          emit(
            state.copyWith(
              seconds: nextSeconds,
              leftRemainingSeconds: nextSeconds,
            ),
          );
        } else {
          emit(
            state.copyWith(
              seconds: nextSeconds,
              rightRemainingSeconds: nextSeconds,
            ),
          );
        }
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
