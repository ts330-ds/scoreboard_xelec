import 'package:hive_flutter/hive_flutter.dart';
import '../models/session_model.dart';

class SessionRepository {
  static const String _boxName = 'sessions';

  Box<SessionModel> get _box => Hive.box<SessionModel>(_boxName);

  // ── WRITE ──────────────────────────────────────────────

  Future<void> saveSession(SessionModel session) async {
    await _box.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  // ── READ ───────────────────────────────────────────────

  /// All sessions, newest first
  List<SessionModel> getAllSessions() {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Last N sessions
  List<SessionModel> getRecentSessions({int limit = 5}) {
    return getAllSessions().take(limit).toList();
  }

  /// Single session by ID
  SessionModel? getSession(String id) => _box.get(id);

  /// Total count
  int get count => _box.length;

  // ── WATCH (reactive) ───────────────────────────────────

  /// Stream of box changes — useful for rebuilding Dashboard live
  Stream<BoxEvent> watchSessions() => _box.watch();
}
