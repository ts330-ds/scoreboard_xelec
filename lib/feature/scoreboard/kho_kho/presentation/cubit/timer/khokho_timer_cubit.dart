import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'khokho_timer_state.dart';

class KhokhoTimerCubit extends Cubit<KhokhoTimerState> {
  KhokhoTimerCubit() : super(const KhokhoTimerState(duration: 540)); // 9 minutes = 540 seconds

  Timer? _timer;

  void startTimer() {
    if (state.status == KhokhoTimerStatus.initial) {
      _start();
    }
  }

  void resumeTimer() {
    if (state.status == KhokhoTimerStatus.paused) {
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    emit(state.copyWith(status: KhokhoTimerStatus.inProgress));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.duration > 0) {
        emit(state.copyWith(duration: state.duration - 1));
      } else {
        _timer?.cancel();
        emit(state.copyWith(status: KhokhoTimerStatus.paused));
      }
    });
  }

  void pauseTimer() {
    if (state.status == KhokhoTimerStatus.inProgress) {
      _timer?.cancel();
      emit(state.copyWith(status: KhokhoTimerStatus.paused));
    }
  }

  void stopTimer() {
    _timer?.cancel();
    emit(state.copyWith(status: KhokhoTimerStatus.paused));
  }

  void resetTimer(int duration) {
    _timer?.cancel();
    emit(KhokhoTimerState(duration: duration, status: KhokhoTimerStatus.initial));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
