class AthleteTaskEntity {
  final int id;
  final String name;
  final String duration;
  final String assignedBy;
  final String? assignedByName;
  final String? status;
  final String? assignedAt;

  const AthleteTaskEntity({
    required this.id,
    required this.name,
    required this.duration,
    required this.assignedBy,
    this.assignedByName,
    this.status,
    this.assignedAt,
  });
}
