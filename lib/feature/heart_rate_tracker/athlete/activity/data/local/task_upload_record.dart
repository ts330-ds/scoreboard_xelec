import 'package:hive/hive.dart';

/// Tracks upload progress for a single task's session data.
///
/// Stored in Hive so that if the app is killed mid-upload,
/// we can resume from the last successfully uploaded chunk.
class TaskUploadRecord {
  final int taskId;
  final int sessionStartMs;
  final int sessionEndMs;
  final int totalReadings;
  final int totalChunks;
  final int uploadedChunks;
  final String status; // pending | uploading | complete | error
  final int lastAttemptMs;

  const TaskUploadRecord({
    required this.taskId,
    required this.sessionStartMs,
    required this.sessionEndMs,
    required this.totalReadings,
    required this.totalChunks,
    this.uploadedChunks = 0,
    this.status = 'pending',
    this.lastAttemptMs = 0,
  });

  bool get isResumable => status != 'complete';
  int get remainingChunks => totalChunks - uploadedChunks;
  double get progress =>
      totalChunks > 0 ? uploadedChunks / totalChunks : 0.0;

  TaskUploadRecord copyWith({
    int? uploadedChunks,
    String? status,
    int? lastAttemptMs,
  }) {
    return TaskUploadRecord(
      taskId: taskId,
      sessionStartMs: sessionStartMs,
      sessionEndMs: sessionEndMs,
      totalReadings: totalReadings,
      totalChunks: totalChunks,
      uploadedChunks: uploadedChunks ?? this.uploadedChunks,
      status: status ?? this.status,
      lastAttemptMs: lastAttemptMs ?? this.lastAttemptMs,
    );
  }

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'sessionStartMs': sessionStartMs,
        'sessionEndMs': sessionEndMs,
        'totalReadings': totalReadings,
        'totalChunks': totalChunks,
        'uploadedChunks': uploadedChunks,
        'status': status,
        'lastAttemptMs': lastAttemptMs,
      };

  factory TaskUploadRecord.fromMap(Map<dynamic, dynamic> m) {
    return TaskUploadRecord(
      taskId: (m['taskId'] as num?)?.toInt() ?? 0,
      sessionStartMs: (m['sessionStartMs'] as num?)?.toInt() ?? 0,
      sessionEndMs: (m['sessionEndMs'] as num?)?.toInt() ?? 0,
      totalReadings: (m['totalReadings'] as num?)?.toInt() ?? 0,
      totalChunks: (m['totalChunks'] as num?)?.toInt() ?? 0,
      uploadedChunks: (m['uploadedChunks'] as num?)?.toInt() ?? 0,
      status: m['status'] as String? ?? 'pending',
      lastAttemptMs: (m['lastAttemptMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class TaskUploadRecordAdapter extends TypeAdapter<TaskUploadRecord> {
  @override
  final int typeId = 14;

  @override
  TaskUploadRecord read(BinaryReader reader) {
    final map = reader.readMap();
    return TaskUploadRecord.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, TaskUploadRecord obj) {
    writer.writeMap(obj.toMap());
  }
}
