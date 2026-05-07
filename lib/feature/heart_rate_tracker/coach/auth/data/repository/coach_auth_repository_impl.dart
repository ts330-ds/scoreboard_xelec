import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../../domain/entity/coach_auth_entity.dart';
import '../../domain/repository/coach_auth_repository.dart';
import '../datasource/coach_auth_remote_datasource.dart';

class CoachAuthRepositoryImpl implements CoachAuthRepository {
  final CoachAuthRemoteDataSource _dataSource;
  final SharedPreferences _preferences;

  const CoachAuthRepositoryImpl(this._dataSource, this._preferences);

  void _saveCoach(CoachAuthEntity coach) {
    _preferences.setInt(PrefKeys.coachId, coach.id);
    _preferences.setString(PrefKeys.coachName, coach.name);
    _preferences.setString(PrefKeys.coachEmail, coach.email);
    _preferences.setString(PrefKeys.coachRole, coach.role);
    _preferences.setString(PrefKeys.coachToken, coach.token);
  }

  @override
  TaskEither<Failure, CoachAuthEntity> login({
    required String email,
    required String password,
  }) =>
      _dataSource.login(email: email, password: password).map((coach) {
        _saveCoach(coach);
        return coach;
      });

  @override
  TaskEither<Failure, CoachAuthEntity> loginWithSocial({
    required String email,
  }) =>
      _dataSource.loginWithSocial(email: email).map((coach) {
        _saveCoach(coach);
        return coach;
      });

  @override
  TaskEither<Failure, CoachAuthEntity> register({
    required String name,
    required String email,
    required String password,
    required int sport,
    required String organization,
  }) =>
      _dataSource
          .register(name: name, email: email, password: password, sport: sport, organization: organization)
          .map((coach) {
        _saveCoach(coach);
        return coach;
      });
}
