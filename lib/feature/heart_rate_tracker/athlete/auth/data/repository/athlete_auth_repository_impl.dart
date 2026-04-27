import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../../domain/entity/athlete_auth_entity.dart';
import '../../domain/repository/athlete_auth_repository.dart';
import '../datasource/athlete_auth_remote_datasource.dart';

class AthleteAuthRepositoryImpl implements AthleteAuthRepository {
  final AthleteAuthRemoteDataSource _dataSource;
  final SharedPreferences _preferences;

  const AthleteAuthRepositoryImpl(this._dataSource, this._preferences);

  void _saveUser(AthleteAuthEntity athlete) {
    _preferences.setInt(PrefKeys.userId, athlete.id);
    _preferences.setString(PrefKeys.userName, athlete.name);
    _preferences.setString(PrefKeys.userEmail, athlete.email);
    _preferences.setString(PrefKeys.userRole, athlete.role);
    _preferences.setString(PrefKeys.userToken, athlete.token);
  }

  @override
  TaskEither<Failure, AthleteAuthEntity> login({
    required String email,
    required String password,
  }) =>
      _dataSource.login(email: email, password: password).map((athlete) {
        _saveUser(athlete);
        return athlete;
      });

  @override
  TaskEither<Failure, AthleteAuthEntity> register({
    required String name,
    required String email,
    required String password,
    required int sport,
  }) =>
      _dataSource
          .register(name: name, email: email, password: password, sport: sport)
          .map((athlete) {
        _saveUser(athlete);
        return athlete;
      });
}
