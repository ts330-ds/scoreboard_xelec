import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_hour_raw_entity.dart';
import '../repository/my_athletes_repository.dart';

class GetAthleteHourRawUseCase {
  final MyAthletesRepository _repository;

  const GetAthleteHourRawUseCase(this._repository);

  TaskEither<Failure, AthleteHourRawEntity> call({
    required int athleteId,
    required DateTime date,
    required int hour,
  }) =>
      _repository.getAthleteHourRaw(
        athleteId: athleteId,
        date: date,
        hour: hour,
      );
}
