class ActiveTaskEntity {
  final int taskId;
  final String taskName;
  final int athleteId;
  final String athleteName;
  final String status;
  final int? duration;
  final String? startedAt;

  const ActiveTaskEntity({
    required this.taskId,
    required this.taskName,
    required this.athleteId,
    required this.athleteName,
    required this.status,
    this.duration,
    this.startedAt,
  });
}
