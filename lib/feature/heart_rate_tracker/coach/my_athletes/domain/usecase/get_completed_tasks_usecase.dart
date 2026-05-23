import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/completed_task_entity.dart';
import '../repository/my_athletes_repository.dart';

class GetCompletedTasksUseCase {
  final MyAthletesRepository _repository;
  const GetCompletedTasksUseCase(this._repository);

  TaskEither<Failure, List<CompletedTaskEntity>> call(int athleteId) =>
      _repository.getCompletedTasks(athleteId);
}
