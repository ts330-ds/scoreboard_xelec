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
    required String duration,
    required String assignedBy,
  }) =>
      _dataSource.createTask(name: name, duration: duration, assignedBy: assignedBy);

  @override
  TaskEither<Failure, List<AthleteTaskEntity>> getMyTasks() =>
      _dataSource.getMyTasks();

  @override
  TaskEither<Failure, TaskResultEntity> getTaskResult(int taskId) =>
      _dataSource.getTaskResult(taskId);
}
