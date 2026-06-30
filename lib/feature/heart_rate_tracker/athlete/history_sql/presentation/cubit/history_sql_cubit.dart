import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../history/presentation/widgets/sleep_from_hr.dart'
    show detectSleepFromHr;
import '../../domain/entity/daily_hr_summary.dart';
import '../../domain/repository/history_sql_repository.dart';
import 'history_sql_state.dart';

/// Drives the SQL-backed history screen.
///
/// Data is *ingested* from the in-memory lists the BLE cubit already exposes
/// (which themselves come from Hive) — so Hive stays the source of truth and is
/// never touched. SQLite is used purely as an indexed, query-optimized
/// projection: tabs/stats come from a GROUP BY, per-day data from a range scan.
class HistorySqlCubit extends Cubit<HistorySqlState> {
  final HistorySqlRepository repo;
  HistorySqlCubit(this.repo) : super(const HistorySqlState());

  // Guards against overlapping refresh() runs (e.g. rapid sync chunks).
  bool _busy = false;
  bool _again = false;

  int _sec(DateTime dt) => dt.millisecondsSinceEpoch ~/ 1000;

  /// Ingest the latest in-memory history into SQLite, then reload summaries +
  /// the selected day. Idempotent — upserts dedupe on timestamp.
  Future<void> refresh(
    List<Map<dynamic, dynamic>> hr,
    List<Map<dynamic, dynamic>> rr,
    List<Map<dynamic, dynamic>> sleep,
  ) async {
    if (_busy) {
      _again = true;
      return;
    }
    _busy = true;
    try {
      await repo.ingestHr(hr);
      await repo.ingestRr(rr);
      await repo.ingestSleep(sleep);

      final summaries = await repo.dailySummaries();
      var idx = state.selectedIdx;
      if (idx >= summaries.length) {
        idx = summaries.isEmpty ? 0 : summaries.length - 1;
      }
      emit(state.copyWith(
        loading: false,
        summaries: summaries,
        selectedIdx: idx,
      ));
      await _loadDay(idx, summaries);
    } finally {
      _busy = false;
      if (_again) {
        _again = false;
        await refresh(hr, rr, sleep);
      }
    }
  }

  Future<void> selectDay(int i) async {
    if (i == state.selectedIdx) return;
    emit(state.copyWith(selectedIdx: i));
    await _loadDay(i, state.summaries);
  }

  Future<void> _loadDay(int idx, List<DailyHrSummary> summaries) async {
    if (summaries.isEmpty || idx < 0 || idx >= summaries.length) {
      emit(state.copyWith(dayReadings: const [], clearSleep: true));
      return;
    }
    final date = summaries[idx].date;

    // Day's own readings for the chart.
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final dayRows = await repo.readingsInRange(_sec(dayStart), _sec(dayEnd));
    final dayMaps = dayRows.map((r) => r.toLegacyMap()).toList();

    // Overnight window (prev day 21:00 → day 09:00) for sleep detection.
    final winStart = DateTime(date.year, date.month, date.day - 1, 21);
    final winEnd = DateTime(date.year, date.month, date.day, 9);
    final winRows = await repo.readingsInRange(_sec(winStart), _sec(winEnd));
    final sleep = detectSleepFromHr(
      winRows.map((r) => r.toLegacyMap()).toList(),
      date,
    );

    emit(state.copyWith(
      dayReadings: dayMaps,
      sleep: sleep,
      clearSleep: sleep == null,
    ));
  }
}
