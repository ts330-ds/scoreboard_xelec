import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

import 'archery_individual_timer_state.dart';

class ArcheryIndividualTimerCubit extends Cubit<ArcheryIndividualTimerState> {
  Timer? _timer;
  bool _hasPrestarted = false;
  final BleService bleService;
  final ArcheryBleMapper bleMapper;
  final GlobalErrorCubit globalErrorCubit;

  ArcheryIndividualTimerCubit({
    int initialSeconds = 20,
    int totalRounds = 1,
    ArcheryIndividualSide initialSide = ArcheryIndividualSide.left,
    int brightness = 100,
    required this.bleService,
    required this.bleMapper,
    required this.globalErrorCubit,
  }) : super(
         ArcheryIndividualTimerState.initial(
           totalSeconds: initialSeconds,
           totalRounds: totalRounds,
           side: initialSide,
           brightness: brightness,
         ),
       );

  void setInitialSeconds(int seconds) {
    final updatedSeconds = seconds.clamp(0, 9999);
    _timer?.cancel();
    _hasPrestarted = false;
    bleService.send(bleMapper.setIndividualMode());
    bleService.send(bleMapper.setTimerIndividuals(updatedSeconds));
    emit(
      state.copyWith(
        seconds: updatedSeconds,
        initialSeconds: updatedSeconds,
        status: ArcheryIndividualTimerStatus.initial,
        phase: ArcheryIndividualTimerPhase.main,
        isComplete: false,
      ),
    );
  }

  void setTotalRounds(int rounds) {
    final updatedRounds = rounds.clamp(1, 999);
    bleService.send(bleMapper.setNumberOfSets(1));
    emit(
      state.copyWith(
        totalRounds: updatedRounds,
        currentRound: 1,
        isComplete: false,
      ),
    );
  }

  void setStartSide(ArcheryIndividualSide side) {
    side == ArcheryIndividualSide.left
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
  }

  void setActiveSide(ArcheryIndividualSide side) {
    emit(state.copyWith(activeSide: side));
  }

  void switchSide(ArcheryIndividualSide side, {bool autoStart = true}) {
    _timer?.cancel();
    bleService.send(bleMapper.switchSide());
    final shouldIncrement =
        side == state.startSide && state.activeSide != state.startSide;
    final nextRound = shouldIncrement
        ? (state.currentRound + 1)
        : state.currentRound;
    final isComplete = nextRound > state.totalRounds;

    if (isComplete) {
      _timer?.cancel();
      bleService.send(bleMapper.endGame());
      emit(
        state.copyWith(
          status: ArcheryIndividualTimerStatus.finished,
          seconds: 0,
          isComplete: true,
        ),
      );
      return;
    }
    bleService.send(bleMapper.setNumberOfSets(nextRound));
    emit(
      state.copyWith(
        activeSide: side,
        seconds: state.initialSeconds,
        currentRound: nextRound,
        status: ArcheryIndividualTimerStatus.initial,
        phase: ArcheryIndividualTimerPhase.main,
        isComplete: false,
      ),
    );

    if (autoStart) {
      start();
    }
  }

  void start() {
    bleService.send(bleMapper.startAlternateTimer());
    if (state.status == ArcheryIndividualTimerStatus.running) return;
    if (state.status == ArcheryIndividualTimerStatus.paused) {
      resume();
      return;
    }
    _timer?.cancel();
    if (!_hasPrestarted) {
      _hasPrestarted = true;
      emit(
        state.copyWith(
          status: ArcheryIndividualTimerStatus.running,
          phase: ArcheryIndividualTimerPhase.prestart,
          seconds: 10,
        ),
      );
      _startTicker();
      return;
    }

    emit(
      state.copyWith(
        status: ArcheryIndividualTimerStatus.running,
        phase: ArcheryIndividualTimerPhase.main,
        seconds: state.initialSeconds,
      ),
    );
    _startTicker();
  }

  void pause() {
    if (state.status != ArcheryIndividualTimerStatus.running) return;
    _timer?.cancel();
    bleService.send(bleMapper.pauseAlternateTimer());
    emit(state.copyWith(status: ArcheryIndividualTimerStatus.paused));
  }

  void resume() {
    if (state.status != ArcheryIndividualTimerStatus.paused) return;
    emit(state.copyWith(status: ArcheryIndividualTimerStatus.running));
    bleService.send(bleMapper.resumeAlternateTimer());
    _startTicker();
  }

  void reset() {
    _timer?.cancel();
    _hasPrestarted = false;
    emit(
      state.copyWith(
        seconds: state.initialSeconds,
        currentRound: 1,
        status: ArcheryIndividualTimerStatus.initial,
        phase: ArcheryIndividualTimerPhase.main,
        isComplete: false,
      ),
    );
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

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }

      if (state.status != ArcheryIndividualTimerStatus.running) return;

      if (state.phase == ArcheryIndividualTimerPhase.prestart) {
        if (state.seconds <= 1) {
          emit(
            state.copyWith(
              phase: ArcheryIndividualTimerPhase.main,
              seconds: state.initialSeconds,
            ),
          );
        } else {
          emit(state.copyWith(seconds: state.seconds - 1));
        }
        return;
      }

      if (state.seconds <= 1) {
        _handleAutoAdvance();
      } else {
        emit(state.copyWith(seconds: state.seconds - 1));
      }
    });
  }

  void _handleAutoAdvance() {
    if (state.isComplete) {
      _timer?.cancel();
      bleService.send(bleMapper.endGame()); 
      return;
    }

    final nextSide = state.activeSide == ArcheryIndividualSide.left
        ? ArcheryIndividualSide.right
        : ArcheryIndividualSide.left;
    final shouldIncrement = nextSide == state.startSide;
    final nextRound = shouldIncrement
        ? state.currentRound + 1
        : state.currentRound;

    if (nextRound > state.totalRounds) {
      _timer?.cancel();
bleService.send(bleMapper.endGame());
      emit(
        state.copyWith(
          seconds: 0,
          status: ArcheryIndividualTimerStatus.finished,
          isComplete: true,
        ),
      );
      return;
    }
    bleService.send(bleMapper.setNumberOfSets(nextRound));
    bleService.send(bleMapper.switchSide());
    _hasPrestarted = true;
    emit(
      state.copyWith(
        activeSide: nextSide,
        currentRound: nextRound,
        status: ArcheryIndividualTimerStatus.running,
        phase: ArcheryIndividualTimerPhase.main,
        seconds: state.initialSeconds,
        isComplete: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
