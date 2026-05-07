import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/task_result_entity.dart';

enum TaskResultStatus { initial, loading, loaded, error }

class TaskResultState {
  final TaskResultStatus status;
  final TaskResultEntity? result;
  final String? errorMessage;

  const TaskResultState({
    required this.status,
    this.result,
    this.errorMessage,
  });

  const TaskResultState.initial()
      : status = TaskResultStatus.initial,
        result = null,
        errorMessage = null;

  TaskResultState copyWith({
    TaskResultStatus? status,
    TaskResultEntity? result,
    String? errorMessage,
  }) =>
      TaskResultState(
        status: status ?? this.status,
        result: result ?? this.result,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
