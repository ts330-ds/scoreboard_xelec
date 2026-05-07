import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/coach_auth_entity.dart';

abstract interface class CoachAuthRepository {
  TaskEither<Failure, CoachAuthEntity> login({
    required String email,
    required String password,
  });

  TaskEither<Failure, CoachAuthEntity> loginWithSocial({
    required String email,
  });

  TaskEither<Failure, CoachAuthEntity> register({
    required String name,
    required String email,
    required String password,
    required int sport,
    required String organization,
  });
}
