import '../../domain/entity/completed_task_entity.dart';

enum CompletedTasksStatus { initial, loading, loaded, error }

class CompletedTasksState {
  final CompletedTasksStatus status;
  final List<CompletedTaskEntity> tasks;
  final String? errorMessage;

  const CompletedTasksState({
    required this.status,
    this.tasks = const [],
    this.errorMessage,
  });

  const CompletedTasksState.initial()
      : status = CompletedTasksStatus.initial,
        tasks = const [],
        errorMessage = null;

  CompletedTasksState copyWith({
    CompletedTasksStatus? status,
    List<CompletedTaskEntity>? tasks,
    String? errorMessage,
  }) =>
      CompletedTasksState(
        status: status ?? this.status,
        tasks: tasks ?? this.tasks,
        errorMessage: errorMessage,
      );
}
