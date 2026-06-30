import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../data/datasource/active_tasks_remote_datasource.dart';
import '../entity/coach_task_result_entity.dart';

abstract interface class ActiveTasksRepository {
  TaskEither<Failure, ActiveTasksResult> getActiveTasks({
    String status = 'in_progress',
    int page = 1,
  });

  TaskEither<Failure, CoachTaskResultEntity> getAthleteTaskResult(int taskId);
}
