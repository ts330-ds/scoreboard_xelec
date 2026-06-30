import '../entity/daily_hr_summary.dart';
import '../entity/hr_reading.dart';

/// Read/write contract for the SQLite-backed history store.
///
/// This is a *parallel* implementation to the existing Hive store — Hive is
/// left untouched. Data is fed in via the `ingest*` methods (idempotent upserts
/// keyed on the timestamp, so replaying the same data never duplicates), and
/// queried back with indexed range / GROUP BY queries.
abstract class HistorySqlRepository {
  /// Upsert HR readings. Accepts the legacy map shape (`stamp`,`heartRate`).
  /// Returns number of rows written.
  Future<int> ingestHr(List<Map<dynamic, dynamic>> chunk);

  /// Upsert RR samples (`stamp`,`value`).
  Future<int> ingestRr(List<Map<dynamic, dynamic>> chunk);

  /// Upsert sleep sessions (`utc`,`actions`).
  Future<int> ingestSleep(List<Map<dynamic, dynamic>> list);

  /// Per-day HR aggregates, newest day first. Computed in SQL.
  Future<List<DailyHrSummary>> dailySummaries();

  /// HR readings whose stamp (seconds) is within [fromSec, toSec], ascending.
  Future<List<HrReading>> readingsInRange(int fromSec, int toSec);

  /// Total stored HR rows.
  Future<int> hrCount();

  /// Wipe all SQL history (does NOT touch Hive).
  Future<void> clear();
}
