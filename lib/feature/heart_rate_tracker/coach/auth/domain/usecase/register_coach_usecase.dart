import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/coach_auth_entity.dart';
import '../repository/coach_auth_repository.dart';

class RegisterCoachUseCase {
  final CoachAuthRepository _repository;

  const RegisterCoachUseCase(this._repository);

  TaskEither<Failure, CoachAuthEntity> call({
    required String name,
    required String email,
    required String password,
    required int sport,
    required String organization,
  }) =>
      _repository.register(
        name: name,
        email: email,
        password: password,
        sport: sport,
        organization: organization,
      );
}
