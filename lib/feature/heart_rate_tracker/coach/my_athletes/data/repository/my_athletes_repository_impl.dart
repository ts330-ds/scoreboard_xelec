import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../domain/entity/athlete_health_metrics_entity.dart';
import '../../domain/entity/my_athlete_entity.dart';
import '../../domain/repository/my_athletes_repository.dart';
import '../datasource/my_athletes_remote_datasource.dart';

class MyAthletesRepositoryImpl implements MyAthletesRepository {
  final MyAthletesRemoteDataSource _dataSource;
  const MyAthletesRepositoryImpl(this._dataSource);

  @override
  TaskEither<Failure, MyAthletesResult> getMyAthletes({
    String? search,
    int page = 1,
  }) =>
      _dataSource.getMyAthletes(search: search, page: page);

  @override
  TaskEither<Failure, MyAthleteEntity> getAthleteDetail(int athleteId) =>
      _dataSource.getAthleteDetail(athleteId);

  @override
  TaskEither<Failure, void> removeAthlete(int athleteId) =>
      _dataSource.removeAthlete(athleteId);

  @override
  TaskEither<Failure, AthleteHealthMetricsEntity> getAthleteHealthMetrics({
    required int athleteId,
    required DateTime fromDate,
    required DateTime toDate,
  }) =>
      _dataSource.getHealthMetrics(
        athleteId: athleteId,
        fromDate: fromDate,
        toDate: toDate,
      );
}
