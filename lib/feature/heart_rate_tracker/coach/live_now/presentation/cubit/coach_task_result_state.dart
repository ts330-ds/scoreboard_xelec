import '../../domain/entity/coach_task_result_entity.dart';

enum CoachTaskResultStatus { initial, loading, loaded, error }

class CoachTaskResultState {
  final CoachTaskResultStatus status;
  final CoachTaskResultEntity? result;
  final String? errorMessage;

  const CoachTaskResultState({
    required this.status,
    this.result,
    this.errorMessage,
  });

  const CoachTaskResultState.initial()
      : status = CoachTaskResultStatus.initial,
        result = null,
        errorMessage = null;

  CoachTaskResultState copyWith({
    CoachTaskResultStatus? status,
    CoachTaskResultEntity? result,
    String? errorMessage,
  }) =>
      CoachTaskResultState(
        status: status ?? this.status,
        result: result ?? this.result,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
