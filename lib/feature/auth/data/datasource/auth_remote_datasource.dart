import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:xelex_esp/core/failure.dart';
import '../model/auth_user_model.dart';

abstract interface class AuthRemoteDataSource {
  TaskEither<Failure, AuthUserModel> signInWithGoogle();
  TaskEither<Failure, AuthUserModel> signInWithLinkedIn();
  TaskEither<Failure, AuthUserModel> signInWithMicrosoft();
  TaskEither<Failure, AuthUserModel> signInWithApple();
  TaskEither<Failure, Unit> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final GoogleSignIn _googleSignIn;

  const AuthRemoteDataSourceImpl(this._googleSignIn);

  @override
  TaskEither<Failure, AuthUserModel> signInWithGoogle() => TaskEither(() async {
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) return left(const CancelledByUserFailure());
      return right(AuthUserModel.fromGoogleAccount(account));
    } catch (e) {
      return left(AuthFailure('Google sign-in failed: $e'));
    }
  });

  @override
  TaskEither<Failure, AuthUserModel> signInWithLinkedIn() =>
      TaskEither(() async {
        await Future.delayed(const Duration(seconds: 1));
        return right(
          const AuthUserModel(
            id: 'linkedin_dummy_001',
            email: 'tusharsoni123@gmail.com',
            displayName: 'LinkedIn User',
            photoUrl: null,
          ),
        );
      });

  @override
  TaskEither<Failure, AuthUserModel> signInWithMicrosoft() =>
      TaskEither(() async {
        await Future.delayed(const Duration(seconds: 1));
        return right(
          const AuthUserModel(
            id: 'microsoft_dummy_001',
            email: 'tusharsoni123@gmail.com',
            displayName: 'Microsoft User',
            photoUrl: null,
          ),
        );
      });

  @override
  TaskEither<Failure, AuthUserModel> signInWithApple() => TaskEither(() async {
        await Future.delayed(const Duration(seconds: 1));
        return right(
          const AuthUserModel(
            id: 'apple_dummy_001',
            email: 'tusharsoni123@gmail.com',
            displayName: 'Apple User',
            photoUrl: null,
          ),
        );
      });

  @override
  TaskEither<Failure, Unit> signOut() => TaskEither(() async {
    try {
      await _googleSignIn.signOut();
      return right(unit);
    } catch (e) {
      return left(AuthFailure('Sign-out failed: $e'));
    }
  });
}
