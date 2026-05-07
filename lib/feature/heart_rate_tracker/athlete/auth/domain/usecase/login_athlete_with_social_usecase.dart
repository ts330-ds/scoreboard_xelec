import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_auth_entity.dart';
import '../repository/athlete_auth_repository.dart';

class LoginAthleteWithSocialUseCase {
  final AthleteAuthRepository _repository;

  const LoginAthleteWithSocialUseCase(this._repository);

  TaskEither<Failure, AthleteAuthEntity> call({required String email}) =>
      _repository.loginWithSocial(email: email);
}
