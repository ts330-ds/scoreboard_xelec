import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_profile_entity.dart';
import '../repository/athlete_profile_repository.dart';

class UpdateAthleteProfileUseCase {
  final AthleteProfileRepository _repository;

  const UpdateAthleteProfileUseCase(this._repository);

  TaskEither<Failure, AthleteProfileEntity> call({
    String? name,
    String? phone,
    int? age,
    String? gender,
    int? sportId,
  }) =>
      _repository.updateProfile(
        name: name,
        phone: phone,
        age: age,
        gender: gender,
        sportId: sportId,
      );
}
