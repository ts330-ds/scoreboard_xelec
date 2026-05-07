import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_now/domain/entity/active_task_entity.dart';

enum CoachLiveNowStatus { initial, loading, loaded, error }

class CoachLiveNowState extends Equatable {
  final CoachLiveNowStatus status;
  final List<ActiveTaskEntity> tasks;
  final String? errorMessage;

  const CoachLiveNowState({
    this.status = CoachLiveNowStatus.initial,
    this.tasks = const [],
    this.errorMessage,
  });

  CoachLiveNowState copyWith({
    CoachLiveNowStatus? status,
    List<ActiveTaskEntity>? tasks,
    String? errorMessage,
  }) {
    return CoachLiveNowState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tasks, errorMessage];
}
