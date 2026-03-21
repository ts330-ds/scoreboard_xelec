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

  const TrialResultModel({
    required this.trialNumber,
    this.totalTime,
    this.splits = const [],
    this.lane,
    this.status = 'pending',
    this.timestamp,
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
  }) {
    return TrialResultModel(
      trialNumber: trialNumber ?? this.trialNumber,
      totalTime: totalTime ?? this.totalTime,
      splits: splits ?? this.splits,
      lane: lane ?? this.lane,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
