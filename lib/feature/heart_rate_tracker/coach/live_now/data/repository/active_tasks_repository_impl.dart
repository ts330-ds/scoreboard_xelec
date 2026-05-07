import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../domain/entity/active_task_entity.dart';
import '../../domain/entity/coach_task_result_entity.dart';
import '../../domain/repository/active_tasks_repository.dart';
import '../datasource/active_tasks_remote_datasource.dart';

class ActiveTasksRepositoryImpl implements ActiveTasksRepository {
  final ActiveTasksRemoteDataSource _dataSource;
  const ActiveTasksRepositoryImpl(this._dataSource);

  @override
  TaskEither<Failure, List<ActiveTaskEntity>> getActiveTasks({
    String status = 'in_progress',
  }) =>
      _dataSource.getActiveTasks(status: status);

  @override
  TaskEither<Failure, CoachTaskResultEntity> getAthleteTaskResult(
          int taskId) =>
      _dataSource.getAthleteTaskResult(taskId);
}
