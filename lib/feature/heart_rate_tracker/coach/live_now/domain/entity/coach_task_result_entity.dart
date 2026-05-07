double _toDouble(dynamic v) =>
    v == null ? 0.0 : v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;

class StatRange {
  final double avg;
  final double min;
  final double max;

  const StatRange({required this.avg, required this.min, required this.max});

  factory StatRange.fromJson(Map<String, dynamic> json) => StatRange(
        avg: _toDouble(json['avg']),
        min: _toDouble(json['min']),
        max: _toDouble(json['max']),
      );
}

class AggregatedStats {
  final StatRange heartRate;
  final StatRange sugar;
  final StatRange spo2;
  final StatRange stress;

  const AggregatedStats({
    required this.heartRate,
    required this.sugar,
    required this.spo2,
    required this.stress,
  });

  factory AggregatedStats.fromJson(Map<String, dynamic> json) =>
      AggregatedStats(
        heartRate: StatRange.fromJson(
            (json['heart_rate'] as Map<String, dynamic>?) ?? {}),
        sugar: StatRange.fromJson(
            (json['sugar'] as Map<String, dynamic>?) ?? {}),
        spo2: StatRange.fromJson(
            (json['spo2'] as Map<String, dynamic>?) ?? {}),
        stress: StatRange.fromJson(
            (json['stress'] as Map<String, dynamic>?) ?? {}),
      );
}

class TaskRawDataPoint {
  final int heartRate;
  final double? spo2;
  final double? stressLevel;
  final double? sugarLevel;
  final DateTime recordedAt;

  const TaskRawDataPoint({
    required this.heartRate,
    this.spo2,
    this.stressLevel,
    this.sugarLevel,
    required this.recordedAt,
  });

  factory TaskRawDataPoint.fromJson(Map<String, dynamic> json) =>
      TaskRawDataPoint(
        heartRate: json['heart_rate'] is num
            ? (json['heart_rate'] as num).toInt()
            : int.tryParse(json['heart_rate'].toString()) ?? 0,
        spo2: json['spo2'] != null
            ? double.tryParse(json['spo2'].toString())
            : null,
        stressLevel: json['stress_level'] != null
            ? double.tryParse(json['stress_level'].toString())
            : null,
        sugarLevel: json['sugar_level'] != null
            ? double.tryParse(json['sugar_level'].toString())
            : null,
        recordedAt: DateTime.tryParse(json['recorded_at'] ?? '') ??
            DateTime.now(),
      );
}

class CoachTaskResultSession {
  final int id;
  final int taskId;
  final DateTime startedAt;
  final DateTime endedAt;
  final AggregatedStats stats;
  final List<TaskRawDataPoint> rawData;

  const CoachTaskResultSession({
    required this.id,
    required this.taskId,
    required this.startedAt,
    required this.endedAt,
    required this.stats,
    required this.rawData,
  });

  Duration get duration => endedAt.difference(startedAt);

  factory CoachTaskResultSession.fromJson(Map<String, dynamic> json) {
    final rawList = (json['raw_data'] as List?) ?? [];
    return CoachTaskResultSession(
      id: (json['id'] as num?)?.toInt() ?? 0,
      taskId: (json['task_id'] as num?)?.toInt() ?? 0,
      startedAt:
          DateTime.tryParse(json['started_at'] ?? '') ?? DateTime.now(),
      endedAt: DateTime.tryParse(json['ended_at'] ?? '') ?? DateTime.now(),
      stats: AggregatedStats.fromJson(
          (json['aggregated_stats'] as Map<String, dynamic>?) ?? {}),
      rawData: rawList
          .whereType<Map<String, dynamic>>()
          .map(TaskRawDataPoint.fromJson)
          .toList()
          .reversed
          .toList(), // oldest first for chart
    );
  }
}

class CoachTaskResultEntity {
  final int taskId;
  final List<CoachTaskResultSession> sessions;

  const CoachTaskResultEntity({
    required this.taskId,
    required this.sessions,
  });
}
