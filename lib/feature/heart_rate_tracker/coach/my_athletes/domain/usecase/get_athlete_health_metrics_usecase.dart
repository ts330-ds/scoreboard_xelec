import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_health_metrics_entity.dart';
import '../repository/my_athletes_repository.dart';

class GetAthleteHealthMetricsUseCase {
  final MyAthletesRepository _repository;

  const GetAthleteHealthMetricsUseCase(this._repository);

  TaskEither<Failure, AthleteHealthMetricsEntity> call({
    required int athleteId,
    required DateTime fromDate,
    required DateTime toDate,
  }) =>
      _repository.getAthleteHealthMetrics(
        athleteId: athleteId,
        fromDate: fromDate,
        toDate: toDate,
      );
}
