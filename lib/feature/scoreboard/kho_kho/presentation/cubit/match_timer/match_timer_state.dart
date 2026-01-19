part of 'match_timer_cubit.dart';

enum MatchTimerStatus { initial, inProgress, paused }

class MatchTimerState extends Equatable {
  final int duration;
  final MatchTimerStatus status;

  const MatchTimerState({required this.duration, this.status = MatchTimerStatus.initial});

  MatchTimerState copyWith({
    int? duration,
    MatchTimerStatus? status,
  }) {
    return MatchTimerState(
      duration: duration ?? this.duration,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [duration, status];
}
