import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/failure.dart';
import 'package:xelex_esp/core/pref_keys.dart';

class LogoutCoachUseCase {
  final SharedPreferences _prefs;

  const LogoutCoachUseCase(this._prefs);

  TaskEither<Failure, Unit> call() =>
      TaskEither(() async {
        try {
          await _prefs.remove(PrefKeys.coachToken);
          await _prefs.remove(PrefKeys.coachId);
          await _prefs.remove(PrefKeys.coachName);
          await _prefs.remove(PrefKeys.coachEmail);
          await _prefs.remove(PrefKeys.coachRole);
          return right(unit);
        } catch (e) {
          return left(ServerFailure('Logout failed: $e'));
        }
      });
}
