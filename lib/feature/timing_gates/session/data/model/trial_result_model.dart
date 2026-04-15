import 'package:hive/hive.dart';

part 'trial_result_model.g.dart';

@HiveType(typeId: 1)
class TrialResultModel {
  @HiveField(0)
  final int trialNumber; // 1-based

  @HiveField(1)
  final double? totalTime; // seconds — null = pending or invalid

  /// Gate-to-gate split times (linear/sprint mode only).
  /// splits[0] = start→gate1, splits[1] = gate1→gate2, etc.
  @HiveField(2)
  final List<double> splits;

  /// Shuttle lane number (1 / 2 / 3). Null for non-shuttle modes.
  @HiveField(3)
  final int? lane;

  /// 'pending' | 'completed' | 'false_start' | 'skipped'
  @HiveField(4)
  final String status;

  @HiveField(5)
  final DateTime? timestamp;

  /// Per-segment speeds in m/s (sprint mode only).
  /// speeds[i] = distance_i / time_i for each gate-to-gate segment.
  @HiveField(6)
  final List<double> speeds;

  /// Per-segment accelerations in m/s² (sprint mode only).
  /// accelerations[i] maps directly to speeds[i] — one value per segment.
  /// accelerations[0] = speeds[0] / segTime[0]  (athlete starts from rest, v=0)
  /// accelerations[i] = (speeds[i] - speeds[i-1]) / segTime[i]  for i > 0
  @HiveField(7)
  final List<double> accelerations;

  /// YoYo only: level string at which the 1st strike was received (e.g. "11.0").
  @HiveField(8)
  final String? firstStrikeLevel;

  /// YoYo only: level string at which the 2nd (final) strike was received / athlete
  /// was eliminated (e.g. "12.3"). Null for athletes who survived.
  @HiveField(9)
  final String? secondStrikeLevel;

  const TrialResultModel({
    required this.trialNumber,
    this.totalTime,
    this.splits = const [],
    this.lane,
    this.status = 'pending',
    this.timestamp,
    this.speeds = const [],
    this.accelerations = const [],
    this.firstStrikeLevel,
    this.secondStrikeLevel,
  });

  bool get isCompleted => status == 'completed' && totalTime != null;
  bool get isPending => status == 'pending';
  bool get isSkipped => status == 'skipped';
  bool get isFalseStart => status == 'false_start';

  TrialResultModel copyWith({
    int? trialNumber,
    double? totalTime,
    List<double>? splits,
    int? lane,
    String? status,
    DateTime? timestamp,
    List<double>? speeds,
    List<double>? accelerations,
    String? firstStrikeLevel,
    String? secondStrikeLevel,
  }) {
    return TrialResultModel(
      trialNumber: trialNumber ?? this.trialNumber,
      totalTime: totalTime ?? this.totalTime,
      splits: splits ?? this.splits,
      lane: lane ?? this.lane,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      speeds: speeds ?? this.speeds,
      accelerations: accelerations ?? this.accelerations,
      firstStrikeLevel: firstStrikeLevel ?? this.firstStrikeLevel,
      secondStrikeLevel: secondStrikeLevel ?? this.secondStrikeLevel,
    );
  }

  double? get peakSpeed => speeds.isEmpty ? null : speeds.reduce((a, b) => a > b ? a : b);
  double? get peakAcceleration => accelerations.isEmpty ? null : accelerations.reduce((a, b) => a > b ? a : b);
}
