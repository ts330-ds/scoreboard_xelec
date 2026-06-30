import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the single SQLite connection for the history feature.
///
/// Schema is intentionally tiny + indexed-by-timestamp so range queries
/// (`WHERE stamp BETWEEN ?`) and per-day aggregation (`GROUP BY day`) run in
/// the engine instead of in Dart. Timestamps are stored in **seconds** so the
/// integer primary key both dedupes and stays well within range.
class HistoryDatabase {
  HistoryDatabase._();
  static final HistoryDatabase instance = HistoryDatabase._();

  static const _dbName = 'history_sql.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final opened = await _open();
    _db = opened;
    return opened;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE hr_readings (
            stamp INTEGER PRIMARY KEY,
            heart_rate INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE rr_samples (
            stamp INTEGER PRIMARY KEY,
            value INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sleep_sessions (
            utc INTEGER PRIMARY KEY,
            actions TEXT NOT NULL
          )
        ''');
        await _createSyncMeta(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        // v1 → v2: sync metadata moved out of Hive into this DB.
        if (oldVersion < 2) await _createSyncMeta(db);
      },
    );
  }

  /// Single-row key/value table holding history sync metadata
  /// (currently just the last successful sync time, in ms).
  Future<void> _createSyncMeta(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_meta (
        key TEXT PRIMARY KEY,
        value INTEGER NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
