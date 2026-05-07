import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/coach_task_result_entity.dart';
import '../repository/active_tasks_repository.dart';

class GetCoachTaskResultUseCase {
  final ActiveTasksRepository _repo;
  const GetCoachTaskResultUseCase(this._repo);

  TaskEither<Failure, CoachTaskResultEntity> call(int taskId) =>
      _repo.getAthleteTaskResult(taskId);
}
