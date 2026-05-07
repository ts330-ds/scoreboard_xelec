import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/my_athlete_entity.dart';
import '../repository/my_athletes_repository.dart';

class GetAthleteDetailUseCase {
  final MyAthletesRepository _repository;
  const GetAthleteDetailUseCase(this._repository);

  TaskEither<Failure, MyAthleteEntity> call(int athleteId) =>
      _repository.getAthleteDetail(athleteId);
}
