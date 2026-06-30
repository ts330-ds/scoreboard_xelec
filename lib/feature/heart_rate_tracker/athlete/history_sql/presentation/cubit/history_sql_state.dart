import 'package:equatable/equatable.dart';

import '../../../history/presentation/widgets/sleep_from_hr.dart' show SleepResult;
import '../../domain/entity/daily_hr_summary.dart';

class HistorySqlState extends Equatable {
  /// True until the first ingest+load completes.
  final bool loading;

  /// Per-day aggregates (newest first) — powers tabs + stat cards.
  final List<DailyHrSummary> summaries;

  /// Index into [summaries] of the currently viewed day.
  final int selectedIdx;

  /// HR readings of the selected day (legacy map shape) for the chart.
  final List<Map<dynamic, dynamic>> dayReadings;

  /// Sleep derived from the selected day's overnight window, if any.
  final SleepResult? sleep;

  const HistorySqlState({
    this.loading = true,
    this.summaries = const [],
    this.selectedIdx = 0,
    this.dayReadings = const [],
    this.sleep,
  });

  DailyHrSummary? get selected =>
      (selectedIdx >= 0 && selectedIdx < summaries.length)
          ? summaries[selectedIdx]
          : null;

  HistorySqlState copyWith({
    bool? loading,
    List<DailyHrSummary>? summaries,
    int? selectedIdx,
    List<Map<dynamic, dynamic>>? dayReadings,
    SleepResult? sleep,
    bool clearSleep = false,
  }) {
    return HistorySqlState(
      loading: loading ?? this.loading,
      summaries: summaries ?? this.summaries,
      selectedIdx: selectedIdx ?? this.selectedIdx,
      dayReadings: dayReadings ?? this.dayReadings,
      sleep: clearSleep ? null : (sleep ?? this.sleep),
    );
  }

  @override
  List<Object?> get props =>
      [loading, summaries, selectedIdx, dayReadings, sleep];
}
