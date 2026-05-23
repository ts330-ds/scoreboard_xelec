import 'package:hive/hive.dart';

import 'hr_reading_hive.dart';
import 'rr_sample_hive.dart';
import 'sleep_session_hive.dart';
import 'sync_meta_hive.dart';

/// Hive-backed local store for heart-rate history data.
///
/// Keys are timestamps (stamp / utc), so `put(key, value)` automatically
/// dedupes — replaying the same chunk never creates duplicates.
class HistoryLocalStore {
  HistoryLocalStore._();
  static final HistoryLocalStore instance = HistoryLocalStore._();

  static const _hrBox = 'history_hr';
  static const _rrBox = 'history_rr';
  static const _sleepBox = 'history_sleep';
  static const _metaBox = 'history_meta';

  // Meta keys
  static const metaHr = 'hr';
  static const metaRr = 'rr';
  static const metaSleep = 'sleep';

  late Box<HrReadingHive> _hr;
  late Box<RrSampleHive> _rr;
  late Box<SleepSessionHive> _sleep;
  late Box<SyncMetaHive> _meta;

  bool _opened = false;

  /// Hive box keys must be in 0..0xFFFFFFFF (32-bit unsigned). Some device
  /// stamps arrive in milliseconds (~1.7e12) which overflow that range, so
  /// we normalize the KEY to seconds. The full original stamp is preserved
  /// inside the stored value object.
  static const int _maxSecondsStamp = 9999999999; // ~year 2286 in seconds
  int _keyForStamp(int stamp) =>
      stamp > _maxSecondsStamp ? stamp ~/ 1000 : stamp;

  Future<void> open() async {
    if (_opened) return;
    _hr = await Hive.openBox<HrReadingHive>(_hrBox);
    _rr = await Hive.openBox<RrSampleHive>(_rrBox);
    _sleep = await Hive.openBox<SleepSessionHive>(_sleepBox);
    _meta = await Hive.openBox<SyncMetaHive>(_metaBox);
    _opened = true;
  }

  // ── HR ────────────────────────────────────────────────────────────────────
  Future<int> upsertHrChunk(List<Map<dynamic, dynamic>> chunk) async {
    if (chunk.isEmpty) return 0;
    final entries = <int, HrReadingHive>{};
    for (final m in chunk) {
      final r = HrReadingHive.fromMap(m);
      if (r.stamp <= 0 || r.heartRate <= 0) continue;
      entries[_keyForStamp(r.stamp)] = r;
    }
    if (entries.isEmpty) return 0;
    await _hr.putAll(entries);
    return entries.length;
  }

  List<Map<dynamic, dynamic>> getAllHr() =>
      _hr.values.map((r) => r.toMap()).toList();

  // ── RR ────────────────────────────────────────────────────────────────────
  Future<int> upsertRrChunk(List<Map<dynamic, dynamic>> chunk) async {
    if (chunk.isEmpty) return 0;
    final entries = <int, RrSampleHive>{};
    for (final m in chunk) {
      final r = RrSampleHive.fromMap(m);
      if (r.stamp <= 0 || r.value <= 0) continue;
      entries[_keyForStamp(r.stamp)] = r;
    }
    if (entries.isEmpty) return 0;
    await _rr.putAll(entries);
    return entries.length;
  }

  List<Map<dynamic, dynamic>> getAllRr() =>
      _rr.values.map((r) => r.toMap()).toList();

  // ── Sleep ─────────────────────────────────────────────────────────────────
  Future<int> upsertSleepList(List<Map<dynamic, dynamic>> list) async {
    if (list.isEmpty) return 0;
    final entries = <int, SleepSessionHive>{};
    for (final m in list) {
      final s = SleepSessionHive.fromMap(m);
      if (s.utc <= 0 || s.actions.isEmpty) continue;
      entries[_keyForStamp(s.utc)] = s;
    }
    if (entries.isEmpty) return 0;
    await _sleep.putAll(entries);
    return entries.length;
  }

  List<Map<dynamic, dynamic>> getAllSleep() =>
      _sleep.values.map((s) => s.toMap()).toList();

  // ── Meta ──────────────────────────────────────────────────────────────────
  SyncMetaHive getMeta(String type) =>
      _meta.get(type) ?? SyncMetaHive.empty();

  Future<void> updateMeta(String type) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    int oldest = 0;
    int newest = 0;
    int count = 0;
    switch (type) {
      case metaHr:
        count = _hr.length;
        for (final r in _hr.values) {
          if (oldest == 0 || r.stamp < oldest) oldest = r.stamp;
          if (r.stamp > newest) newest = r.stamp;
        }
        break;
      case metaRr:
        count = _rr.length;
        for (final r in _rr.values) {
          if (oldest == 0 || r.stamp < oldest) oldest = r.stamp;
          if (r.stamp > newest) newest = r.stamp;
        }
        break;
      case metaSleep:
        count = _sleep.length;
        for (final s in _sleep.values) {
          if (oldest == 0 || s.utc < oldest) oldest = s.utc;
          if (s.utc > newest) newest = s.utc;
        }
        break;
    }
    await _meta.put(
      type,
      SyncMetaHive(
        lastSyncMs: now,
        oldestStamp: oldest,
        newestStamp: newest,
        count: count,
      ),
    );
  }

  /// Returns the most-recent stamp across all 3 streams (0 if empty).
  /// Used for the banner — "last sync at" timeline label.
  int get latestKnownStamp {
    final values = <int>[
      getMeta(metaHr).newestStamp,
      getMeta(metaRr).newestStamp,
      getMeta(metaSleep).newestStamp,
    ];
    values.sort();
    return values.last;
  }

  Future<void> clearAll() async {
    await _hr.clear();
    await _rr.clear();
    await _sleep.clear();
    await _meta.clear();
  }
}
