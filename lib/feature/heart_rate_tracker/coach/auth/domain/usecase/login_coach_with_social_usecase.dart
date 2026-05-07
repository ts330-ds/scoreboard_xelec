import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/coach_auth_entity.dart';
import '../repository/coach_auth_repository.dart';

class LoginCoachWithSocialUseCase {
  final CoachAuthRepository _repository;

  const LoginCoachWithSocialUseCase(this._repository);

  TaskEither<Failure, CoachAuthEntity> call({required String email}) =>
      _repository.loginWithSocial(email: email);
}
