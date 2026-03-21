import 'package:hive_flutter/hive_flutter.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/test_session_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/trial_result_model.dart';

class SessionRepository {
  static const _boxName = 'sessions';

  Box<TestSessionModel> get _box => Hive.box<TestSessionModel>(_boxName);

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> save(TestSessionModel session) async {
    await _box.put(session.id, session);
  }

  /// Saves a single trial result immediately — called after every trial
  /// so data is not lost on crash or BLE disconnect.
  Future<void> saveTrial({
    required String sessionId,
    required String athleteId,
    required TrialResultModel trial,
  }) async {
    final session = _box.get(sessionId);
    if (session == null) return;

    final updatedResults = session.results.map((r) {
      if (r.athleteId != athleteId) return r;
      final updatedTrials = List<TrialResultModel>.from(r.trials);
      final idx = updatedTrials.indexWhere((t) => t.trialNumber == trial.trialNumber);
      if (idx >= 0) {
        updatedTrials[idx] = trial;
      } else {
        updatedTrials.add(trial);
      }
      return r.copyWith(trials: updatedTrials);
    }).toList();

    await _box.put(sessionId, session.copyWith(results: updatedResults));
  }

  /// Updates queue position — called after every trial so session is resumable.
  Future<void> updateQueueIndex(String sessionId, int index) async {
    final session = _box.get(sessionId);
    if (session == null) return;
    await _box.put(sessionId, session.copyWith(currentQueueIndex: index));
  }

  Future<void> updateStatus(String sessionId, String status) async {
    final session = _box.get(sessionId);
    if (session == null) return;
    await _box.put(
      sessionId,
      session.copyWith(
        status: status,
        completedAt: status == 'completed' ? DateTime.now() : session.completedAt,
      ),
    );
  }

  /// Single atomic write at session completion —
  /// writes ALL in-memory results + status in one go.
  /// More reliable than incremental saveTrial + updateStatus.
  Future<void> finalizeSession({
    required String sessionId,
    required List<AthleteResultModel> results,
    required String status,
  }) async {
    final session = _box.get(sessionId);
    if (session == null) return;
    await _box.put(
      sessionId,
      session.copyWith(
        results: results,
        status: status,
        completedAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateAthleteResults(
    String sessionId,
    List<AthleteResultModel> results,
  ) async {
    final session = _box.get(sessionId);
    if (session == null) return;
    await _box.put(sessionId, session.copyWith(results: results));
  }

  Future<void> delete(String sessionId) async {
    await _box.delete(sessionId);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  TestSessionModel? getById(String id) => _box.get(id);

  List<TestSessionModel> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first
  }

  List<TestSessionModel> getRecent({int limit = 5}) {
    return getAll().take(limit).toList();
  }

  List<TestSessionModel> getByStatus(String status) {
    return getAll().where((s) => s.status == status).toList();
  }

  int get totalCount => _box.length;
}
