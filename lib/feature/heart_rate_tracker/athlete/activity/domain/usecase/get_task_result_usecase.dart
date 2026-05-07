import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/task_result_entity.dart';
import '../repository/athlete_task_repository.dart';

class GetTaskResultUseCase {
  final AthleteTaskRepository _repository;

  const GetTaskResultUseCase(this._repository);

  TaskEither<Failure, TaskResultEntity> call(int taskId) =>
      _repository.getTaskResult(taskId);
}
