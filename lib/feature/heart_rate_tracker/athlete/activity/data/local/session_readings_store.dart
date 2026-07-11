import 'package:sqflite/sqflite.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history_sql/data/db/history_database.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history_sql/domain/entity/hr_reading.dart';

/// Session upload ka staging store — `session_readings` table (per task).
///
/// Activity session ka BLE-fetched data health-history tables me NAHI jaata;
/// yahan task_id ke against store hota hai taaki:
///   • app kill / upload fail ke baad bhi retry SQLite se ho sake (band ke
///     bina), aur
///   • successful upload ke baad data clear ho jaaye — history DB session
///     readings se pollute na ho.
class SessionReadingsStore {
  SessionReadingsStore._();
  static final SessionReadingsStore instance = SessionReadingsStore._();

  final _dbProvider = HistoryDatabase.instance;

  /// Device stamps kabhi ms (~1.7e12) me aate hain — seconds me normalize.
  static const int _maxSecondsStamp = 9999999999;
  int _toSec(int stamp) => stamp > _maxSecondsStamp ? stamp ~/ 1000 : stamp;

  int _asInt(dynamic v) => (v as num?)?.toInt() ?? 0;

  /// BLE fetch ka HR chunk task ke against upsert karta hai (stamp-dedupe).
  Future<int> saveForTask(int taskId, List<Map<dynamic, dynamic>> chunk) async {
    if (chunk.isEmpty) return 0;
    final db = await _dbProvider.database;
    final batch = db.batch();
    var n = 0;
    for (final m in chunk) {
      final stamp = _toSec(_asInt(m['stamp']));
      final hr = _asInt(m['heartRate']);
      if (stamp <= 0 || hr <= 0) continue;
      batch.insert(
        'session_readings',
        {'task_id': taskId, 'stamp': stamp, 'heart_rate': hr},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      n++;
    }
    if (n == 0) return 0;
    await batch.commit(noResult: true);
    return n;
  }

  /// Task ke saare pending readings, stamp-ascending.
  Future<List<HrReading>> readForTask(int taskId) async {
    final db = await _dbProvider.database;
    final rows = await db.query(
      'session_readings',
      columns: ['stamp', 'heart_rate'],
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'stamp ASC',
    );
    return rows
        .map((r) => HrReading(
              stampSec: (r['stamp'] as num).toInt(),
              heartRate: (r['heart_rate'] as num).toInt(),
            ))
        .toList();
  }

  /// Successful upload ke baad task ka staging data hata do.
  Future<void> clearTask(int taskId) async {
    final db = await _dbProvider.database;
    await db.delete('session_readings', where: 'task_id = ?', whereArgs: [taskId]);
  }

  /// Logout — saare pending session readings wipe (per-user data).
  Future<void> clearAll() async {
    final db = await _dbProvider.database;
    await db.delete('session_readings');
  }
}
