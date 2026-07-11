import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:xelex_esp/core/util/compression.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/data/local/session_readings_store.dart';
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

  // Band stop ke turant baad apna in-flight record close nahi karta — usme
  // ~10s lagte hain (log evidence: stop 11:40:29, record commit 11:40:39 —
  // fetch 6 sec se race haar ke 0 readings laayi thi). Isliye pehli fetch se
  // pehle chhota delay, aur khaali/bahut-kam data aane par bounded re-fetch.
  static const _maxFetchAttempts = 3;
  static const _initialFetchDelay = Duration(seconds: 5);
  static const _fetchRetryDelay = Duration(seconds: 10);
  // ~1 reading/sec aati hai — expected ke 10% se kam matlab record abhi
  // adhoora hai (close nahi hua), poora data nahi mila.
  static const _minDataFraction = 0.10;
  int _fetchAttempt = 0;

  // Concurrency guard — har naya flow (submit/retry) generation badhata hai,
  // jisse purane flow ke pending awaits stale ho kar chup-chaap abort karte
  // hain. Iske bina double app-resume (power button on/off) pe do parallel
  // retry flows ek doosre ke states overwrite karte the — UI compressing pe
  // atak jaati thi.
  int _flowGen = 0;
  bool _isStale(int gen) => isClosed || gen != _flowGen;

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
    _fetchAttempt = 1;
    final gen = ++_flowGen;

    // Band ko record close karne ka time do — turant maangne par khaali/
    // adhoora milta hai (feedback form ka time + ye delay usually kaafi).
    emit(state.copyWith(
      status: TaskZipStatus.fetching,
      message: 'Waiting for device to finalize session data...',
      clearError: true,
    ));
    await Future.delayed(_initialFetchDelay);
    if (_isStale(gen)) return;

    _startFetch(
      gen: gen,
      taskId: taskId,
      sessionStart: sessionStart,
      sessionEnd: sessionEnd,
    );
  }

  // Fetch shuru karta hai — pehli baar aur har re-fetch attempt pe yahi
  // chalta hai (subscription fresh banti hai, purani cancel).
  void _startFetch({
    required int gen,
    required int taskId,
    required DateTime sessionStart,
    required DateTime sessionEnd,
  }) {
    emit(state.copyWith(
      status: TaskZipStatus.fetching,
      message: 'Fetching data from device...',
      clearError: true,
    ));

    _fetchSub?.cancel();
    _fetchSub = _fetchCubit.stream.listen((fetchState) {
      if (_isStale(gen)) {
        _fetchSub?.cancel();
        return;
      }
      if (fetchState.status == FetchRangeStatus.syncing) {
        emit(state.copyWith(message: fetchState.message));
      } else if (fetchState.status == FetchRangeStatus.complete) {
        _fetchSub?.cancel();
        _onFetchComplete(
          gen: gen,
          taskId: taskId,
          sessionStartMs: sessionStart.millisecondsSinceEpoch,
          sessionEndMs: sessionEnd.millisecondsSinceEpoch,
          hrData: fetchState.hrData,
        ).catchError((e) {
          if (!_isStale(gen)) {
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

  /// Retry after a failure — re-reads the task's staged readings from the
  /// session store and re-attempts zip upload. Agar staging me kuch nahi
  /// (app fetch complete hone se pehle mar gayi thi), to band se pura fetch
  /// dobara chalate hain.
  Future<void> retryUpload({
    required int taskId,
    required int sessionStartMs,
    required int sessionEndMs,
  }) async {
    if (state.isWorking) return;
    final gen = ++_flowGen;

    emit(state.copyWith(
      status: TaskZipStatus.compressing,
      clearError: true,
      message: 'Retrying upload...',
    ));

    final readings = await SessionReadingsStore.instance.readForTask(taskId);
    if (_isStale(gen)) return;
    // Staging khaali ya adhoori (expected ke 10% se kam) — band se poora
    // fetch dobara chalao (fresh attempts ke saath), warna manual retry
    // purana incomplete data hi upload kar deta.
    final expectedSeconds = ((sessionEndMs - sessionStartMs) / 1000).round();
    final minReadings =
        expectedSeconds > 0 ? (expectedSeconds * _minDataFraction).ceil() : 1;
    if (readings.length < minReadings) {
      debugPrint('[TASK-ZIP] retry — staging has ${readings.length}/'
          '$expectedSeconds expected, re-fetching from device');
      emit(const TaskZipSubmitState());
      await submitSessionData(
        taskId: taskId,
        sessionStart: DateTime.fromMillisecondsSinceEpoch(sessionStartMs),
        sessionEnd: DateTime.fromMillisecondsSinceEpoch(sessionEndMs),
      );
      return;
    }

    final mapped = _mapReadingsForApi(readings);
    await _compressAndUpload(gen: gen, taskId: taskId, readings: mapped);
  }

  // ── BLE fetch complete ───────────────────────────────────────────────────

  Future<void> _onFetchComplete({
    required int gen,
    required int taskId,
    required int sessionStartMs,
    required int sessionEndMs,
    required List<Map<dynamic, dynamic>> hrData,
  }) async {
    // Fetch cubit pehle hi session range (±30s drift) pe filter kar chuka hai.
    // Ise health-history me NAHI — session staging table me rakhte hain, taaki
    // upload fail/app-kill pe retry ho sake aur success pe clear ho jaaye.
    await SessionReadingsStore.instance.saveForTask(taskId, hrData);

    final readings = await SessionReadingsStore.instance.readForTask(taskId);
    if (_isStale(gen)) return;

    // Band ~1 reading/sec deta hai. Expected ke 10% se kam mila to band ne
    // shayad in-flight record abhi close nahi kiya (close hone me stop ke
    // baad ~10s lagte hain) — thoda ruk ke dobara fetch karo, max 3 attempts.
    // Staging (task_id, stamp) PK pe upsert hai, isliye re-fetch pe duplicate
    // readings nahi banti.
    final expectedSeconds = ((sessionEndMs - sessionStartMs) / 1000).round();
    final minReadings =
        expectedSeconds > 0 ? (expectedSeconds * _minDataFraction).ceil() : 1;
    final incomplete = readings.length < minReadings;

    if (incomplete && _fetchAttempt < _maxFetchAttempts) {
      _fetchAttempt++;
      debugPrint('[TASK-ZIP] Incomplete data for task $taskId — '
          '${readings.length}/$expectedSeconds expected readings. '
          'Re-fetch attempt $_fetchAttempt/$_maxFetchAttempts '
          'in ${_fetchRetryDelay.inSeconds}s');
      emit(state.copyWith(
        status: TaskZipStatus.fetching,
        message: 'Device is still finalizing session data — '
            'retrying ($_fetchAttempt/$_maxFetchAttempts)...',
      ));
      await Future.delayed(_fetchRetryDelay);
      if (_isStale(gen)) return;
      _startFetch(
        gen: gen,
        taskId: taskId,
        sessionStart: DateTime.fromMillisecondsSinceEpoch(sessionStartMs),
        sessionEnd: DateTime.fromMillisecondsSinceEpoch(sessionEndMs),
      );
      return;
    }

    if (readings.isEmpty) {
      debugPrint('[TASK-ZIP] No readings found for task $taskId '
          '(range: $sessionStartMs – $sessionEndMs) '
          'after $_fetchAttempt fetch attempts');
      emit(state.copyWith(
        status: TaskZipStatus.error,
        errorMessage: 'No heart rate readings found for this session. '
            'Make sure your device was worn during the session.',
        message: 'No readings',
        totalReadings: 0,
      ));
      return;
    }

    if (incomplete) {
      // 3 attempts ke baad bhi kam data — band ke paas shayad itna hi hai
      // (e.g. band aadhi session hi pehna tha). Jo mila wahi upload karo.
      debugPrint('[TASK-ZIP] Still low data after $_fetchAttempt attempts '
          '(${readings.length}/$expectedSeconds) — uploading what we have');
    }

    final mapped = _mapReadingsForApi(readings);
    await _compressAndUpload(gen: gen, taskId: taskId, readings: mapped);
  }

  // ── Gzip compress & upload ──────────────────────────────────────────────

  Future<void> _compressAndUpload({
    required int gen,
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
      if (_isStale(gen)) return;
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
        if (_isStale(gen)) return;

        jobId = await _postGzipPayload(gzipBytes, token);
        if (_isStale(gen)) return;
        if (jobId != null) break;

        // Auth failure already emitted error state inside _postGzipPayload
        if (state.status == TaskZipStatus.error) return;

        if (attempt < _maxRetries - 1) {
          debugPrint('[TASK-ZIP] Upload attempt ${attempt + 1} failed, retrying...');
          await Future.delayed(_retryDelays[attempt]);
        }
      }

      if (_isStale(gen)) return;

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

      final pollResult = await _pollJobStatus(gen, jobId, token);

      if (_isStale(gen)) return;

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

      // Server pe pahunch gaya — staging data ki ab zaroorat nahi.
      await SessionReadingsStore.instance.clearTask(taskId);

      emit(state.copyWith(
        status: TaskZipStatus.complete,
        message: '${readings.length} readings uploaded successfully.',
      ));

      debugPrint('[TASK-ZIP] Upload complete for task $taskId '
          '— ${readings.length} readings, staging cleared');
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
        errorMessage: 'Upload failed. Please try again.',
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

      final String responseBody;
      final int statusCode;
      try {
        final request = await httpClient.postUrl(uri);
        request.headers.set('Authorization', 'Bearer $token');
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Content-Encoding', 'gzip');
        request.headers.contentLength = gzipBytes.length;
        request.add(gzipBytes);

        // connectionTimeout sirf connect cover karta hai — response ka apna
        // timeout zaroori hai. App suspend (screen off) me socket chupchaap
        // mar jaata hai; bina timeout ke ye await kabhi complete nahi hota
        // aur upload flow hamesha ke liye atka rehta tha.
        final httpResponse =
            await request.close().timeout(const Duration(seconds: 60));
        responseBody = await httpResponse
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 30));
        statusCode = httpResponse.statusCode;
      } finally {
        // force: true — hung/dead socket bhi turant release ho.
        httpClient.close(force: true);
      }

      debugPrint('[TASK-ZIP] Status: $statusCode');
      debugPrint('[TASK-ZIP] Body: $responseBody');

      if (statusCode == 401 || statusCode == 403) {
        // Raw HttpClient Dio interceptor bypass karta hai — global logout flow
        // manually trigger karo (token clear + re-login route), warna user
        // sirf error dekhta tha par logout nahi hota tha.
        ApiService.instance.notifyTokenExpired();
        emit(state.copyWith(
          status: TaskZipStatus.error,
          errorMessage: 'Auth expired, please login again',
        ));
        return null;
      }

      if (statusCode != 202) {
        debugPrint('[TASK-ZIP] Unexpected status: $statusCode');
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

  Future<Map<String, dynamic>?> _pollJobStatus(
      int gen, String jobId, String token) async {
    const maxAttempts = 60;
    int consecutiveErrors = 0;
    const maxConsecutiveErrors = 5;

    for (int i = 0; i < maxAttempts; i++) {
      if (_isStale(gen)) return null;

      await Future.delayed(const Duration(seconds: 1));
      try {
        // Auth header explicitly bhejo — global Dio token set na ho (fresh
        // isolate / relaunch / cleared) to poll "No token provided" (401) de
        // deta tha. POST bhi isi tarah explicit header use karta hai.
        final response = await ApiService.instance.dio.get(
          '/athlete/ingestion/job/$jobId',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
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
      debugPrint('[TASK-ZIP] App resumed during upload — retrying from staging');
      _fetchSub?.cancel();
      emit(state.copyWith(
        status: TaskZipStatus.error,
        errorMessage: 'Upload interrupted. Retrying...',
      ));
      retryUpload(taskId: taskId, sessionStartMs: startMs, sessionEndMs: endMs);
    }
  }

  void reset() {
    _flowGen++; // pending flows stale ho jaayen — reset ke baad kuch emit na karein
    _fetchSub?.cancel();
    emit(const TaskZipSubmitState());
  }

  @override
  Future<void> close() {
    _fetchSub?.cancel();
    return super.close();
  }
}
