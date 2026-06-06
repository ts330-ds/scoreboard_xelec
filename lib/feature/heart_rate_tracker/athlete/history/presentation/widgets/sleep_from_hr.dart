import 'dart:math' as math;

import 'history_data_utils.dart';

/// Sleep stage codes (same as Chileaf SDK convention).
class SleepStage {
  static const int deep = 1;
  static const int light = 2;
  static const int rem = 3;
  static const int awake = 4;

  static String label(int code) {
    switch (code) {
      case deep:
        return 'Deep';
      case light:
        return 'Light';
      case rem:
        return 'REM';
      case awake:
        return 'Awake';
      default:
        return '';
    }
  }
}

class SleepMinute {
  final DateTime time;
  final int hr;
  final int stage;
  const SleepMinute({required this.time, required this.hr, required this.stage});
}

class SleepResult {
  final List<SleepMinute> minutes;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int totalMin;
  final int deepMin;
  final int lightMin;
  final int remMin;
  final int awakeMin;

  const SleepResult({
    required this.minutes,
    required this.bedTime,
    required this.wakeTime,
    required this.totalMin,
    required this.deepMin,
    required this.lightMin,
    required this.remMin,
    required this.awakeMin,
  });

  String get totalLabel => _fmtMin(totalMin);
  String get deepLabel => _fmtMin(deepMin);
  String get lightLabel => _fmtMin(lightMin);
  String get remLabel => _fmtMin(remMin);
  String get awakeLabel => _fmtMin(awakeMin);

  int get deepPct => totalMin > 0 ? (deepMin * 100 / totalMin).round() : 0;
  int get lightPct => totalMin > 0 ? (lightMin * 100 / totalMin).round() : 0;
  int get remPct => totalMin > 0 ? (remMin * 100 / totalMin).round() : 0;
  int get awakePct => totalMin > 0 ? (awakeMin * 100 / totalMin).round() : 0;

  static String _fmtMin(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    if (h == 0) return '${min}m';
    if (min == 0) return '${h}h';
    return '${h}h ${min}m';
  }
}

