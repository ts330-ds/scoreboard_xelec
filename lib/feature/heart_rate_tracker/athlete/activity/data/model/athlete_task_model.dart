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
  });

  factory AthleteTaskModel.fromJson(Map<String, dynamic> json) =>
      AthleteTaskModel(
        id: json['task_id'] as int? ?? json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        duration: json['duration']?.toString() ?? '',
        assignedBy: json['assigned_by'] as String? ?? 'self',
        assignedByName: json['assigned_by_name'] as String?,
        status: json['status'] as String?,
        assignedAt: json['assigned_at'] as String?,
      );
}
