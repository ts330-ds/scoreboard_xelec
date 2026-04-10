import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/auth_user.dart';
import '../repository/auth_repository.dart';

class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  const SignInWithGoogleUseCase(this._repository);

  TaskEither<Failure, AuthUser> call() => _repository.signInWithGoogle();
}
