class HeartRateSample {
  final DateTime time;
  final int bpm;
  const HeartRateSample({required this.time, required this.bpm});
}

class ActivitySession {
  final String id;
  final String activityType;
  final int targetDurationMinutes;
  final DateTime startTime;
  final DateTime? endTime;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<HeartRateSample> heartRateSamples;
  final bool isCompleted;

  const ActivitySession({
    required this.id,
    required this.activityType,
    required this.targetDurationMinutes,
    required this.startTime,
    this.endTime,
    this.location = '',
    this.latitude,
    this.longitude,
    this.heartRateSamples = const [],
    this.isCompleted = false,
  });

  // ── Computed ─────────────────────────────────────────────────────────────

  int get actualDurationSeconds => endTime != null
      ? endTime!.difference(startTime).inSeconds
      : DateTime.now().difference(startTime).inSeconds;

  int get avgHeartRate {
    if (heartRateSamples.isEmpty) return 0;
    final total = heartRateSamples.fold(0, (sum, s) => sum + s.bpm);
    return total ~/ heartRateSamples.length;
  }

  int get maxHeartRate {
    if (heartRateSamples.isEmpty) return 0;
    return heartRateSamples.map((s) => s.bpm).reduce((a, b) => a > b ? a : b);
  }

  int get minHeartRate {
    if (heartRateSamples.isEmpty) return 0;
    return heartRateSamples.map((s) => s.bpm).reduce((a, b) => a < b ? a : b);
  }

  String get formattedDate {
    final d = startTime;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  String get formattedTime {
    final d = startTime;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  ActivitySession copyWith({
    DateTime? endTime,
    String? location,
    double? latitude,
    double? longitude,
    List<HeartRateSample>? heartRateSamples,
    bool? isCompleted,
  }) {
    return ActivitySession(
      id: id,
      activityType: activityType,
      targetDurationMinutes: targetDurationMinutes,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heartRateSamples: heartRateSamples ?? this.heartRateSamples,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
