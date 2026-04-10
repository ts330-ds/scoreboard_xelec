import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../repository/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  TaskEither<Failure, Unit> call() => _repository.signOut();
}
