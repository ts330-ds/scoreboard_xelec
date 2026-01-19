import 'package:equatable/equatable.dart';

enum ShotClockStatus { initial, running, paused, expired }

class ShotClockState extends Equatable {
  final int seconds;
  final ShotClockStatus status;

  const ShotClockState({
    this.seconds = 24,
    this.status = ShotClockStatus.initial,
  });

  ShotClockState copyWith({
    int? seconds,
    ShotClockStatus? status,
  }) {
    return ShotClockState(
      seconds: seconds ?? this.seconds,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [seconds, status];
}
