import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'football_timer_state.dart';

class FootballTimerCubit extends Cubit<FootballTimerState> {
  FootballTimerCubit() : super(const FootballTimerState(duration: 0)); // Football usually counts up

  Timer? _timer;

  void startTimer() {
    if (state.status != FootballTimerStatus.inProgress) {
      _timer?.cancel();
      emit(state.copyWith(status: FootballTimerStatus.inProgress));
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        emit(state.copyWith(duration: state.duration + 1));
      });
    }
  }

  void pauseTimer() {
    _timer?.cancel();
    emit(state.copyWith(status: FootballTimerStatus.paused));
  }

  void resumeTimer() => startTimer();

  void resetTimer() {
    _timer?.cancel();
    emit(const FootballTimerState(duration: 0, status: FootballTimerStatus.initial));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
