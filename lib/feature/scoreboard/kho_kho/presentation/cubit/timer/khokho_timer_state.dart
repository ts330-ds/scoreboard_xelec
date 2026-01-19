part of 'khokho_timer_cubit.dart';

enum KhokhoTimerStatus { initial, inProgress, paused }

class KhokhoTimerState extends Equatable {
  final int duration;
  final KhokhoTimerStatus status;

  const KhokhoTimerState({required this.duration, this.status = KhokhoTimerStatus.initial});

  KhokhoTimerState copyWith({
    int? duration,
    KhokhoTimerStatus? status,
  }) {
    return KhokhoTimerState(
      duration: duration ?? this.duration,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [duration, status];
}
