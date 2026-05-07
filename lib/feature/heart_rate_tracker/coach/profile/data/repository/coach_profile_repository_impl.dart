import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../domain/entity/coach_profile_entity.dart';
import '../../domain/repository/coach_profile_repository.dart';
import '../datasource/coach_profile_remote_datasource.dart';

class CoachProfileRepositoryImpl implements CoachProfileRepository {
  final CoachProfileRemoteDataSource _dataSource;

  const CoachProfileRepositoryImpl(this._dataSource);

  @override
  TaskEither<Failure, CoachProfileEntity> getProfile() =>
      _dataSource.getProfile();

  @override
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
  }) =>
      _dataSource.updateProfile(
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
