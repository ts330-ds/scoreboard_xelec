import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/coach_profile_entity.dart';
import '../repository/coach_profile_repository.dart';

class UpdateCoachProfileUseCase {
  final CoachProfileRepository _repository;

  const UpdateCoachProfileUseCase(this._repository);

  TaskEither<Failure, CoachProfileEntity> call({
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
  }) =>
      _repository.updateProfile(
        name: name,
        organization: organization,
        sport: sport,
        phone: phone,
        aadhar: aadhar,
        dob: dob,
        sex: sex,
        dominantHand: dominantHand,
        heightInFeet: heightInFeet,
        heightInInches: heightInInches,
        weightInKg: weightInKg,
        weightInLbs: weightInLbs,
      );
}
