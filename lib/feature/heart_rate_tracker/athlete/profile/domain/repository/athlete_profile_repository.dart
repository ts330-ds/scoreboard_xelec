import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_profile_entity.dart';

abstract interface class AthleteProfileRepository {
  TaskEither<Failure, AthleteProfileEntity> getProfile();

  TaskEither<Failure, AthleteProfileEntity> updateProfile({
    required String name,
    String? phone,
    String? aadhar,
    String? dob,
    String? sex,
    String? dominantHand,
    double? heightInFeet,
    double? heightInInches,
    double? weightInKg,
    double? weightInLbs,
    int? sportId,
    String? deviceModel,
    String? deviceSerial,
  });
}
