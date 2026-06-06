import 'package:hive/hive.dart';
import 'task_upload_record.dart';

/// Hive-backed store for tracking task result upload progress.
///
/// Each record is keyed by taskId. This lets us:
/// - Resume uploads after app kill
/// - Retry failed uploads
/// - Know which tasks still need uploading
class TaskUploadStore {
  TaskUploadStore._();
  static final TaskUploadStore instance = TaskUploadStore._();

  static const _boxName = 'task_upload_queue';

  late Box<TaskUploadRecord> _box;
  bool _opened = false;

  Future<void> open() async {
    if (_opened) return;
    _box = await Hive.openBox<TaskUploadRecord>(_boxName);
    _opened = true;
  }

  /// Save or update a record.
  Future<void> saveRecord(TaskUploadRecord record) async {
    await _box.put(record.taskId, record);
  }

  /// Get record for a specific task.
  TaskUploadRecord? getRecord(int taskId) => _box.get(taskId);

  /// Get all records that are not yet complete (pending / uploading / error).
  List<TaskUploadRecord> getPendingRecords() {
    return _box.values.where((r) => r.isResumable).toList();
  }

  /// Update chunk progress after a successful chunk upload.
  Future<void> updateProgress(int taskId, int uploadedChunks) async {
    final record = _box.get(taskId);
    if (record == null) return;

    await _box.put(
      taskId,
      record.copyWith(
        uploadedChunks: uploadedChunks,
        status: 'uploading',
        lastAttemptMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Mark task upload as complete.
  Future<void> markComplete(int taskId) async {
    final record = _box.get(taskId);
    if (record == null) return;

    await _box.put(
      taskId,
      record.copyWith(
        status: 'complete',
        uploadedChunks: record.totalChunks,
        lastAttemptMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Mark task upload as failed.
  Future<void> markError(int taskId) async {
    final record = _box.get(taskId);
    if (record == null) return;

    await _box.put(
      taskId,
      record.copyWith(
        status: 'error',
        lastAttemptMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Remove a completed record (cleanup).
  Future<void> deleteRecord(int taskId) async {
    await _box.delete(taskId);
  }
}
