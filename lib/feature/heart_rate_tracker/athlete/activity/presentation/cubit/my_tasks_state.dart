import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/athlete_task_entity.dart';

enum MyTasksStatus { initial, loading, loaded, error }

class MyTasksState extends Equatable {
  final MyTasksStatus status;
  final List<AthleteTaskEntity> tasks;
  final String? errorMessage;

  const MyTasksState({
    this.status = MyTasksStatus.initial,
    this.tasks = const [],
    this.errorMessage,
  });

  MyTasksState copyWith({
    MyTasksStatus? status,
    List<AthleteTaskEntity>? tasks,
    String? errorMessage,
  }) {
    return MyTasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tasks, errorMessage];
}
