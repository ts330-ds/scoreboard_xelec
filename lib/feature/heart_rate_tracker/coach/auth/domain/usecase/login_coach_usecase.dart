import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/coach_auth_entity.dart';
import '../repository/coach_auth_repository.dart';

class LoginCoachUseCase {
  final CoachAuthRepository _repository;

  const LoginCoachUseCase(this._repository);

  TaskEither<Failure, CoachAuthEntity> call({
    required String email,
    required String password,
  }) =>
      _repository.login(email: email, password: password);
}
