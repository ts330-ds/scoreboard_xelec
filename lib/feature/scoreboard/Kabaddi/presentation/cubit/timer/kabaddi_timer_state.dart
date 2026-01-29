enum TimerStatus {
  initial,
  running,
  paused,
  finished
}

class KabaddiTimerState {
  final int seconds;
  final int initialSeconds;
  final TimerStatus status;

  const KabaddiTimerState({
    required this.seconds,
    required this.initialSeconds,
    required this.status,
  });

  factory KabaddiTimerState.initial({int startMinutes = 20}) {
    return KabaddiTimerState(
      seconds: startMinutes * 60,
      initialSeconds: startMinutes * 60,
      status: TimerStatus.initial
    );
  }

  KabaddiTimerState copyWith({
    int? seconds,
    int? initialSeconds,
    TimerStatus? status,
  }) {
    return KabaddiTimerState(
      seconds: seconds ?? this.seconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      status: status?? this.status,
    );
  }
}
