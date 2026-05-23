import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';

// SharedPreferences wrapper for history-push watermarks.
// Per-athlete scoped to prevent cross-account leak on shared device.
class HistoryWatermarkStore {
  final SharedPreferences _prefs;
  final String _athleteId;

  HistoryWatermarkStore(this._prefs, this._athleteId);

  /// True when no logged-in user id was found in prefs. Callers should
  /// refuse to push data in this state to avoid attributing readings to
  /// the wrong account on a shared device.
  bool get isAnonymous => _athleteId == 'anon';

  String get athleteId => _athleteId;

  static Future<HistoryWatermarkStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    // userId auth repo me setInt se save hota hai. Defensive read — agar
    // future me format String me badle (ya legacy install pe String ho), wo
    // bhi handle ho jaye. getInt/getString galat type pe throw karte hain,
    // isliye try/catch zaroori hai.
    String id = 'anon';
    try {
      final intId = prefs.getInt(PrefKeys.userId);
      if (intId != null) {
        id = intId.toString();
      } else {
        final strId = prefs.getString(PrefKeys.userId);
        if (strId != null && strId.isNotEmpty) id = strId;
      }
    } catch (_) {
      try {
        final strId = prefs.getString(PrefKeys.userId);
        if (strId != null && strId.isNotEmpty) id = strId;
      } catch (_) {}
    }
    return HistoryWatermarkStore(prefs, id);
  }

  String get _hrKey => '${PrefKeys.lastEmittedHrStampPrefix}$_athleteId';
  String get _rrKey => '${PrefKeys.lastEmittedRrStampPrefix}$_athleteId';
  String get _sleepKey => '${PrefKeys.lastEmittedSleepUtcPrefix}$_athleteId';
  String get _syncAtKey => '${PrefKeys.lastHistorySyncAtPrefix}$_athleteId';
  String get _pushAtKey => '${PrefKeys.lastHistoryPushAtPrefix}$_athleteId';

  int get lastHrStamp => _prefs.getInt(_hrKey) ?? 0;
  int get lastRrStamp => _prefs.getInt(_rrKey) ?? 0;
  int get lastSleepUtc => _prefs.getInt(_sleepKey) ?? 0;

  // Epoch millis of last completed BLE sync. 0 = never synced.
  int get lastSyncAtMs => _prefs.getInt(_syncAtKey) ?? 0;
  DateTime get lastSyncAt =>
      DateTime.fromMillisecondsSinceEpoch(lastSyncAtMs);

  // Epoch millis of last successful server push. 0 = never pushed.
  int get lastPushAtMs => _prefs.getInt(_pushAtKey) ?? 0;
  DateTime get lastPushAt =>
      DateTime.fromMillisecondsSinceEpoch(lastPushAtMs);

  Future<void> commitHr(int stamp) async {
    if (stamp > lastHrStamp) await _prefs.setInt(_hrKey, stamp);
  }

  Future<void> commitRr(int stamp) async {
    if (stamp > lastRrStamp) await _prefs.setInt(_rrKey, stamp);
  }

  Future<void> commitSleep(int utc) async {
    if (utc > lastSleepUtc) await _prefs.setInt(_sleepKey, utc);
  }

  Future<void> commitSyncAtNow() async {
    await _prefs.setInt(_syncAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> commitPushAtNow() async {
    await _prefs.setInt(_pushAtKey, DateTime.now().millisecondsSinceEpoch);
  }
}
