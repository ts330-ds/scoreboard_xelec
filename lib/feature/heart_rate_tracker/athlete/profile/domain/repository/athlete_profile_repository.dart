import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_profile_entity.dart';

abstract interface class AthleteProfileRepository {
  TaskEither<Failure, AthleteProfileEntity> getProfile();

  TaskEither<Failure, AthleteProfileEntity> updateProfile({
    String? name,
    String? phone,
    int? age,
    String? gender,
    int? sportId,
  });
}
