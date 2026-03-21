import 'package:hive/hive.dart';

part 'trial_result_model.g.dart';

@HiveType(typeId: 1)
class TrialResultModel extends HiveObject {
  @HiveField(0)
  String athleteId;

  @HiveField(1)
  String athleteName;

  @HiveField(2)
  int trialNumber; // 1, 2, 3

  @HiveField(3)
  double timeSeconds; // 4.521

  @HiveField(4)
  bool isManualStop; // true if coach tapped stop manually

  @HiveField(5)
  DateTime recordedAt;

  TrialResultModel({
    required this.athleteId,
    required this.athleteName,
    required this.trialNumber,
    required this.timeSeconds,
    this.isManualStop = false,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  String get formattedTime => timeSeconds.toStringAsFixed(3);

  @override
  String toString() =>
      'TrialResult($athleteName · T$trialNumber · ${formattedTime}s)';
}
