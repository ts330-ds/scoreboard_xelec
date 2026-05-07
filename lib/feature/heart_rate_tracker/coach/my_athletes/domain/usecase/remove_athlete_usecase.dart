import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../repository/my_athletes_repository.dart';

class RemoveAthleteUseCase {
  final MyAthletesRepository _repository;
  const RemoveAthleteUseCase(this._repository);

  TaskEither<Failure, void> call(int athleteId) =>
      _repository.removeAthlete(athleteId);
}
