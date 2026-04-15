import 'package:fpdart/fpdart.dart';
import 'package:xelex_esp/core/failure.dart';
import '../entity/auth_user.dart';

abstract interface class AuthRepository {
  TaskEither<Failure, AuthUser> signInWithGoogle();
  TaskEither<Failure, AuthUser> signInWithLinkedIn();
  TaskEither<Failure, AuthUser> signInWithMicrosoft();
  TaskEither<Failure, AuthUser> signInWithApple();
  TaskEither<Failure, Unit> signOut();
}
