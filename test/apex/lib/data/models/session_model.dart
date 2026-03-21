import 'package:hive/hive.dart';
import 'athlete_model.dart';
import 'trial_result_model.dart';

part 'session_model.g.dart';

@HiveType(typeId: 2)
class SessionModel extends HiveObject {
  @HiveField(0)
  String id; // UUID

  @HiveField(1)
  String testName; // "40m Sprint Pre-Season 2026"

  @HiveField(2)
  String protocol; // "40m", "505", "t-test" etc.

  @HiveField(3)
  double distanceMeters; // 40.0

  @HiveField(4)
  String location; // "National Stadium"

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String layoutDiagram; // "linear", "t-test", "flying", "505"

  @HiveField(7)
  String triggerMode; // "auto", "manual", "remote", "sound"

  @HiveField(8)
  int falseStartThresholdMs; // 100

  @HiveField(9)
  int resetDelaySeconds; // 5

  @HiveField(10)
  List<AthleteModel> athletes;

  @HiveField(11)
  List<TrialResultModel> results;

  @HiveField(12)
  DateTime createdAt;

  SessionModel({
    required this.id,
    required this.testName,
    required this.protocol,
    required this.distanceMeters,
    required this.location,
    required this.date,
    required this.layoutDiagram,
    required this.triggerMode,
    required this.falseStartThresholdMs,
    required this.resetDelaySeconds,
    required this.athletes,
    required this.results,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Best time across all trials
  double? get bestTime {
    if (results.isEmpty) return null;
    return results
        .map((r) => r.timeSeconds)
        .reduce((a, b) => a < b ? a : b);
  }

  // Best time athlete name
  String? get bestAthliteName {
    if (results.isEmpty) return null;
    final best = results.reduce((a, b) => a.timeSeconds < b.timeSeconds ? a : b);
    return best.athleteName;
  }

  // Results grouped by athlete
  Map<String, List<TrialResultModel>> get resultsByAthlete {
    final map = <String, List<TrialResultModel>>{};
    for (final r in results) {
      map.putIfAbsent(r.athleteId, () => []).add(r);
    }
    return map;
  }

  // Leaderboard: athletes sorted by best time
  List<_AthleteLeaderboardEntry> get leaderboard {
    final entries = <_AthleteLeaderboardEntry>[];

    for (final athlete in athletes) {
      final athleteResults = results
          .where((r) => r.athleteId == athlete.id)
          .toList();
      if (athleteResults.isEmpty) continue;

      final times = athleteResults.map((r) => r.timeSeconds).toList();
      final best = times.reduce((a, b) => a < b ? a : b);
      final avg = times.reduce((a, b) => a + b) / times.length;

      entries.add(_AthleteLeaderboardEntry(
        athlete: athlete,
        trials: athleteResults,
        bestTime: best,
        avgTime: avg,
      ));
    }

    entries.sort((a, b) => a.bestTime.compareTo(b.bestTime));
    return entries;
  }

  @override
  String toString() => 'Session($testName · $protocol · ${athletes.length} athletes)';
}

class _AthleteLeaderboardEntry {
  final AthleteModel athlete;
  final List<TrialResultModel> trials;
  final double bestTime;
  final double avgTime;

  _AthleteLeaderboardEntry({
    required this.athlete,
    required this.trials,
    required this.bestTime,
    required this.avgTime,
  });
}
