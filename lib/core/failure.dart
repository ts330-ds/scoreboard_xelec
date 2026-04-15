abstract class Failure {
  final String message;
  const Failure(this.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class CancelledByUserFailure extends Failure {
  const CancelledByUserFailure() : super('Sign-in cancelled by user');
}

class SportFailure extends Failure {
  const SportFailure(super.message);
}
