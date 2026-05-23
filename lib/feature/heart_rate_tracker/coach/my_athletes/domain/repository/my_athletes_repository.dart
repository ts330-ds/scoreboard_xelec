import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../data/datasource/my_athletes_remote_datasource.dart';
import '../entity/athlete_health_metrics_entity.dart';
import '../entity/athlete_hour_raw_entity.dart';
import '../entity/completed_task_entity.dart';
import '../entity/my_athlete_entity.dart';

abstract interface class MyAthletesRepository {
  TaskEither<Failure, MyAthletesResult> getMyAthletes({
    String? search,
    int page = 1,
  });

  TaskEither<Failure, MyAthleteEntity> getAthleteDetail(int athleteId);

  TaskEither<Failure, void> removeAthlete(int athleteId);

  TaskEither<Failure, AthleteHealthMetricsEntity> getAthleteHealthMetrics({
    required int athleteId,
    required DateTime fromDate,
    required DateTime toDate,
  });

  TaskEither<Failure, AthleteHourRawEntity> getAthleteHourRaw({
    required int athleteId,
    required DateTime date,
    required int hour,
  });

  TaskEither<Failure, List<CompletedTaskEntity>> getCompletedTasks(
      int athleteId);
}
