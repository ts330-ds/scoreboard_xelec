import '../../domain/entity/athlete_task_entity.dart';

class AthleteTaskModel extends AthleteTaskEntity {
  const AthleteTaskModel({
    required super.id,
    required super.name,
    required super.duration,
    required super.assignedBy,
    super.assignedByName,
    super.status,
    super.assignedAt,
    super.startedAt,
  });

  factory AthleteTaskModel.fromJson(Map<String, dynamic> json) {
    final id = json['task_id'] as int? ?? json['id'] as int?;
    if (id == null || id <= 0) {
      throw FormatException('Invalid task id in response: ${json['task_id'] ?? json['id']}');
    }
    return AthleteTaskModel(
        id: id,
        name: json['name'] as String? ?? '',
        duration: json['duration']?.toString() ?? '',
        assignedBy: json['assigned_by'] as String? ?? 'self',
        assignedByName: json['assigned_by_name'] as String?,
        status: json['status'] as String?,
        assignedAt: json['assigned_at'] as String?,
        startedAt: json['started_at'] as String?,
      );
  }
}
