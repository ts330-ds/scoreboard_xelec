class AthleteTaskEntity {
  final int id;
  final String name;
  final String duration;
  final String assignedBy;
  final String? assignedByName;
  final String? status;
  final String? assignedAt;

  /// In-progress session ka server-side start time (ISO). App-kill ke baad
  /// resume pe accurate elapsed nikaalne ke liye. Sirf running task pe aata hai.
  final String? startedAt;

  const AthleteTaskEntity({
    required this.id,
    required this.name,
    required this.duration,
    required this.assignedBy,
    this.assignedByName,
    this.status,
    this.assignedAt,
    this.startedAt,
  });
}
