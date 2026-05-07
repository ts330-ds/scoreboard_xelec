import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/active_task_entity.dart';
import '../repository/active_tasks_repository.dart';

class GetActiveTasksUseCase {
  final ActiveTasksRepository _repo;
  const GetActiveTasksUseCase(this._repo);

  TaskEither<Failure, List<ActiveTaskEntity>> call({
    String status = 'in_progress',
  }) =>
      _repo.getActiveTasks(status: status);
}