/// Detects sleep from overnight HR readings.
///
/// [allHrData] — full HR history from Hive (all days).
/// [targetDate] — the "morning" date. Sleep window = previous day 21:00 → targetDate 09:00.
///
/// Algorithm:
///  1. Extract overnight HR window (9 PM → 9 AM).
///  2. Resample to per-minute averages.
///  3. Calculate resting HR baseline (10th percentile of the window).
///  4. Per-minute: compute 5-min rolling HR mean + variance.
///  5. Classify stage based on HR delta from baseline + variance:
///       - Deep:  HR within baseline+5, low variance (<15)
///       - Light: HR within baseline+12, moderate variance
///       - REM:   high variance (>20) regardless of HR level
///       - Awake: HR > baseline+15 or sudden spike
///  6. Smooth: remove single-minute flips (median filter).
///  7. Trim leading/trailing awake epochs to find bed/wake time.
SleepResult? detectSleepFromHr(
  List<Map<dynamic, dynamic>> allHrData,
  DateTime targetDate,
) {
  // Overnight window: previous day 21:00 → target day 09:00
  final windowStart = DateTime(
      targetDate.year, targetDate.month, targetDate.day - 1, 21, 0);
  final windowEnd = DateTime(
      targetDate.year, targetDate.month, targetDate.day, 9, 0);

  // Filter readings in window
  final overnightReadings = <({int ms, int hr})>[];
  for (final r in allHrData) {
    final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
    final hr = (r['heartRate'] as num?)?.toInt() ?? 0;
    if (stamp <= 0 || hr <= 0) continue;
    final dt = stampToDateTime(stamp);
    if (dt.isAfter(windowStart) && dt.isBefore(windowEnd)) {
      final ms = dt.millisecondsSinceEpoch;
      overnightReadings.add((ms: ms, hr: hr));
    }
  }

  // Need at least 60 readings (~1 hour) to detect sleep
  if (overnightReadings.length < 60) return null;

  overnightReadings.sort((a, b) => a.ms.compareTo(b.ms));

  // Resample to per-minute buckets
  final minuteBuckets = <int, List<int>>{};
  for (final r in overnightReadings) {
    final minuteKey = r.ms ~/ 60000;
    minuteBuckets.putIfAbsent(minuteKey, () => []).add(r.hr);
  }

  final minuteKeys = minuteBuckets.keys.toList()..sort();
  if (minuteKeys.length < 30) return null;

  final minuteHr = <int, int>{};
  for (final k in minuteKeys) {
    final vals = minuteBuckets[k]!;
    minuteHr[k] = (vals.reduce((a, b) => a + b) / vals.length).round();
  }

  // Calculate baseline (10th percentile = deep sleep HR level)
  final sortedHr = minuteHr.values.toList()..sort();
  final p10Index = (sortedHr.length * 0.10).floor().clamp(0, sortedHr.length - 1);
  final baseline = sortedHr[p10Index].toDouble();

  // Per-minute classification with rolling window
  const windowSize = 5;
  final stages = <int, int>{};

  for (int i = 0; i < minuteKeys.length; i++) {
    final k = minuteKeys[i];
    final hr = minuteHr[k]!;

    // Collect rolling window values
    final windowVals = <int>[];
    for (int j = math.max(0, i - windowSize ~/ 2);
        j <= math.min(minuteKeys.length - 1, i + windowSize ~/ 2);
        j++) {
      windowVals.add(minuteHr[minuteKeys[j]]!);
    }

    final mean =
        windowVals.reduce((a, b) => a + b) / windowVals.length;
    final variance = windowVals.length > 1
        ? windowVals
                .map((v) => (v - mean) * (v - mean))
                .reduce((a, b) => a + b) /
            (windowVals.length - 1)
        : 0.0;

    final delta = hr - baseline;

    int stage;
    if (delta > 18 || hr > baseline + 20) {
      stage = SleepStage.awake;
    } else if (variance > 25) {
      stage = SleepStage.rem;
    } else if (delta <= 6 && variance < 15) {
      stage = SleepStage.deep;
    } else {
      stage = SleepStage.light;
    }

    stages[k] = stage;
  }

  // Median filter (3-wide) to smooth single-minute flips
  final smoothed = <int, int>{};
  for (int i = 0; i < minuteKeys.length; i++) {
    final k = minuteKeys[i];
    if (i == 0 || i == minuteKeys.length - 1) {
      smoothed[k] = stages[k]!;
      continue;
    }
    final prev = stages[minuteKeys[i - 1]]!;
    final curr = stages[k]!;
    final next = stages[minuteKeys[i + 1]]!;
    if (prev == next && curr != prev) {
      smoothed[k] = prev;
    } else {
      smoothed[k] = curr;
    }
  }

  // Trim leading/trailing awake to find actual bed/wake time
  int bedIdx = 0;
  for (int i = 0; i < minuteKeys.length; i++) {
    if (smoothed[minuteKeys[i]] != SleepStage.awake) {
      bedIdx = i;
      break;
    }
  }

  int wakeIdx = minuteKeys.length - 1;
  for (int i = minuteKeys.length - 1; i >= 0; i--) {
    if (smoothed[minuteKeys[i]] != SleepStage.awake) {
      wakeIdx = i;
      break;
    }
  }

  if (wakeIdx <= bedIdx) return null;

  final sleepMinutes = <SleepMinute>[];
  int deepMin = 0, lightMin = 0, remMin = 0, awakeMin = 0;

  for (int i = bedIdx; i <= wakeIdx; i++) {
    final k = minuteKeys[i];
    final stage = smoothed[k]!;
    sleepMinutes.add(SleepMinute(
      time: DateTime.fromMillisecondsSinceEpoch(k * 60000),
      hr: minuteHr[k]!,
      stage: stage,
    ));
    switch (stage) {
      case SleepStage.deep:
        deepMin++;
      case SleepStage.light:
        lightMin++;
      case SleepStage.rem:
        remMin++;
      case SleepStage.awake:
        awakeMin++;
    }
  }

  if (sleepMinutes.length < 30) return null;

  return SleepResult(
    minutes: sleepMinutes,
    bedTime: sleepMinutes.first.time,
    wakeTime: sleepMinutes.last.time,
    totalMin: sleepMinutes.length,
    deepMin: deepMin,
    lightMin: lightMin,
    remMin: remMin,
    awakeMin: awakeMin,
  );
}
