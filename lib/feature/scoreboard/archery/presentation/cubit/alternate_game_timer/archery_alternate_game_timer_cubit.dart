import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

import '../alternate_game_controller/archery_alternate_game_controller_state.dart';
import 'archery_alternate_game_timer_state.dart';

class ArcheryAlternateGameTimerCubit
    extends Cubit<ArcheryAlternateGameTimerState> {
  Timer? _timer;
  bool _hasPrestarted = false;
  final ArcheryBleMapper bleMapper;
  final GlobalErrorCubit globalErrorCubit;
  final BleService bleService;

  ArcheryAlternateGameTimerCubit({
    int initialSeconds = 60,
    required this.bleMapper,
    required this.globalErrorCubit,
    required this.bleService,
  }) : super(ArcheryAlternateGameTimerState.initial(initialSeconds));

  void setTime(int seconds, ArcheryGameMode mode) {
    _timer?.cancel();
    _hasPrestarted = false;
    final updatedSeconds = seconds.clamp(0, 9999);
    if (mode == ArcheryGameMode.alternatingFinals) {
      bleService.send(bleMapper.setTeamTimer(updatedSeconds));
    } else {
      bleService.send(bleMapper.setTimerIndividuals(updatedSeconds));
    }
    emit(
      state.copyWith(
        seconds: updatedSeconds,
        initialSeconds: updatedSeconds,
        leftRemainingSeconds: updatedSeconds,
        rightRemainingSeconds: updatedSeconds,
        status: AlternateTimerStatus.initial,
        phase: AlternateTimerPhase.main,
      ),
    );
  }

  void setGameMode(ArcheryGameMode mode) {
    emit(
      state.copyWith(
        gameMode: mode,
        leftRemainingSeconds: state.initialSeconds,
        rightRemainingSeconds: state.initialSeconds,
        seconds: state.initialSeconds,
      ),
    );
  }

  void setActiveSide(ArcheryAlternateSide side) {
    emit(state.copyWith(activeSide: side));
  }

  void resetForSimpleSideChange() {
    if (state.gameMode != ArcheryGameMode.simple) return;
    emit(
      state.copyWith(
        seconds: state.initialSeconds,
        leftRemainingSeconds: state.initialSeconds,
        rightRemainingSeconds: state.initialSeconds,
        phase: AlternateTimerPhase.main,
      ),
    );
  }

  void switchSide(ArcheryAlternateSide nextSide) {
    if (state.gameMode != ArcheryGameMode.alternatingFinals) {
      bleService.send(bleMapper.switchSide());
      emit(state.copyWith(activeSide: nextSide));
      return;
    }

    var leftRemaining = state.leftRemainingSeconds;
    var rightRemaining = state.rightRemainingSeconds;
    if (state.phase == AlternateTimerPhase.main) {
      if (state.activeSide == ArcheryAlternateSide.left) {
        leftRemaining = state.seconds;
      } else {
        rightRemaining = state.seconds;
      }
    }

    final nextSeconds = nextSide == ArcheryAlternateSide.left
        ? leftRemaining
        : rightRemaining;

    bleService.send(bleMapper.switchSide());
    emit(
      state.copyWith(
        activeSide: nextSide,
        seconds: nextSeconds,
        leftRemainingSeconds: leftRemaining,
        rightRemainingSeconds: rightRemaining,
      ),
    );
  }

  void start() {
    if (state.status == AlternateTimerStatus.running) return;
    _timer?.cancel();
    if (!_hasPrestarted) {
      _hasPrestarted = true;
      emit(
        state.copyWith(
          status: AlternateTimerStatus.running,
          phase: AlternateTimerPhase.prestart,
          seconds: 10,
        ),
      );
      bleService.send(bleMapper.startAlternateTimer());
      _startTicker();
      return;
    }

    emit(
      state.copyWith(
        status: AlternateTimerStatus.running,
        phase: AlternateTimerPhase.main,
        seconds: state.gameMode == ArcheryGameMode.alternatingFinals
            ? state.activeSide == ArcheryAlternateSide.left
                  ? state.leftRemainingSeconds
                  : state.rightRemainingSeconds
            : state.initialSeconds,
      ),
    );
    _startTicker();
  }

  void pause() {
    if (state.status != AlternateTimerStatus.running) return;
    _timer?.cancel();
    bleService.send(bleMapper.pauseAlternateTimer());
    emit(state.copyWith(status: AlternateTimerStatus.paused));
  }

  void resume() {
    if (state.status != AlternateTimerStatus.paused) return;
    bleService.send(bleMapper.resumeAlternateTimer());
    emit(state.copyWith(status: AlternateTimerStatus.running));
    _startTicker();
  }

  void stop() {
    if (state.status == AlternateTimerStatus.initial) return;
    _timer?.cancel();
    emit(
      state.copyWith(
        status: AlternateTimerStatus.initial,
        seconds: state.initialSeconds,
        leftRemainingSeconds: state.initialSeconds,
        rightRemainingSeconds: state.initialSeconds,
        phase: AlternateTimerPhase.main,
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

      if (state.status != AlternateTimerStatus.running) return;

      if (state.phase == AlternateTimerPhase.prestart) {
        if (state.seconds <= 0) {
          final nextSeconds =
              state.gameMode == ArcheryGameMode.alternatingFinals
              ? state.activeSide == ArcheryAlternateSide.left
                    ? state.leftRemainingSeconds
                    : state.rightRemainingSeconds
              : state.initialSeconds;
          emit(
            state.copyWith(
              phase: AlternateTimerPhase.main,
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
        emit(state.copyWith(seconds: 0, status: AlternateTimerStatus.finished));
        // bleService.send(bleMapper.stopTimer());
      } else {
        final nextSeconds = state.seconds - 1;
        if (state.gameMode == ArcheryGameMode.alternatingFinals) {
          emit(
            state.copyWith(
              seconds: nextSeconds,
              leftRemainingSeconds:
                  state.activeSide == ArcheryAlternateSide.left
                  ? nextSeconds
                  : state.leftRemainingSeconds,
              rightRemainingSeconds:
                  state.activeSide == ArcheryAlternateSide.right
                  ? nextSeconds
                  : state.rightRemainingSeconds,
            ),
          );
        } else {
          emit(state.copyWith(seconds: nextSeconds));
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
