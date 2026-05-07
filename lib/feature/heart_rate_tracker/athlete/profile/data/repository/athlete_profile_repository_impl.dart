import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../domain/entity/athlete_profile_entity.dart';
import '../../domain/repository/athlete_profile_repository.dart';
import '../datasource/athlete_profile_remote_datasource.dart';

class AthleteProfileRepositoryImpl implements AthleteProfileRepository {
  final AthleteProfileRemoteDataSource _dataSource;

  const AthleteProfileRepositoryImpl(this._dataSource);


  @override
  TaskEither<Failure, AthleteProfileEntity> getProfile() =>
      _dataSource.getProfile();

  @override
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
  }) =>
      _dataSource.updateProfile(
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
