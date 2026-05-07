import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/active_task_entity.dart';
import '../entity/coach_task_result_entity.dart';

abstract interface class ActiveTasksRepository {
  TaskEither<Failure, List<ActiveTaskEntity>> getActiveTasks({
    String status = 'in_progress',
  });

  TaskEither<Failure, CoachTaskResultEntity> getAthleteTaskResult(int taskId);
}
