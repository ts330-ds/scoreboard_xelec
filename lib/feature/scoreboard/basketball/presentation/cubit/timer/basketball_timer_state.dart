enum TimerStatus {
  initial,
  running,
  paused,
  finished
}


class BasketBallTimerState {
  final int seconds;
  final int initialSeconds;
  final TimerStatus status;
  final int quarter;

  const BasketBallTimerState({
    required this.seconds,
    required this.initialSeconds,
    required this.status,
    this.quarter = 1,
  });

  factory BasketBallTimerState.initial(int totalTime) {
    return  BasketBallTimerState(
      seconds: totalTime,
      initialSeconds: 0,
      status: TimerStatus.initial,
      quarter: 1,
    );
  }

  BasketBallTimerState copyWith({
    int? seconds,
    int? initialSeconds,
    TimerStatus? status,
    int? quarter,
  }) {
    return BasketBallTimerState(
      seconds: seconds ?? this.seconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      status: status ?? this.status,
      quarter: quarter ?? this.quarter,
    );
  }

  Map<String,dynamic> toJson(){
    return {
      "seconds": seconds,
      /*"initialSeconds": initialSeconds,
      "status": status.toString(),*/
      "quarter": quarter,
    };
  }

}

