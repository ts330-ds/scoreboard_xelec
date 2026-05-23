import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_task_entity.dart';
import '../entity/task_result_entity.dart';

abstract interface class AthleteTaskRepository {
  TaskEither<Failure, AthleteTaskEntity> createTask({
    required String name,
    required String assignedBy,
  });

  TaskEither<Failure, List<AthleteTaskEntity>> getMyTasks();

  TaskEither<Failure, TaskResultEntity> getTaskResult(int taskId);
}
