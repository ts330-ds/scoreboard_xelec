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
  // Close-aware re-fetch: band ka record commit (~30s tak / next data-request
  // pe) hone tak fetch se poora data nahi milta. Vendor confirm: data maangna
  // hi record close ka trigger hai — isliye har fetch band ko commit ke kareeb
  // dhakelta hai, aur agla fetch aksar closed record ka pura data laata hai.
  // Blind-timer ke bajaye record-list se decide karte hain (dekho _onFetchComplete).
  // Max 3 fetch tries — pehli fetch + 2 re-fetch. Isse zyada try karne se sirf
  // user ka time jaata hai; agar band 3 fetch-cycle me record commit nahi karta
  // to wo turant nahi hoga, isliye ruk ke user ko "wapas aakar dobara flush"
  // ka mauka dete hain.
  static const _maxFetchAttempts = 3;
  static const _initialFetchDelay = Duration(seconds: 5);
  // Escalating backoff — re-fetch ke beech wait. 3 attempts pe window ~5+10=15s
  // (+ fetch durations). Extra entries (>attempts) safe hain — clamp use hota hai.
  static const _fetchRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 15),
    Duration(seconds: 20),
    Duration(seconds: 30),
  ];
  // ~1 reading/sec aati hai. Session ka data tab hi "poora" maana jaata hai jab
  // expected readings ka >=95% mil jaaye. Isse kam = record abhi band ke andar
  // commit ho raha hai (tail missing) — server pe partial NAHI bhejte; user ko
  // wapas aakar dobara flush karne ko kehte hain. (Pehle 10% tha jo 20+ min ka
  // tail-gap bhi "complete" maan ke partial upload kar deta tha.)
  static const _minDataFraction = 0.90;
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
      message: 'Attempt 1 of $_maxFetchAttempts • Waiting for the watch to '
          'finalize this recording...',
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
      message: 'Attempt $_fetchAttempt of $_maxFetchAttempts • Fetching session '
          'data from your watch...',
      clearError: true,
    ));

    _fetchSub?.cancel();
    _fetchSub = _fetchCubit.stream.listen((fetchState) {
      if (_isStale(gen)) {
        _fetchSub?.cancel();
        return;
      }
      if (fetchState.status == FetchRangeStatus.syncing) {
        emit(state.copyWith(
          message: 'Attempt $_fetchAttempt of $_maxFetchAttempts • '
              '${fetchState.message}',
        ));
      } else if (fetchState.status == FetchRangeStatus.complete) {
        _fetchSub?.cancel();
        _onFetchComplete(
          gen: gen,
          taskId: taskId,
          sessionStartMs: sessionStart.millisecondsSinceEpoch,
          sessionEndMs: sessionEnd.millisecondsSinceEpoch,
          hrData: fetchState.hrData,
          recordMaxStampSec: fetchState.recordMaxStampSec,
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
    required int recordMaxStampSec,
  }) async {
    // Fetch cubit pehle hi session range (±30s drift) pe filter kar chuka hai.
    // Ise health-history me NAHI — session staging table me rakhte hain, taaki
    // upload fail/app-kill pe retry ho sake aur success pe clear ho jaaye.
    await SessionReadingsStore.instance.saveForTask(taskId, hrData);

    final readings = await SessionReadingsStore.instance.readForTask(taskId);
    if (_isStale(gen)) return;

    // Band ~1 reading/sec deta hai. Expected ke 10% se kam = adhoora data.
    final expectedSeconds = ((sessionEndMs - sessionStartMs) / 1000).round();
    final minReadings =
        expectedSeconds > 0 ? (expectedSeconds * _minDataFraction).ceil() : 1;
    final incomplete = readings.length < minReadings;

    // ── Close-aware signal ──────────────────────────────────────────────────
    // Agar record-list me session ke END ke baad shuru hone wala koi record
    // maujood hai, to session ka record commit ho chuka (band ne uske baad naya
    // record khol diya) — matlab jitna data mila wahi final hai, retry se aur
    // nahi aayega. Agar aisa koi record NAHI, to session ka record abhi OPEN ho
    // sakta hai — tab retry sarthak hai (har fetch band ko commit ka nudge deta
    // hai, agla fetch closed record ka data laata hai). recordMaxStampSec 0 ho
    // (record info hi na mile) to conservatively "open" maano.
    final sessionEndSec = (sessionEndMs / 1000).round();
    final recordClosed =
        recordMaxStampSec > 0 && recordMaxStampSec > sessionEndSec;

    // Adhoora data + record shayad abhi open + attempts bache → ruk ke re-fetch.
    if (incomplete && !recordClosed && _fetchAttempt < _maxFetchAttempts) {
      final delay = _fetchRetryDelays[
          (_fetchAttempt - 1).clamp(0, _fetchRetryDelays.length - 1)];
      _fetchAttempt++;
      debugPrint('[TASK-ZIP] Incomplete (${readings.length}/$expectedSeconds), '
          'record still open — re-fetch $_fetchAttempt/$_maxFetchAttempts '
          'in ${delay.inSeconds}s');
      emit(state.copyWith(
        status: TaskZipStatus.fetching,
        message: 'The watch is still saving this recording — retrying '
            '(Attempt $_fetchAttempt of $_maxFetchAttempts)...',
      ));
      await Future.delayed(delay);
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
      debugPrint('[TASK-ZIP] No readings for task $taskId after $_fetchAttempt '
          'attempts (recordClosed=$recordClosed, range: $sessionStartMs–$sessionEndMs)');
      emit(state.copyWith(
        status: TaskZipStatus.error,
        // Record abhi open ho sakta hai — user ko Retry pe guide karo (band ko
        // finalize hone ka mauka). Ye wahi "Upload Session" fallback trigger karega.
        errorMessage: 'No heart rate readings found yet. If you were wearing '
            'the device, wait a moment and tap Retry — the band may still be '
            'finalizing this recording.',
        message: 'No readings',
        totalReadings: 0,
      ));
      return;
    }

    // ── 95% completeness gate ────────────────────────────────────────────────
    // Data adhoora + record abhi OPEN (band ne session-end ke baad naya record
    // nahi khola) → matlab band abhi tail commit kar raha hai. Server pe partial
    // MAT bhejo. User ko rok ke bolo: thodi der baad wapas aakar Retry (flush)
    // dabayein — tab tak band record close kar dega aur agli flush pura data
    // laayegi. (Retry button retryUpload → device se fresh fetch karta hai.)
    if (incomplete && !recordClosed) {
      debugPrint('[TASK-ZIP] Incomplete (${readings.length}/$expectedSeconds, '
          'record still open) after $_fetchAttempt attempts — asking user to re-flush');
      emit(state.copyWith(
        status: TaskZipStatus.error,
        errorMessage: 'The recording is still open on your watch and hasn\'t '
            'finished saving yet — this can take some time to complete. '
            'Got ${readings.length} of ~$expectedSeconds readings so far. '
            'Please keep the band nearby, wait a moment, then tap Retry.',
        message: 'Recording still open on watch',
        totalReadings: readings.length,
      ));
      return;
    }

    if (incomplete) {
      // recordClosed == true → band ne session-end ke baad naya record khol diya,
      // matlab is session ka record FINAL hai; band ke paas itna hi data hai
      // (aadhi session pehni / beech me utaari). Re-flush se aur nahi aayega,
      // isliye jo mila wahi upload karo — warna user hamesha atka rahega.
      debugPrint('[TASK-ZIP] Uploading final partial (${readings.length}/'
          '$expectedSeconds, record closed) after $_fetchAttempt attempts');
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
