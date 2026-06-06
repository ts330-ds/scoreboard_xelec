import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_task_entity.dart';
import '../entity/task_result_entity.dart';

class MyTasksPage {
  final List<AthleteTaskEntity> tasks;
  final int totalRecords;

  const MyTasksPage({
    required this.tasks,
    required this.totalRecords,
  });
}

abstract interface class AthleteTaskRepository {
  TaskEither<Failure, AthleteTaskEntity> createTask({
    required String name,
    required String assignedBy,
  });

  TaskEither<Failure, MyTasksPage> getMyTasks({int page = 1});

  TaskEither<Failure, TaskResultEntity> getTaskResult(int taskId);

  TaskEither<Failure, bool> submitTaskResults({
    required int taskId,
    required bool isFirstChunk,
    required bool isLastChunk,
    required List<Map<String, dynamic>> readings,
  });
}
