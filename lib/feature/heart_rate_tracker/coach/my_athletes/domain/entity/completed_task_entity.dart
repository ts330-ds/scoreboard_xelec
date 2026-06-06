class CompletedTaskEntity {
  final Map<String, dynamic> raw;
  const CompletedTaskEntity({required this.raw});

  int? get id => _toInt(raw['task_id'] ?? raw['id']);

  String? get name => _toStr(raw['task_name'] ?? raw['name'] ?? raw['title']);

  String? get athleteName => _toStr(raw['athlete_name']);

  String? get status => _toStr(raw['status']);

  /// Duration calculated from assigned_at → feedback submitted_at.
  int? get durationSeconds {
    final start = assignedAt;
    final end = feedback?.submittedAt;
    if (start == null || end == null) return null;
    return end.difference(start).inSeconds;
  }

  String? get assignedBy => _toStr(raw['assigned_by']);

  String? get assignedByName => _toStr(raw['assigned_by_name']);

  DateTime? get assignedAt {
    final v = raw['assigned_at'];
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  CompletedTaskFeedback? get feedback {
    final v = raw['feedback'];
    if (v is Map<String, dynamic>) {
      return CompletedTaskFeedback(raw: v);
    }
    return null;
  }

  /// Best date to display — submitted_at if feedback present, else assigned_at.
  DateTime? get displayDate => feedback?.submittedAt ?? assignedAt;
}

class CompletedTaskFeedback {
  final Map<String, dynamic> raw;
  const CompletedTaskFeedback({required this.raw});

  int? get rpe => _toInt(raw['rpe']);
  String? get note => _toStr(raw['note']);
  int? get trainingLoad => _toInt(raw['training_load']);

  /// Session duration in **seconds** (API returns seconds).
  int? get sessionDurationSeconds =>
      _toInt(raw['session_duration'] ?? raw['session_duration_minutes']);

  DateTime? get submittedAt {
    final v = raw['submitted_at'];
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String? _toStr(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}
