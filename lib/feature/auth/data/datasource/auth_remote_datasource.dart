import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:xelex_esp/core/failure.dart';
import '../model/auth_user_model.dart';

abstract interface class AuthRemoteDataSource {
  TaskEither<Failure, AuthUserModel> signInWithGoogle();
  TaskEither<Failure, Unit> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final GoogleSignIn _googleSignIn;

  const AuthRemoteDataSourceImpl(this._googleSignIn);

  @override
  TaskEither<Failure, AuthUserModel> signInWithGoogle() => TaskEither(() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return left(const CancelledByUserFailure());
      return right(AuthUserModel.fromGoogleAccount(account));
    } catch (e) {
      return left(AuthFailure('Google sign-in failed: $e'));
    }
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
