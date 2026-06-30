import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:xelex_esp/core/util/compression.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/data/repository/history_repository.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history_sql/domain/entity/hr_reading.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/ble_fetch_range/cubit/ble_fetch_range_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/ble_fetch_range/cubit/ble_fetch_range_state.dart';
import 'package:xelex_esp/service/api/api_service.dart';

import 'task_zip_submit_state.dart';

class TaskZipSubmitCubit extends Cubit<TaskZipSubmitState> {
  final BleFetchRangeCubit _fetchCubit;

  StreamSubscription<BleFetchRangeState>? _fetchSub;

  static const _maxRetries = 3;
  static const _retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
  ];

  int? _lastTaskId;
  int? _lastSessionStartMs;
  int? _lastSessionEndMs;

  TaskZipSubmitCubit({
    required BleFetchRangeCubit fetchCubit,
  })  : _fetchCubit = fetchCubit,
        super(const TaskZipSubmitState());

  // ── Main entry point ─────────────────────────────────────────────────────

  Future<void> submitSessionData({
    required int taskId,
    required DateTime sessionStart,
    required DateTime sessionEnd,
  }) async {
    if (state.isWorking) return;

    _lastTaskId = taskId;
    _lastSessionStartMs = sessionStart.millisecondsSinceEpoch;
    _lastSessionEndMs = sessionEnd.millisecondsSinceEpoch;

    emit(state.copyWith(
      status: TaskZipStatus.fetching,
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
        emit(state.copyWith(message: fetchState.message));
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
              status: TaskZipStatus.error,
              errorMessage: 'Upload error: $e',
              message: 'Upload failed',
            ));
          }
        });
      } else if (fetchState.status == FetchRangeStatus.error) {
        _fetchSub?.cancel();
        emit(state.copyWith(
          status: TaskZipStatus.error,
          errorMessage: fetchState.message,
          message: 'Fetch failed',
        ));
      }
    });

    _fetchCubit.fetchRange(from: sessionStart, to: sessionEnd);
  }

  /// Retry after a failure — re-reads from Hive and re-attempts zip upload.
  Future<void> retryUpload({
    required int taskId,
    required int sessionStartMs,
    required int sessionEndMs,
  }) async {
    if (state.isWorking) return;

    emit(state.copyWith(
      status: TaskZipStatus.compressing,
      clearError: true,
      message: 'Retrying upload...',
    ));

    final readings = await _loadReadings(sessionStartMs, sessionEndMs);
    if (readings.isEmpty) {
      emit(state.copyWith(
        status: TaskZipStatus.error,
        errorMessage: 'No readings found in local storage',
      ));
      return;
    }

    final mapped = _mapReadingsForApi(readings);
    await _compressAndUpload(taskId: taskId, readings: mapped);
  }

  // ── BLE fetch complete ───────────────────────────────────────────────────

  Future<void> _onFetchComplete({
    required int taskId,
    required int sessionStartMs,
    required int sessionEndMs,
    required List<Map<dynamic, dynamic>> hrData,
  }) async {
    await HistoryRepository.instance.persistHrChunk(hrData);

    final readings = await _loadReadings(sessionStartMs, sessionEndMs);

    if (readings.isEmpty) {
      debugPrint('[TASK-ZIP] No readings found for task $taskId '
          '(range: $sessionStartMs – $sessionEndMs)');
      emit(state.copyWith(
        status: TaskZipStatus.error,
        errorMessage: 'No heart rate readings found for this session. '
            'Make sure your device was worn during the session.',
        message: 'No readings',
        totalReadings: 0,
      ));
      return;
    }

    final mapped = _mapReadingsForApi(readings);
    await _compressAndUpload(taskId: taskId, readings: mapped);
  }

  // ── Gzip compress & upload ──────────────────────────────────────────────

  Future<void> _compressAndUpload({
    required int taskId,
    required List<Map<String, dynamic>> readings,
  }) async {
    emit(state.copyWith(
      status: TaskZipStatus.compressing,
      totalReadings: readings.length,
      message: 'Compressing ${readings.length} readings...',
    ));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(PrefKeys.userToken) ?? '';
    if (token.isEmpty) {
      emit(state.copyWith(
        status: TaskZipStatus.error,
        errorMessage: 'Auth token not found, please login again',
      ));
      return;
    }

    final payload = <String, dynamic>{
      'task_id': taskId,
      'readings': readings,
    };

    try {
      // JSON encode + gzip bhari ho sakte hain (multi-hour session → kai MB).
      // Inhe main isolate pe chalane se UI freeze hoti thi, isliye ab ek alag
      // background isolate me chalate hain — UI bilkul smooth rehti hai.
      final compressed = await gzipPayloadInIsolate(payload);
      final gzipBytes = compressed.gzipBytes;
      final jsonLength = compressed.jsonLength;

      final jsonKb = (jsonLength / 1024).toStringAsFixed(1);
      final gzipKb = (gzipBytes.length / 1024).toStringAsFixed(1);
      final ratio = (gzipBytes.length * 100 / jsonLength).toStringAsFixed(1);
      final saved = (100 - gzipBytes.length * 100 / jsonLength).toStringAsFixed(1);
      debugPrint('[TASK-ZIP] ═══════════ COMPRESSION ═══════════');
      debugPrint('[TASK-ZIP] task=$taskId  readings=${readings.length}');
      debugPrint('[TASK-ZIP] JSON   : $jsonLength bytes ($jsonKb KB)');
      debugPrint('[TASK-ZIP] Gzip   : ${gzipBytes.length} bytes ($gzipKb KB)');
      debugPrint('[TASK-ZIP] Ratio  : $ratio% of original  →  saved $saved%');
      debugPrint('[TASK-ZIP] ════════════════════════════════════');

      // Upload with retry
      emit(state.copyWith(
        status: TaskZipStatus.uploading,
        message: 'Uploading ${readings.length} readings...',
      ));

      String? jobId;
      for (int attempt = 0; attempt < _maxRetries; attempt++) {
        if (isClosed) return;

        jobId = await _postGzipPayload(gzipBytes, token);
        if (jobId != null) break;

        // Auth failure already emitted error state inside _postGzipPayload
        if (state.status == TaskZipStatus.error) return;

        if (attempt < _maxRetries - 1) {
          debugPrint('[TASK-ZIP] Upload attempt ${attempt + 1} failed, retrying...');
          await Future.delayed(_retryDelays[attempt]);
        }
      }

      if (isClosed) return;

      if (jobId == null || jobId.isEmpty) {
        // Only emit if not already in error (e.g. auth failure)
        if (state.status != TaskZipStatus.error) {
          emit(state.copyWith(
            status: TaskZipStatus.error,
            errorMessage: 'Upload failed after $_maxRetries attempts. '
                'Please check your internet connection and try again.',
            message: 'Upload failed',
          ));
        }
        return;
      }

      // Poll job status
      emit(state.copyWith(
        status: TaskZipStatus.polling,
        jobId: jobId,
        message: 'Processing on server...',
      ));

      final pollResult = await _pollJobStatus(jobId);

      if (isClosed) return;

      if (pollResult == null) {
        emit(state.copyWith(
          status: TaskZipStatus.error,
          errorMessage: 'Server processing timed out. Please try again.',
          message: 'Timed out',
        ));
        return;
      }
      if (pollResult['error'] != null) {
        emit(state.copyWith(
          status: TaskZipStatus.error,
          errorMessage: pollResult['error'].toString(),
          message: 'Server error',
        ));
        return;
      }

      emit(state.copyWith(
        status: TaskZipStatus.complete,
        message: '${readings.length} readings uploaded successfully.',
      ));

      debugPrint('[TASK-ZIP] Upload complete for task $taskId '
          '— ${readings.length} readings');
    } on SocketException {
      emit(state.copyWith(
        status: TaskZipStatus.error,
        errorMessage: 'No internet connection',
        message: 'Upload failed',
      ));
    } on TimeoutException {
      emit(state.copyWith(
        status: TaskZipStatus.error,
        errorMessage: 'Upload timed out. Please try again.',
        message: 'Timed out',
      ));
    } catch (e) {
      debugPrint('[TASK-ZIP] Unexpected error: $e');
      emit(state.copyWith(
        status: TaskZipStatus.error,
        errorMessage: e.toString(),
        message: 'Upload failed',
      ));
    }
  }

  // ── POST gzipped bytes via dart:io HttpClient ───────────────────────────

  Future<String?> _postGzipPayload(List<int> gzipBytes, String token) async {
    try {
      final baseUrl = ApiService.instance.dio.options.baseUrl;
      final uri = Uri.parse('$baseUrl/athlete/task_results/submit/v3');

      debugPrint('[TASK-ZIP] POST $uri');
      debugPrint('[TASK-ZIP] Gzip payload: ${gzipBytes.length} bytes');

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 60);

      final request = await httpClient.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Content-Encoding', 'gzip');
      request.headers.contentLength = gzipBytes.length;
      request.add(gzipBytes);

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      httpClient.close();

      debugPrint('[TASK-ZIP] Status: ${httpResponse.statusCode}');
      debugPrint('[TASK-ZIP] Body: $responseBody');

      if (httpResponse.statusCode == 401 || httpResponse.statusCode == 403) {
        emit(state.copyWith(
          status: TaskZipStatus.error,
          errorMessage: 'Auth expired, please login again',
        ));
        return null;
      }

      if (httpResponse.statusCode != 202) {
        debugPrint('[TASK-ZIP] Unexpected status: ${httpResponse.statusCode}');
        return null;
      }

      final responseData = jsonDecode(responseBody) as Map<String, dynamic>? ?? {};
      final data = responseData['data'] as Map<String, dynamic>? ?? {};
      return data['job_id']?.toString();
    } catch (e) {
      debugPrint('[TASK-ZIP] POST error: $e');
      return null;
    }
  }

  // ── Poll job status ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _pollJobStatus(String jobId) async {
    const maxAttempts = 60;
    int consecutiveErrors = 0;
    const maxConsecutiveErrors = 5;

    for (int i = 0; i < maxAttempts; i++) {
      if (isClosed) return null;

      await Future.delayed(const Duration(seconds: 1));
      try {
        final response = await ApiService.instance.dio.get(
          '/athlete/ingestion/job/$jobId',
        );
        consecutiveErrors = 0;

        final respData = response.data as Map<String, dynamic>? ?? {};
        final data = respData['data'] as Map<String, dynamic>? ?? {};
        final status = data['status']?.toString() ?? '';

        if (status == 'done') {
          return data['result'] as Map<String, dynamic>? ?? data;
        }
        if (status == 'failed') {
          final reason = data['error']?.toString() ??
              data['message']?.toString() ??
              'Job failed on server';
          return <String, dynamic>{'error': reason};
        }
      } on DioException catch (e) {
        consecutiveErrors++;
        final code = e.response?.statusCode ?? 0;
        if (code == 401 || code == 403) {
          return <String, dynamic>{'error': 'Auth expired during polling'};
        }
        if (consecutiveErrors >= maxConsecutiveErrors) {
          return <String, dynamic>{'error': 'Network error during polling'};
        }
      } catch (_) {
        consecutiveErrors++;
        if (consecutiveErrors >= maxConsecutiveErrors) {
          return <String, dynamic>{'error': 'Unexpected error during polling'};
        }
      }
    }
    return null;
  }

  // ── Load readings from Hive ──────────────────────────────────────────────

  Future<List<HrReading>> _loadReadings(
      int sessionStartMs, int sessionEndMs) async {
    const driftMs = 30 * 1000;
    final fromMs = sessionStartMs - driftMs;
    final toMs = sessionEndMs + driftMs;

    final filtered = await HistoryRepository.instance.hrInRange(fromMs, toMs);
    filtered.sort((a, b) => a.stampSec.compareTo(b.stampSec));
    return filtered;
  }

  // ── Map to API format ───────────────────────────────────────────────────

  List<Map<String, dynamic>> _mapReadingsForApi(List<HrReading> readings) {
    return readings.map((r) {
      return <String, dynamic>{
        'heart_rate': r.heartRate,
        'sugar_level': null,
        'spo2': null,
        'lat': null,
        'lng': null,
        'stress_level': null,
        'timestamp': _ensureMilliseconds(r.stampSec),
      };
    }).toList();
  }

  int _ensureMilliseconds(int stamp) {
    return stamp < 1000000000000 ? stamp * 1000 : stamp;
  }

  void onAppResumed() {
    if (isClosed || state.status == TaskZipStatus.complete) return;
    final taskId = _lastTaskId;
    final startMs = _lastSessionStartMs;
    final endMs = _lastSessionEndMs;
    if (taskId == null || startMs == null || endMs == null) return;

    final start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final end = DateTime.fromMillisecondsSinceEpoch(endMs);

    if (state.status == TaskZipStatus.error) {
      debugPrint('[TASK-ZIP] App resumed with error — auto-retrying');
      retryUpload(taskId: taskId, sessionStartMs: startMs, sessionEndMs: endMs);
      return;
    }

    if (state.status == TaskZipStatus.fetching) {
      // BLE fetch was in progress — native BLE call is likely dead after
      // iOS suspension. Restart the full fetch from BLE device.
      debugPrint('[TASK-ZIP] App resumed during BLE fetch — restarting fetch');
      _fetchSub?.cancel();
      emit(const TaskZipSubmitState());
      submitSessionData(taskId: taskId, sessionStart: start, sessionEnd: end);
      return;
    }

    // Other working states (compressing/uploading/polling): the underlying
    // HTTP request or Dart computation is likely dead after iOS suspension.
    if (state.isWorking) {
      debugPrint('[TASK-ZIP] App resumed during upload — retrying from Hive');
      _fetchSub?.cancel();
      emit(state.copyWith(
        status: TaskZipStatus.error,
        errorMessage: 'Upload interrupted. Retrying...',
      ));
      retryUpload(taskId: taskId, sessionStartMs: startMs, sessionEndMs: endMs);
    }
  }

  void reset() {
    _fetchSub?.cancel();
    emit(const TaskZipSubmitState());
  }

  @override
  Future<void> close() {
    _fetchSub?.cancel();
    return super.close();
  }
}
