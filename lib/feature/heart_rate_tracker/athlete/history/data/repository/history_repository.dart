import '../local/history_local_store.dart';
import '../local/sync_meta_hive.dart';

class HistoryHydration {
  final List<Map<dynamic, dynamic>> hr;
  final List<Map<dynamic, dynamic>> rr;
  final List<Map<dynamic, dynamic>> sleep;
  const HistoryHydration({
    required this.hr,
    required this.rr,
    required this.sleep,
  });
}

class HistorySyncMeta {
  final SyncMetaHive hr;
  final SyncMetaHive rr;
  final SyncMetaHive sleep;
  const HistorySyncMeta({
    required this.hr,
    required this.rr,
    required this.sleep,
  });

  int get latestSyncMs {
    final values = [hr.lastSyncMs, rr.lastSyncMs, sleep.lastSyncMs];
    values.sort();
    return values.last;
  }

  int get oldestStamp {
    final values = [hr.oldestStamp, rr.oldestStamp, sleep.oldestStamp]
        .where((v) => v > 0)
        .toList()
      ..sort();
    return values.isEmpty ? 0 : values.first;
  }

  int get newestStamp {
    final values = [hr.newestStamp, rr.newestStamp, sleep.newestStamp];
    values.sort();
    return values.last;
  }

  int get totalCount => hr.count + rr.count + sleep.count;
}

class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository instance = HistoryRepository._();

  final _store = HistoryLocalStore.instance;

  /// Read all persisted data — used by HeartBleCubit on init / hydration.
  HistoryHydration hydrate() => HistoryHydration(
        hr: _store.getAllHr(),
        rr: _store.getAllRr(),
        sleep: _store.getAllSleep(),
      );

  /// Persist incoming HR chunk; dedupes by stamp. Returns inserted/updated count.
  Future<int> persistHrChunk(List<Map<dynamic, dynamic>> chunk) async {
    final n = await _store.upsertHrChunk(chunk);
    if (n > 0) await _store.updateMeta(HistoryLocalStore.metaHr);
    return n;
  }

  Future<int> persistRrChunk(List<Map<dynamic, dynamic>> chunk) async {
    final n = await _store.upsertRrChunk(chunk);
    if (n > 0) await _store.updateMeta(HistoryLocalStore.metaRr);
    return n;
  }

  Future<int> persistSleep(List<Map<dynamic, dynamic>> list) async {
    final n = await _store.upsertSleepList(list);
    if (n > 0) await _store.updateMeta(HistoryLocalStore.metaSleep);
    return n;
  }

  HistorySyncMeta getMeta() => HistorySyncMeta(
        hr: _store.getMeta(HistoryLocalStore.metaHr),
        rr: _store.getMeta(HistoryLocalStore.metaRr),
        sleep: _store.getMeta(HistoryLocalStore.metaSleep),
      );

  Future<void> clearAll() => _store.clearAll();
}
