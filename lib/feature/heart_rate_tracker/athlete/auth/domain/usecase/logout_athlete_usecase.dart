import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';

class LogoutAthleteUseCase {
  final SharedPreferences _prefs;

  const LogoutAthleteUseCase(this._prefs);

  TaskEither<Failure, Unit> call() =>
      TaskEither(() async {
        try {
          await _prefs.clear();
          return right(unit);
        } catch (e) {
          return left(ServerFailure('Logout failed: $e'));
        }
      });
}
