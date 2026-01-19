part of 'football_timer_cubit.dart';

enum FootballTimerStatus { initial, inProgress, paused }

class FootballTimerState extends Equatable {
  final int duration;
  final FootballTimerStatus status;

  const FootballTimerState({required this.duration, this.status = FootballTimerStatus.initial});

  FootballTimerState copyWith({
    int? duration,
    FootballTimerStatus? status,
  }) {
    return FootballTimerState(
      duration: duration ?? this.duration,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [duration, status];
}
