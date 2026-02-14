part of 'football_timer_cubit.dart';

enum FootballTimerStatus { initial, inProgress, paused, finished }

class FootballTimerState extends Equatable {
  final int duration;
  final int initialDuration;
  final FootballTimerStatus status;

  const FootballTimerState({
    required this.duration,
    this.initialDuration = 0,
    this.status = FootballTimerStatus.initial,
  });

  FootballTimerState copyWith({
    int? duration,
    int? initialDuration,
    FootballTimerStatus? status,
  }) {
    return FootballTimerState(
      duration: duration ?? this.duration,
      initialDuration: initialDuration ?? this.initialDuration,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [duration, initialDuration, status];
}
