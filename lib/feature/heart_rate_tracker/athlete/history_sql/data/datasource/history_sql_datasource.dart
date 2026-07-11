import 'package:sqflite/sqflite.dart';

import '../../domain/entity/daily_hr_summary.dart';
import '../../domain/entity/hr_reading.dart';
import '../db/history_database.dart';

/// Raw SQL for the history store. All timestamps are normalized to seconds.
class HistorySqlDatasource {
  HistorySqlDatasource._();
  static final HistorySqlDatasource instance = HistorySqlDatasource._();

  final _dbProvider = HistoryDatabase.instance;

  /// Device stamps sometimes arrive in milliseconds (~1.7e12). Normalize to
  /// seconds so keys are consistent with range-query bounds.
  static const int _maxSecondsStamp = 9999999999;
  int _toSec(int stamp) => stamp > _maxSecondsStamp ? stamp ~/ 1000 : stamp;

  int _asInt(dynamic v) => (v as num?)?.toInt() ?? 0;

  // ── Writes ──────────────────────────────────────────────────────────────

  Future<int> upsertHr(List<Map<dynamic, dynamic>> chunk) async {
    if (chunk.isEmpty) return 0;
    final db = await _dbProvider.database;
    final batch = db.batch();
    var n = 0;
    for (final m in chunk) {
      final stamp = _toSec(_asInt(m['stamp']));
      final hr = _asInt(m['heartRate']);
      if (stamp <= 0 || hr <= 0) continue;
      batch.insert(
        'hr_readings',
        {'stamp': stamp, 'heart_rate': hr},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      n++;
    }
    if (n == 0) return 0;
    await batch.commit(noResult: true);
    return n;
  }

  Future<int> upsertRr(List<Map<dynamic, dynamic>> chunk) async {
    if (chunk.isEmpty) return 0;
    final db = await _dbProvider.database;
    final batch = db.batch();
    var n = 0;
    for (final m in chunk) {
      final stamp = _toSec(_asInt(m['stamp']));
      final value = _asInt(m['value']);
      if (stamp <= 0 || value <= 0) continue;
      batch.insert(
        'rr_samples',
        {'stamp': stamp, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      n++;
    }
    if (n == 0) return 0;
    await batch.commit(noResult: true);
    return n;
  }

  Future<int> upsertSleep(List<Map<dynamic, dynamic>> list) async {
    if (list.isEmpty) return 0;
    final db = await _dbProvider.database;
    final batch = db.batch();
    var n = 0;
    for (final m in list) {
      final utc = _toSec(_asInt(m['utc']));
      final raw = m['actions'];
      if (utc <= 0 || raw is! List || raw.isEmpty) continue;
      final actions =
          raw.whereType<num>().map((e) => e.toInt()).join(',');
      if (actions.isEmpty) continue;
      batch.insert(
        'sleep_sessions',
        {'utc': utc, 'actions': actions},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      n++;
    }
    if (n == 0) return 0;
    await batch.commit(noResult: true);
    return n;
  }

  // ── Reads ───────────────────────────────────────────────────────────────

  /// Per-day aggregates grouped in SQL, newest day first.
  Future<List<DailyHrSummary>> dailySummaries() async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery('''
      SELECT
        strftime('%Y-%m-%d', stamp, 'unixepoch', 'localtime') AS day,
        AVG(heart_rate) AS avg_hr,
        MAX(heart_rate) AS max_hr,
        MIN(heart_rate) AS min_hr,
        COUNT(*)        AS cnt
      FROM hr_readings
      WHERE heart_rate > 0
      GROUP BY day
      ORDER BY day DESC
    ''');

    return rows.map((r) {
      final day = r['day'] as String; // 'YYYY-MM-DD'
      final parts = day.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return DailyHrSummary(
        date: date,
        avg: ((r['avg_hr'] as num?) ?? 0).round(),
        max: ((r['max_hr'] as num?) ?? 0).toInt(),
        min: ((r['min_hr'] as num?) ?? 0).toInt(),
        count: ((r['cnt'] as num?) ?? 0).toInt(),
      );
    }).toList();
  }

  /// Indexed range scan — only the matching rows are read, not the whole table.
  Future<List<HrReading>> readingsInRange(int fromSec, int toSec) async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
      '''
      SELECT stamp, heart_rate FROM hr_readings
      WHERE stamp BETWEEN ? AND ? AND heart_rate > 0
      ORDER BY stamp ASC
      ''',
      [fromSec, toSec],
    );
    return rows
        .map((r) => HrReading(
              stampSec: (r['stamp'] as num).toInt(),
              heartRate: (r['heart_rate'] as num).toInt(),
            ))
        .toList();
  }

  Future<int> hrCount() async {
    final db = await _dbProvider.database;
    final res =
        await db.rawQuery('SELECT COUNT(*) AS c FROM hr_readings');
    return (res.first['c'] as num?)?.toInt() ?? 0;
  }

  // ── Full-table reads (for hydration + push) ──────────────────────────────
  // Stamps are stored in SECONDS; these return them in MILLISECONDS so the
  // legacy display utils and the server-push payload (backend expects ms)
  // keep working exactly as they did under the old Hive store.

  Future<List<Map<dynamic, dynamic>>> getAllHr() async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        'SELECT stamp, heart_rate FROM hr_readings ORDER BY stamp ASC');
    return rows
        .map<Map<dynamic, dynamic>>((r) => {
              'stamp': (r['stamp'] as num).toInt() * 1000,
              'heartRate': (r['heart_rate'] as num).toInt(),
            })
        .toList();
  }

  Future<List<Map<dynamic, dynamic>>> getAllRr() async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        'SELECT stamp, value FROM rr_samples ORDER BY stamp ASC');
    return rows
        .map<Map<dynamic, dynamic>>((r) => {
              'stamp': (r['stamp'] as num).toInt() * 1000,
              'value': (r['value'] as num).toInt(),
            })
        .toList();
  }

  Future<List<Map<dynamic, dynamic>>> getAllSleep() async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        'SELECT utc, actions FROM sleep_sessions ORDER BY utc ASC');
    return rows.map<Map<dynamic, dynamic>>((r) {
      final actions = (r['actions'] as String? ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.tryParse(s) ?? 0)
          .toList();
      return {
        'utc': (r['utc'] as num).toInt() * 1000,
        'actions': actions,
      };
    }).toList();
  }

  // ── Sync metadata ─────────────────────────────────────────────────────────

  Future<void> setLastSync(int ms) async {
    final db = await _dbProvider.database;
    await db.insert(
      'sync_meta',
      {'key': 'last_sync_ms', 'value': ms},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> lastSyncMs() async {
    final db = await _dbProvider.database;
    final res = await db.rawQuery(
        "SELECT value FROM sync_meta WHERE key = 'last_sync_ms'");
    return res.isEmpty ? 0 : (res.first['value'] as num?)?.toInt() ?? 0;
  }

  /// Oldest / newest stamp across all streams (ms), and total row count.
  Future<({int oldestMs, int newestMs, int total})> dataBounds() async {
    final db = await _dbProvider.database;
    final res = await db.rawQuery('''
      SELECT MIN(s) AS oldest, MAX(s) AS newest, SUM(c) AS total
      FROM (
        SELECT MIN(stamp) AS s, COUNT(*) AS c FROM hr_readings
        UNION ALL SELECT MAX(stamp), 0 FROM hr_readings
        UNION ALL SELECT MIN(stamp), COUNT(*) FROM rr_samples
        UNION ALL SELECT MAX(stamp), 0 FROM rr_samples
        UNION ALL SELECT MIN(utc),   COUNT(*) FROM sleep_sessions
        UNION ALL SELECT MAX(utc),   0 FROM sleep_sessions
      )
    ''');
    final row = res.first;
    final oldestSec = (row['oldest'] as num?)?.toInt() ?? 0;
    final newestSec = (row['newest'] as num?)?.toInt() ?? 0;
    final total = (row['total'] as num?)?.toInt() ?? 0;
    return (
      oldestMs: oldestSec > 0 ? oldestSec * 1000 : 0,
      newestMs: newestSec > 0 ? newestSec * 1000 : 0,
      total: total,
    );
  }

  Future<void> clear() async {
    final db = await _dbProvider.database;
    final batch = db.batch();
    batch.delete('hr_readings');
    batch.delete('rr_samples');
    batch.delete('sleep_sessions');
    batch.delete('sync_meta');
    // Activity session ka staging table (SessionReadingsStore) — same DB file
    // me hai, logout pe iska pending data bhi per-user hai, wipe karo.
    batch.delete('session_readings');
    await batch.commit(noResult: true);
  }
}
