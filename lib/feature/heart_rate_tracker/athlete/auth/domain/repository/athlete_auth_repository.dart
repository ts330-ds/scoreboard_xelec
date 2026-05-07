import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/athlete_auth_entity.dart';

abstract interface class AthleteAuthRepository {
  TaskEither<Failure, AthleteAuthEntity> login({
    required String email,
    required String password,
  });

  TaskEither<Failure, AthleteAuthEntity> loginWithSocial({
    required String email,
  });

  TaskEither<Failure, AthleteAuthEntity> register({
    required String name,
    required String email,
    required String password,
    required int sport,
  });
}
