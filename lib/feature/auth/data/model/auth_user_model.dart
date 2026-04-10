import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entity/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
  });

  factory AuthUserModel.fromGoogleAccount(GoogleSignInAccount account) {
    return AuthUserModel(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }
}
