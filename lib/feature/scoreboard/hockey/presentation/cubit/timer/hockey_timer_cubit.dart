import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/cubit/timer/hockey_timer_state.dart';

class HockeyTimerCubit extends Cubit<HockeyTimerState> {
  Timer? _timer;

  /// Base duration for each quarter (user configurable)
  int totalSeconds;

  /// Default = 15 minutes (900 seconds)
  HockeyTimerCubit({int initialSeconds = 900})
      : totalSeconds = initialSeconds,
        super(HockeyTimerState.initial(initialSeconds));

  /// Set match/quarter time manually (from user input)
  void setTime(int seconds) {
    _timer?.cancel();

    totalSeconds = seconds;

    emit(
      state.copyWith(
        seconds: seconds,
        initialSeconds: seconds,
        status: TimerStatus.initial,
      ),
    );
  }

  /// Start timer
  void start() {
    if (state.status == TimerStatus.running) return;

    emit(state.copyWith(status: TimerStatus.running));

    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (state.seconds <= 1) {
          timer.cancel();
          emit(
            state.copyWith(
              seconds: 0,
              status: TimerStatus.finished,
            ),
          );
        } else {
          emit(state.copyWith(seconds: state.seconds - 1));
        }
      },
    );
  }

  /// Pause timer
  void pause() {
    if (state.status != TimerStatus.running) return;

    _timer?.cancel();
    emit(state.copyWith(status: TimerStatus.paused));
  }

  /// Resume timer
  void resume() {
    if (state.status != TimerStatus.paused) return;
    start();
  }

  /// Reset timer to initial configured duration
  void reset() {
    _timer?.cancel();
    emit(HockeyTimerState.initial(totalSeconds));
  }

  /// Set quarter (1–4)
  /// Allowed only when timer is NOT running
  bool setQuarter(int quarter) {
    if (quarter < 1 || quarter > 4) return false;
    if (state.status == TimerStatus.running) return false;

    emit(
      state.copyWith(
        quarter: quarter,
        seconds: totalSeconds,
        status: TimerStatus.initial,
      ),
    );
    return true;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
