import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_profile_entity.dart';
import '../repository/athlete_profile_repository.dart';

class GetAthleteProfileUseCase {
  final AthleteProfileRepository _repository;

  const GetAthleteProfileUseCase(this._repository);

  TaskEither<Failure, AthleteProfileEntity> call() => _repository.getProfile();
}
