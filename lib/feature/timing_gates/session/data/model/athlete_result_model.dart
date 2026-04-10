import 'package:hive/hive.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/trial_result_model.dart';

part 'athlete_result_model.g.dart';

@HiveType(typeId: 2)
class AthleteResultModel {
  /// Reference to AthleteModel.id
  @HiveField(0)
  final String athleteId;

  /// Snapshots taken at session creation time — independent of Hive athlete record
  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String bib;

  @HiveField(3)
  final String team;

  @HiveField(4)
  final String discipline;

  @HiveField(5)
  final List<TrialResultModel> trials;

  /// For shuttle mode: which lane this athlete is assigned to (1/2/3)
  @HiveField(6)
  final int? shuttleLane;

  const AthleteResultModel({
    required this.athleteId,
    required this.fullName,
    this.bib = '',
    this.team = '',
    this.discipline = '',
    this.trials = const [],
    this.shuttleLane,
  });

  List<TrialResultModel> get completedTrials =>
      trials.where((t) => t.isCompleted).toList();

  double? get bestTime {
    // Safe: filter out null totalTime to prevent crash
    final times = completedTrials
        .where((t) => t.totalTime != null)
        .map((t) => t.totalTime!)
        .toList();
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a < b ? a : b);
  }

  double? get avgTime {
    // Safe: filter out null totalTime to prevent crash
    final times = completedTrials
        .where((t) => t.totalTime != null)
        .map((t) => t.totalTime!)
        .toList();
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a + b) / times.length;
  }

  AthleteResultModel copyWith({
    String? athleteId,
    String? fullName,
    String? bib,
    String? team,
    String? discipline,
    List<TrialResultModel>? trials,
    int? shuttleLane,
  }) {
    return AthleteResultModel(
      athleteId: athleteId ?? this.athleteId,
      fullName: fullName ?? this.fullName,
      bib: bib ?? this.bib,
      team: team ?? this.team,
      discipline: discipline ?? this.discipline,
      trials: trials ?? this.trials,
      shuttleLane: shuttleLane ?? this.shuttleLane,
    );
  }
}
