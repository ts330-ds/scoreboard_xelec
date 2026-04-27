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
    String? name,
    String? phone,
    int? age,
    String? gender,
    int? sportId,
  }) =>
      _dataSource.updateProfile(
        name: name,
        phone: phone,
        age: age,
        gender: gender,
        sportId: sportId,
      );
}
