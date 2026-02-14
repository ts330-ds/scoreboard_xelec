enum TimerStatus { initial, running, paused, finished }

class HandBallTimerState {
  final int seconds;
  final int initialSeconds;
  final TimerStatus status;
  final int quarter;

  const HandBallTimerState({
    required this.seconds,
    required this.initialSeconds,
    required this.status,
    this.quarter = 1,
  });

  factory HandBallTimerState.initial(int totalTime) {
    return HandBallTimerState(
      seconds: totalTime,
      initialSeconds: 0,
      status: TimerStatus.initial,
      quarter: 1,
    );
  }

  HandBallTimerState copyWith({
    int? seconds,
    int? initialSeconds,
    TimerStatus? status,
    int? quarter,
  }) {
    return HandBallTimerState(
      seconds: seconds ?? this.seconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      status: status ?? this.status,
      quarter: quarter ?? this.quarter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "seconds": seconds,
      /*"initialSeconds": initialSeconds,
      "status": status.toString(),*/
      "quarter": quarter,
    };
  }
}
