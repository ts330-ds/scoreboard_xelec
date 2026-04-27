
import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/registration/domain/entity/register_athlete_entity.dart';

abstract class RegisterAthleteRepository {
  Task<Either<Failure, void>> registerAthlete(RegisterAthleteEntity entity);

}