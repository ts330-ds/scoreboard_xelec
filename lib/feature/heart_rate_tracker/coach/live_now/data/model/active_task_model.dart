import '../../domain/entity/active_task_entity.dart';

class ActiveTaskModel extends ActiveTaskEntity {
  const ActiveTaskModel({
    required super.taskId,
    required super.taskName,
    required super.athleteId,
    required super.athleteName,
    required super.status,
    super.duration,
    super.startedAt,
  });

  factory ActiveTaskModel.fromJson(Map<String, dynamic> json) {
    return ActiveTaskModel(
      taskId: _toInt(json['task_id']) ?? 0,
      taskName: json['name']?.toString() ?? 'Unnamed Task',
      athleteId: _toInt(json['athlete_id']) ?? 0,
      athleteName: json['athlete_name']?.toString() ?? 'Unknown Athlete',
      status: json['status']?.toString() ?? 'in_progress',
      duration: _toInt(json['duration']),
      startedAt: json['assigned_at']?.toString(),
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
