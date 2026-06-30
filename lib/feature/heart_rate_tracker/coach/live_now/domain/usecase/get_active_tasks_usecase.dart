import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../data/datasource/active_tasks_remote_datasource.dart';
import '../repository/active_tasks_repository.dart';

class GetActiveTasksUseCase {
  final ActiveTasksRepository _repo;
  const GetActiveTasksUseCase(this._repo);

  TaskEither<Failure, ActiveTasksResult> call({
    String status = 'in_progress',
    int page = 1,
  }) =>
      _repo.getActiveTasks(status: status, page: page);
}
