import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_auth_entity.dart';
import '../repository/athlete_auth_repository.dart';

class RegisterAthleteUseCase {
  final AthleteAuthRepository _repository;

  const RegisterAthleteUseCase(this._repository);

  TaskEither<Failure, AthleteAuthEntity> call({
    required String name,
    required String email,
    required String password,
    required int sport,
  }) =>
      _repository.register(
        name: name,
        email: email,
        password: password,
        sport: sport,
      );
}
