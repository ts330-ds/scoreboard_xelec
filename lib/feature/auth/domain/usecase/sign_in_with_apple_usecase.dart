import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/auth_user.dart';
import '../repository/auth_repository.dart';

class SignInWithAppleUseCase {
  final AuthRepository _repository;

  const SignInWithAppleUseCase(this._repository);

  TaskEither<Failure, AuthUser> call() => _repository.signInWithApple();
}
