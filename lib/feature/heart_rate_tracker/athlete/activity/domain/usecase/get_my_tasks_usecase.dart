import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../repository/athlete_task_repository.dart';

class GetMyTasksUseCase {
  final AthleteTaskRepository _repository;
  const GetMyTasksUseCase(this._repository);

  TaskEither<Failure, MyTasksPage> call({int page = 1, String? status}) =>
      _repository.getMyTasks(page: page, status: status);
}
