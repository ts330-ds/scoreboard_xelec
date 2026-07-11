import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../domain/entity/athlete_task_entity.dart';
import '../../domain/entity/task_result_entity.dart';
import '../../domain/repository/athlete_task_repository.dart';
import '../datasource/athlete_task_remote_datasource.dart';

class AthleteTaskRepositoryImpl implements AthleteTaskRepository {
  final AthleteTaskRemoteDataSource _dataSource;

  const AthleteTaskRepositoryImpl(this._dataSource);

  @override
  TaskEither<Failure, AthleteTaskEntity> createTask({
    required String name,
    required String assignedBy,
  }) =>
      _dataSource.createTask(name: name, assignedBy: assignedBy);

  @override
  TaskEither<Failure, MyTasksPage> getMyTasks({int page = 1, String? status}) =>
      _dataSource.getMyTasks(page: page, status: status).map(
            (result) => MyTasksPage(
              tasks: result.tasks,
              totalRecords: result.totalRecords,
            ),
          );

  @override
  TaskEither<Failure, TaskResultEntity> getTaskResult(int taskId) =>
      _dataSource.getTaskResult(taskId);

  @override
  TaskEither<Failure, bool> submitTaskResults({
    required int taskId,
    required bool isFirstChunk,
    required bool isLastChunk,
    required List<Map<String, dynamic>> readings,
  }) =>
      _dataSource.submitTaskResults(
        taskId: taskId,
        isFirstChunk: isFirstChunk,
        isLastChunk: isLastChunk,
        readings: readings,
      );
}
