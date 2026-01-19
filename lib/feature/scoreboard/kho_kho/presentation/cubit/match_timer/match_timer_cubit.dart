import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'match_timer_state.dart';

class MatchTimerCubit extends Cubit<MatchTimerState> {
  MatchTimerCubit() : super(const MatchTimerState(duration: 18)); // Initial match time 18 seconds as per design

  Timer? _timer;

  void startTimer() {
    if (state.status == MatchTimerStatus.initial) {
      _start();
    }
  }

  void resumeTimer() {
    if (state.status == MatchTimerStatus.paused) {
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    emit(state.copyWith(status: MatchTimerStatus.inProgress));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.duration > 0) {
        emit(state.copyWith(duration: state.duration - 1));
      } else {
        _timer?.cancel();
        emit(state.copyWith(status: MatchTimerStatus.paused));
      }
    });
  }

  void pauseTimer() {
    if (state.status == MatchTimerStatus.inProgress) {
      _timer?.cancel();
      emit(state.copyWith(status: MatchTimerStatus.paused));
    }
  }

  void stopTimer() {
    _timer?.cancel();
    emit(state.copyWith(status: MatchTimerStatus.paused));
  }

  void resetTimer(int duration) {
    _timer?.cancel();
    emit(MatchTimerState(duration: duration, status: MatchTimerStatus.initial));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
