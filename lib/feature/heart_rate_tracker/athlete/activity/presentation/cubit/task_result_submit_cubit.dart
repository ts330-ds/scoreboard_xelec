import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/data/local/task_upload_record.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/data/local/task_upload_store.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/repository/athlete_task_repository.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/data/local/history_local_store.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/data/local/hr_reading_hive.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/ble_fetch_range/cubit/ble_fetch_range_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/ble_fetch_range/cubit/ble_fetch_range_state.dart';

import 'task_result_submit_state.dart';

class TaskResultSubmitCubit extends Cubit<TaskResultSubmitState> {
  final AthleteTaskRepository _repository;
  final BleFetchRangeCubit _fetchCubit;

  StreamSubscription<BleFetchRangeState>? _fetchSub;

  /// How many readings go in one API call.
  static const _chunkSize = 100;

  /// Max retry attempts per chunk.
  static const _maxRetries = 3;

  /// Delay between retries: 2s, 4s, 8s.
  static const _retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
  ];

  TaskResultSubmitCubit({
    required AthleteTaskRepository repository,
    required BleFetchRangeCubit fetchCubit,
  })  : _repository = repository,
        _fetchCubit = fetchCubit,
        super(const TaskResultSubmitState());

  // ── Main entry point ─────────────────────────────────────────────────────

  /// Called when session ends. Fetches data from BLE device, then uploads.
  Future<void> submitSessionData({
    required int taskId,
    required DateTime sessionStart,
    required DateTime sessionEnd,
  }) async {
    if (state.isWorking) return;

    emit(state.copyWith(
      status: TaskSubmitStatus.fetching,
      message: 'Fetching data from device...',
      clearError: true,
    ));

    _fetchSub?.cancel();
    _fetchSub = _fetchCubit.stream.listen((fetchState) {
      if (isClosed) {
        _fetchSub?.cancel();
        return;
      }
      if (fetchState.status == FetchRangeStatus.syncing) {
        emit(state.copyWith(
          message: fetchState.message,
        ));
      } else if (fetchState.status == FetchRangeStatus.complete) {
        _fetchSub?.cancel();
        _onFetchComplete(
          taskId: taskId,
          sessionStartMs: sessionStart.millisecondsSinceEpoch,
          sessionEndMs: sessionEnd.millisecondsSinceEpoch,
          hrData: fetchState.hrData,
        ).catchError((e) {
          if (!isClosed) {
            emit(state.copyWith(
              status: TaskSubmitStatus.error,
              errorMessage: 'Upload error: $e',
              message: 'Upload failed',
            ));
          }
        });
      } else if (fetchState.status == FetchRangeStatus.error) {
        _fetchSub?.cancel();
        emit(state.copyWith(
          status: TaskSubmitStatus.error,
          errorMessage: fetchState.message,
          message: 'Fetch failed',
        ));
      }
    });

    // Start the BLE fetch
    _fetchCubit.fetchRange(from: sessionStart, to: sessionEnd);
  }

  /// Resume a previously failed/interrupted upload.
  Future<void> resumeUpload(int taskId) async {
    if (state.isWorking) return;

    emit(state.copyWith(
      status: TaskSubmitStatus.uploading,
      clearError: true,
      message: 'Resuming upload...',
    ));

    final store = TaskUploadStore.instance;
    await store.open();

    final record = store.getRecord(taskId);
    if (record == null || !record.isResumable) {
      emit(state.copyWith(
        status: TaskSubmitStatus.error,
        errorMessage: 'No pending upload found for this task',
      ));
      return;
    }

    // Load readings from Hive and resume
    final readings = _loadReadingsFromHive(
      record.sessionStartMs,
      record.sessionEndMs,
    );

    if (readings.isEmpty) {
      emit(state.copyWith(
        status: TaskSubmitStatus.error,
        errorMessage: 'No readings found in local storage',
      ));
      return;
    }

    final mapped = _mapReadingsForApi(readings);
    await _uploadChunks(
      taskId: taskId,
      readings: mapped,
      startFromChunk: record.uploadedChunks,
    );
  }

  // ── BLE fetch complete ───────────────────────────────────────────────────

  Future<void> _onFetchComplete({
    required int taskId,
    required int sessionStartMs,
    required int sessionEndMs,
    required List<Map<dynamic, dynamic>> hrData,
  }) async {
    // Save HR data to Hive (so it persists even if upload fails)
    final historyStore = HistoryLocalStore.instance;
    await historyStore.open();
    await historyStore.upsertHrChunk(hrData);

    // Load filtered readings from Hive
    final readings = _loadReadingsFromHive(sessionStartMs, sessionEndMs);

    if (readings.isEmpty) {
      debugPrint('[TASK-SUBMIT] No readings found for task $taskId '
          '(range: $sessionStartMs – $sessionEndMs)');
      emit(state.copyWith(
        status: TaskSubmitStatus.error,
        errorMessage: 'No heart rate readings found for this session. '
            'Make sure your device was worn during the session.',
        message: 'No readings',
        totalReadings: 0,
      ));
      return;
    }

    // Map to API format
    final mapped = _mapReadingsForApi(readings);

    // Save upload record to Hive (for resume support)
    final totalChunks = (mapped.length / _chunkSize).ceil();
    final uploadStore = TaskUploadStore.instance;
    await uploadStore.open();
    await uploadStore.saveRecord(TaskUploadRecord(
      taskId: taskId,
      sessionStartMs: sessionStartMs,
      sessionEndMs: sessionEndMs,
      totalReadings: mapped.length,
      totalChunks: totalChunks,
    ));

    // Start uploading
    await _uploadChunks(taskId: taskId, readings: mapped);
  }

  // ── Load readings from Hive ──────────────────────────────────────────────

  List<HrReadingHive> _loadReadingsFromHive(
    int sessionStartMs,
    int sessionEndMs,
  ) {
    // BLE device clock can drift vs phone — allow 30s buffer on each side
    const driftMs = 30 * 1000;
    final fromMs = sessionStartMs - driftMs;
    final toMs = sessionEndMs + driftMs;

    final store = HistoryLocalStore.instance;
    final filtered = store.getHrInRange(fromMs, toMs);

    // Sort by timestamp
    filtered.sort((a, b) => a.stamp.compareTo(b.stamp));

    return filtered;
  }

  // ── Map HrReadingHive to API format ──────────────────────────────────────

  List<Map<String, dynamic>> _mapReadingsForApi(List<HrReadingHive> readings) {
    return readings.map((r) {
      return <String, dynamic>{
        'heart_rate': r.heartRate,
        'sugar_level': null,
        'spo2': null,
        'lat': null,
        'lng': null,
        'stress_level': null,
        'timestamp': _ensureMilliseconds(r.stamp),
      };
    }).toList();
  }

  // ── Chunked upload ───────────────────────────────────────────────────────

  Future<void> _uploadChunks({
    required int taskId,
    required List<Map<String, dynamic>> readings,
    int startFromChunk = 0,
  }) async {
    final totalChunks = (readings.length / _chunkSize).ceil();

    emit(state.copyWith(
      status: TaskSubmitStatus.uploading,
      totalReadings: readings.length,
      totalChunks: totalChunks,
      currentChunk: startFromChunk,
      message: 'Uploading...',
    ));

    final uploadStore = TaskUploadStore.instance;
    await uploadStore.open();

    debugPrint('[TASK-SUBMIT] Starting upload for task $taskId '
        '— ${readings.length} readings in $totalChunks chunks '
        '(resuming from chunk $startFromChunk)');

    for (int i = startFromChunk; i < totalChunks; i++) {
      if (isClosed) {
        debugPrint('[TASK-SUBMIT] Cubit closed at chunk ${i + 1} '
            '— upload will resume later');
        return;
      }

      // Slice out this chunk
      final start = i * _chunkSize;
      final end = (start + _chunkSize).clamp(0, readings.length);
      final chunk = readings.sublist(start, end);

      final isFirst = (i == 0 && startFromChunk == 0);
      final isLast = (i == totalChunks - 1);

      emit(state.copyWith(
        currentChunk: i + 1,
        uploadedReadings: start,
        message: 'Uploading chunk ${i + 1} of $totalChunks...',
      ));

      // Upload with retry
      final success = await _uploadChunkWithRetry(
        taskId: taskId,
        isFirstChunk: isFirst,
        isLastChunk: isLast,
        readings: chunk,
      );

      if (isClosed) return;

      if (!success) {
        await uploadStore.markError(taskId);
        emit(state.copyWith(
          status: TaskSubmitStatus.error,
          errorMessage: 'Upload failed at chunk ${i + 1} of $totalChunks. '
              'Please check your internet connection and try again.',
          message: 'Upload failed',
        ));
        return;
      }

      // Save progress after each successful chunk
      await uploadStore.updateProgress(taskId, i + 1);

      debugPrint('[TASK-SUBMIT] Chunk ${i + 1}/$totalChunks OK '
          '(${chunk.length} readings)');
    }

    // All chunks uploaded — remove tracking record from Hive
    await uploadStore.deleteRecord(taskId);
    emit(state.copyWith(
      status: TaskSubmitStatus.complete,
      currentChunk: totalChunks,
      uploadedReadings: readings.length,
      message: 'Upload complete! ${readings.length} readings uploaded.',
    ));

    debugPrint('[TASK-SUBMIT] Upload complete for task $taskId '
        '— ${readings.length} readings in $totalChunks chunks');
  }

  // ── Single chunk upload with retry ───────────────────────────────────────

  Future<bool> _uploadChunkWithRetry({
    required int taskId,
    required bool isFirstChunk,
    required bool isLastChunk,
    required List<Map<String, dynamic>> readings,
  }) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      if (isClosed) return false;

      final result = await _repository
          .submitTaskResults(
            taskId: taskId,
            isFirstChunk: isFirstChunk,
            isLastChunk: isLastChunk,
            readings: readings,
          )
          .run();

      final success = result.fold(
        (failure) {
          debugPrint('[TASK-SUBMIT] Chunk failed (attempt ${attempt + 1}): '
              '${failure.message}');
          return false;
        },
        (_) => true,
      );

      if (success) return true;

      // Wait before retrying (except on last attempt)
      if (attempt < _maxRetries - 1) {
        await Future.delayed(_retryDelays[attempt]);
      }
    }

    return false;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Ensures timestamp is in milliseconds.
  /// Timestamps below 1e12 are treated as seconds (epoch seconds are ~1.7e9 in 2024).
  int _ensureMilliseconds(int stamp) {
    return stamp < 1000000000000 ? stamp * 1000 : stamp;
  }

  void reset() {
    _fetchSub?.cancel();
    emit(const TaskResultSubmitState());
  }

  @override
  Future<void> close() {
    _fetchSub?.cancel();
    return super.close();
  }
}
