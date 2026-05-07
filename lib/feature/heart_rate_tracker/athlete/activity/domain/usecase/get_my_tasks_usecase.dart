import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_task_entity.dart';
import '../repository/athlete_task_repository.dart';

class GetMyTasksUseCase {
  final AthleteTaskRepository _repository;
  const GetMyTasksUseCase(this._repository);

  TaskEither<Failure, List<AthleteTaskEntity>> call() => _repository.getMyTasks();
}
