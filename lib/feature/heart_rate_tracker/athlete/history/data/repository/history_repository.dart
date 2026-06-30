import '../../../history_sql/data/datasource/history_sql_datasource.dart';
import '../../../history_sql/domain/entity/hr_reading.dart';

class HistoryHydration {
  final List<Map<dynamic, dynamic>> hr;
  final List<Map<dynamic, dynamic>> rr;
  final List<Map<dynamic, dynamic>> sleep;
  const HistoryHydration({
    required this.hr,
    required this.rr,
    required this.sleep,
  });

  static const empty = HistoryHydration(hr: [], rr: [], sleep: []);
}

/// Sync metadata surfaced to the UI (e.g. SyncStatusBanner).
class HistorySyncMeta {
  final int latestSyncMs;
  final int oldestStamp;
  final int newestStamp;
  final int totalCount;
  const HistorySyncMeta({
    this.latestSyncMs = 0,
    this.oldestStamp = 0,
    this.newestStamp = 0,
    this.totalCount = 0,
  });
}

/// App-facing history store. Backed entirely by SQLite (sqflite) — Hive is no
/// longer used for history. The same SQLite DB also powers the SQL history
/// screen, so there is a single source of truth.
class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository instance = HistoryRepository._();

  final _ds = HistorySqlDatasource.instance;

  /// Read all persisted data — used by HeartBleCubit on init / hydration.
  Future<HistoryHydration> hydrate() async => HistoryHydration(
        hr: await _ds.getAllHr(),
        rr: await _ds.getAllRr(),
        sleep: await _ds.getAllSleep(),
      );

  /// Persist incoming HR chunk; dedupes by stamp. Returns inserted/updated count.
  Future<int> persistHrChunk(List<Map<dynamic, dynamic>> chunk) =>
      _ds.upsertHr(chunk);

  Future<int> persistRrChunk(List<Map<dynamic, dynamic>> chunk) =>
      _ds.upsertRr(chunk);

  Future<int> persistSleep(List<Map<dynamic, dynamic>> list) =>
      _ds.upsertSleep(list);

  /// HR readings within [fromMs, toMs] — indexed range scan in SQL.
  /// Used by the activity task-upload flows to attach a session's readings.
  Future<List<HrReading>> hrInRange(int fromMs, int toMs) =>
      _ds.readingsInRange(fromMs ~/ 1000, toMs ~/ 1000);

  /// Record that a sync just completed — call once after sync completes.
  Future<void> updateAllMeta() =>
      _ds.setLastSync(DateTime.now().millisecondsSinceEpoch);

  Future<HistorySyncMeta> getMeta() async {
    final lastSync = await _ds.lastSyncMs();
    final bounds = await _ds.dataBounds();
    return HistorySyncMeta(
      latestSyncMs: lastSync,
      oldestStamp: bounds.oldestMs,
      newestStamp: bounds.newestMs,
      totalCount: bounds.total,
    );
  }

  Future<void> clearAll() => _ds.clear();
}
