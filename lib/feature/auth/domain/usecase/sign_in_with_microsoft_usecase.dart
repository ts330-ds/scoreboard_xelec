import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/auth_user.dart';
import '../repository/auth_repository.dart';

class SignInWithMicrosoftUseCase {
  final AuthRepository _repository;

  const SignInWithMicrosoftUseCase(this._repository);

  TaskEither<Failure, AuthUser> call() => _repository.signInWithMicrosoft();
}
