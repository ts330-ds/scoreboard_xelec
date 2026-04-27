import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_auth_entity.dart';
import '../repository/athlete_auth_repository.dart';

class LoginAthleteUseCase {
  final AthleteAuthRepository _repository;

  const LoginAthleteUseCase(this._repository);

  TaskEither<Failure, AthleteAuthEntity> call({
    required String email,
    required String password,
  }) =>
      _repository.login(email: email, password: password);
}
