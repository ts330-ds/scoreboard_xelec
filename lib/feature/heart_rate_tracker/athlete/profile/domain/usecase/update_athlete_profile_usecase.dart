import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_profile_entity.dart';
import '../repository/athlete_profile_repository.dart';

class UpdateAthleteProfileUseCase {
  final AthleteProfileRepository _repository;

  const UpdateAthleteProfileUseCase(this._repository);

  TaskEither<Failure, AthleteProfileEntity> call({
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
  }) =>
      _repository.updateProfile(
        name: name,
        phone: phone,
        aadhar: aadhar,
        dob: dob,
        sex: sex,
        dominantHand: dominantHand,
        heightInFeet: heightInFeet,
        heightInInches: heightInInches,
        weightInKg: weightInKg,
        weightInLbs: weightInLbs,
        sportId: sportId,
        deviceModel: deviceModel,
        deviceSerial: deviceSerial,
      );
}
