import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_task_entity.dart';
import '../repository/athlete_task_repository.dart';

class CreateAthleteTaskUseCase {
  final AthleteTaskRepository _repo;

  const CreateAthleteTaskUseCase(this._repo);

  TaskEither<Failure, AthleteTaskEntity> call({
    required String name,
    required String duration,
    required String assignedBy,
  }) =>
      _repo.createTask(name: name, duration: duration, assignedBy: assignedBy);
}
