import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/coach_profile_entity.dart';

abstract interface class CoachProfileRepository {
  TaskEither<Failure, CoachProfileEntity> getProfile();

  TaskEither<Failure, CoachProfileEntity> updateProfile({
    required String name,
    required String organization,
    required int sport,
    String? phone,
    String? aadhar,
    String? dob,
    String? sex,
    String? dominantHand,
    double? heightInFeet,
    double? heightInInches,
    double? weightInKg,
    double? weightInLbs,
  });
}
