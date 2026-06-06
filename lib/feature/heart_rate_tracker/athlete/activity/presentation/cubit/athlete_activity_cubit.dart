import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/data/model/activity_session_model.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/entity/athlete_task_entity.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/usecase/create_athlete_task_usecase.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_result_submit_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_result_submit_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/service/foreground/athlete_foreground_service.dart';
import 'package:xelex_esp/service/network/network_reconnect_notifier.dart';
import 'package:xelex_esp/service/socket/reconnect_controller.dart';
import 'athlete_activity_state.dart';

class AthleteActivityCubit extends Cubit<AthleteActivityState>
    with WidgetsBindingObserver {
  final CreateAthleteTaskUseCase _createTask;
  final SharedPreferences _prefs;
  final HeartBleCubit _bleCubit;

  // Socket ab yahan nahi — background isolate mein.
  // Cubit ka kaam: UI state, timer, BLE data forwarding, events receive karna.

  AthleteActivityCubit({
    required CreateAthleteTaskUseCase createTask,
    required SharedPreferences prefs,
    required HeartBleCubit bleCubit,
  })  : _createTask = createTask,
        _prefs = prefs,
        _bleCubit = bleCubit,
        super(const AthleteActivityState()) {
    WidgetsBinding.instance.addObserver(this);
    _bgSub = AthleteForegroundService.eventStream.listen(_onBackgroundEvent);
    // BLE data cubit mein directly sunna — screen navigate hone pe bhi
    // data flow band nahi hoga (widget listener pe depend nahi).
    _bleSub = _bleCubit.stream.listen(_onBleState);
    // Airplane mode / Wi-Fi drop ke baad jab network restore ho, agar session
    // active hai aur socket disconnect/exhausted hai to turant retry karo.
    _netSub = NetworkReconnectNotifier.instance.onNetworkRestored.listen((_) {
      if (isClosed || !state.isSessionActive || state.isAuthFailure) return;
      if (!state.isSocketConnected) {
        debugPrint('[ACTIVITY CUBIT] network restored — forcing retry');
        retryConnectionManually();
      }
    });
  }

  /// Active upload cubits — kept alive so uploads continue even if
  /// the user navigates away. Cleaned up when upload completes.
  final List<TaskResultSubmitCubit> _activeUploads = [];

  /// Creates a new upload cubit for a session, keeps reference alive.
  TaskResultSubmitCubit createUploadCubit(TaskResultSubmitCubit cubit) {
    _activeUploads.add(cubit);
    late final StreamSubscription<TaskResultSubmitState> sub;
    sub = cubit.stream.listen((uploadState) {
      if (isClosed) return;
      // Sirf success pe hi tear-down karo. Error pe upload screen yahi cubit
      // ko Retry button ke liye (resumeUpload → emit) zinda rakhta hai —
      // yahan close karne se agle emit pe crash hoga. Errored/abandoned
      // cubits parent close() me cleanup ho jaate hain.
      if (uploadState.status == TaskSubmitStatus.complete) {
        _activeUploads.remove(cubit);
        sub.cancel();
        cubit.close();
      }
    });
    return cubit;
  }

  StreamSubscription<Map<String, dynamic>>? _bgSub;
  StreamSubscription<HeartBleState>? _bleSub;
  StreamSubscription<void>? _netSub;
  bool _bleWasConnected = false;

  void _onBleState(HeartBleState bleState) {
    if (isClosed) return;

    final nowConnected = bleState.isConnected;
    if (nowConnected && !_bleWasConnected) {
      AthleteForegroundService.preWarmService();
    } else if (!nowConnected && _bleWasConnected && !state.isSessionActive) {
      AthleteForegroundService.stopIfIdle();
    }
    _bleWasConnected = nowConnected;

    if (!state.isSessionActive) return;
    if (bleState.heartRate > 0) {
      recordHeartRate(bleState.heartRate);
    }
    updateBiometrics(
      spo2: bleState.spo2 > 0 ? bleState.spo2.toDouble() : null,
      stressLevel: bleState.stressLevel > 0 ? bleState.stressLevel : null,
      hrv: bleState.hrv > 0 ? bleState.hrv : null,
    );
  }

  // UI ke liye timer — sirf elapsed seconds update karta hai
  Timer? _timer;
  // Auto-stop — jab duration puri ho
  Timer? _autoStopTimer;
  // Server se response na aaye to fallback
  Timer? _stopTimeoutTimer;
  // App pause time record — resume pe gap calculate karne ke liye
  DateTime? _pausedAt;
  final ReconnectController _reconnect = ReconnectController(tag: 'ACTIVITY RECONNECT');
  static const _uuid = Uuid();

  // ── Background events ───────────────────────────────────────────────────────
  // Background isolate se socket events aate hain yahan.
  // Event naam 'activity_' prefix se start hote hain — health monitor events ignore ho jaate hain.

  void _onBackgroundEvent(Map<String, dynamic> data) {
    if (isClosed) return;
    final event = data['event'] as String?;

    switch (event) {
      case 'activity_task_saved':
        // Data save successful = reconnect successful. Counters reset.
        if (!isClosed && !state.isSocketConnected) {
          _reconnect.reset();
          emit(state.copyWith(
            isSocketConnected: true,
            isSocketReconnecting: false,
            reconnectAttempt: 0,
            isReconnectExhausted: false,
          ));
        }

      case 'activity_recording_stopped':
        debugPrint('[CUBIT] recording_stopped — ending session');
        _endSession();

      case 'activity_disconnected':
        if (!isClosed && state.isSessionActive && !state.isAuthFailure) {
          emit(state.copyWith(
            isSocketConnected: false,
            isSocketReconnecting: true,
          ));
          _scheduleReconnect();
        }

      case 'activity_auth_failure':
        // Token expired/invalid. Retry waste — UI re-login flow trigger kare.
        _reconnect.cancel();
        if (!isClosed) {
          emit(state.copyWith(
            isSocketConnected: false,
            isSocketReconnecting: false,
            isAuthFailure: true,
            socketError: data['message'] as String? ?? 'Session expired',
          ));
        }

      case 'activity_error':
        if (!isClosed) {
          emit(state.copyWith(
            socketError: data['message'] as String?,
          ));
        }
    }
  }

  void _scheduleReconnect() {
    _reconnect.schedule(
      onAttempt: (attempt) {
        if (isClosed || !state.isSessionActive) return;
        debugPrint('[CUBIT] Reconnect attempt #$attempt');
        emit(state.copyWith(reconnectAttempt: attempt));
        _connectSocket();
      },
      onExhausted: () {
        if (isClosed) return;
        debugPrint('[CUBIT] Reconnect budget exhausted — waiting for user retry');
        emit(state.copyWith(
          isSocketReconnecting: false,
          isReconnectExhausted: true,
        ));
      },
    );
  }

  // User ne "Retry" button dabaya — budget reset karke turant attempt.
  void retryConnectionManually() {
    if (isClosed || !state.isSessionActive) return;
    _reconnect.reset();
    emit(state.copyWith(
      isSocketReconnecting: true,
      isReconnectExhausted: false,
      reconnectAttempt: 0,
      clearSocketError: true,
    ));
    _connectSocket();
  }

  // ── App Lifecycle ─────────────────────────────────────────────────────────
  // Main isolate suspend hone pe UI timer ruk jaata hai.
  // Lekin background service chalta rehta hai aur heartbeat bhejta rehta hai.
  // Resume pe gap calculate karke elapsed sync karo, aur timer restart karo.

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isClosed) return;
    switch (state) {
      case AppLifecycleState.paused:
        _onAppPaused();
      case AppLifecycleState.resumed:
        _onAppResumed();
      case AppLifecycleState.detached:
        // App process khatam ho rahi hai (swipe-kill / system kill).
        // Minimize / screen-off / phone call pe yeh fire nahi hota —
        // wahan paused/inactive hota hai. Yahan tak pahunchne ka matlab:
        // app genuinely band ho rahi hai → server ko bata do session stop.
        // Android me stopWithTask=true se BG service ka onDestroy bhi
        // yahi kaam karta hai (defense-in-depth). iOS pe Flutter side hi
        // sole option hai.
        _onAppDetached();
      default:
        break;
    }
  }

  void _onAppDetached() {
    if (!state.isSessionActive) return;
    final taskId = state.activeTaskId;
    if (taskId == null) return;
    debugPrint('[LIFECYCLE] detached — stopping active task $taskId');
    AthleteForegroundService.stopActivitySession(taskId);
  }

  void _onAppPaused() {
    if (!state.isSessionActive) return;
    // UI timer cancel — background mein drift ho sakta hai
    _timer?.cancel();
    _timer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _pausedAt = DateTime.now();
    debugPrint('[LIFECYCLE] Session paused at $_pausedAt');
    // NOTE: Background service chalta rehta hai — socket alive hai
  }

  void _onAppResumed() {
    if (isClosed || !state.isSessionActive) return;

    if (_pausedAt != null) {
      final gapSeconds = DateTime.now().difference(_pausedAt!).inSeconds;
      final newElapsed = state.elapsedSeconds + gapSeconds;
      final session = state.activeSession;
      if (session == null) return;
      final targetSeconds = session.targetDurationMinutes * 60;

      debugPrint(
          '[LIFECYCLE] Resumed — gap: ${gapSeconds}s, newElapsed: ${newElapsed}s');

      _pausedAt = null;

      if (targetSeconds > 0 && newElapsed >= targetSeconds) {
        if (isClosed) return;
        emit(state.copyWith(elapsedSeconds: targetSeconds));
        if (isClosed) return;
        requestStopSession();
        return;
      }

      if (isClosed) return;
      emit(state.copyWith(elapsedSeconds: newElapsed));
    }

    if (isClosed || !state.isSessionActive) return;
    _startTimer();
  }

  // ── Task name ─────────────────────────────────────────────────────────────

  void setTaskName(String name) => emit(state.copyWith(taskName: name));

  // ── Selection ─────────────────────────────────────────────────────────────

  void selectActivity(String type) =>
      emit(state.copyWith(selectedActivity: type));

  void selectDuration(int minutes) =>
      emit(state.copyWith(selectedDuration: minutes));

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> fetchLocation() async {
    if (isClosed || state.isLoadingLocation) return;
    emit(state.copyWith(isLoadingLocation: true, locationText: 'Fetching location...'));
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (isClosed) return;
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        if (isClosed) return;
        emit(state.copyWith(
          isLoadingLocation: false,
          locationText: 'Location services disabled. Enable GPS and retry.',
          clearLocation: true,
        ));
        // Re-set locationText after clearLocation blanks it.
        emit(state.copyWith(
          locationText: 'Location services disabled. Enable GPS and retry.',
        ));
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (isClosed) return;

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        if (isClosed) return;
        _emitLocationError('Permission denied. Enable location and retry.');
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (isClosed) return;
        if (permission == LocationPermission.denied) {
          _emitLocationError('Location permission denied');
          return;
        }
        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
          if (isClosed) return;
          _emitLocationError('Permission denied. Enable location and retry.');
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
      if (isClosed) return;

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (isClosed) return;
      final place = placemarks.isNotEmpty ? placemarks.first : null;

      final address = place != null
          ? '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}'
              .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
              .replaceAll(RegExp(r',\s*,'), ',')
          : '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';

      emit(state.copyWith(
        isLoadingLocation: false,
        locationText: address,
        lat: pos.latitude,
        lng: pos.longitude,
      ));
    } catch (e) {
      if (isClosed) return;
      _emitLocationError(
        'Unable to fetch location: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}',
      );
    }
  }

  void _emitLocationError(String message) {
    emit(state.copyWith(clearLocation: true));
    emit(state.copyWith(isLoadingLocation: false, locationText: message));
  }

  // ── Create task ────────────────────────────────────────────────────────────

  void resetTaskForm() {
    emit(state.copyWith(
      taskName: '',
      clearTaskError: true,
      clearLocation: true,
    ));
  }

  Future<bool> createTask() async {
    final name = state.taskName.trim();
    if (name.isEmpty) {
      emit(state.copyWith(clearTaskError: true));
      emit(state.copyWith(taskError: 'Enter task name'));
      return false;
    }

    emit(state.copyWith(isCreatingTask: true, clearTaskError: true));

    final result = await _createTask(
      name: name,
      assignedBy: 'self',
    ).run();

    if (isClosed) return false;
    return result.fold(
      (failure) {
        if (isClosed) return false;
        emit(state.copyWith(isCreatingTask: false, taskError: failure.message));
        return false;
      },
      (task) {
        if (isClosed) return false;
        emit(state.copyWith(
          isCreatingTask: false,
          clearTaskError: true,
          pendingTaskId: task.id,
          taskName: '',
        ));
        return true;
      },
    );
  }

  // ── Existing task select ───────────────────────────────────────────────────

  AthleteTaskEntity? _pendingTask;

  void selectExistingTask(AthleteTaskEntity task) {
    if (state.isSessionActive) return;
    _pendingTask = task;
    emit(state.copyWith(
      pendingTaskId: task.id,
      taskName: task.name,
      selectedDuration: int.tryParse(task.duration) ?? state.selectedDuration,
    ));
  }

  void cancelPendingTask() {
    emit(state.copyWith(clearPendingTaskId: true));
  }

  // ── Socket connect ─────────────────────────────────────────────────────────

  void _connectSocket() {
    final token = _prefs.getString(PrefKeys.userToken) ?? '';
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    final taskId = state.activeTaskId;
    if (token.isEmpty || baseUrl.isEmpty || taskId == null) return;

    // Background isolate mein socket connect hoga
    AthleteForegroundService.startActivitySession(
      token: token,
      baseUrl: baseUrl,
      taskId: taskId,
    );
  }

  // ── Session start ──────────────────────────────────────────────────────────

  void startSession() {
    final taskId = state.pendingTaskId;
    if (taskId == null) return;

    final session = ActivitySession(
      id: _uuid.v4(),
      activityType: state.selectedActivity,
      targetDurationMinutes: state.selectedDuration,
      startTime: DateTime.now(),
      location: state.locationText,
    );

    _bleCubit.setSessionActive(true);

    emit(state.copyWith(
      activeSession: session,
      elapsedSeconds: 0,
      activeTaskId: taskId,
      activeTask: _pendingTask,
      clearPendingTaskId: true,
    ));
    _pendingTask = null;

    _connectSocket();
    _startTimer();
  }

  void requestStopSession() {
    if (isClosed) return;
    final taskId = state.activeTaskId;

    _timer?.cancel();
    _timer = null;

    if (taskId != null) {
      emit(state.copyWith(isStoppingSession: true));
      // Background ko stop command bhejo
      AthleteForegroundService.stopActivitySession(taskId);

      _stopTimeoutTimer?.cancel();
      _stopTimeoutTimer = Timer(const Duration(seconds: 8), () {
        if (!isClosed && state.isStoppingSession) {
          debugPrint('[CUBIT] Stop timeout — forcefully ending session');
          _endSession();
        }
      });
    } else {
      _endSession();
    }
  }

  void _endSession() {
    _bleCubit.setSessionActive(false);
    _timer?.cancel();
    _timer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _stopTimeoutTimer?.cancel();
    _stopTimeoutTimer = null;
    _pausedAt = null;
    _reconnect.cancel();

    if (isClosed || state.activeSession == null) return;

    // Feedback sheet ke liye task id ko activeTaskId clear hone se pehle
    // capture karo. UI BlocListener pe sheet open karega, phir
    // acknowledgeFeedbackPrompt() call karega.
    final justCompletedTaskId = state.activeTaskId;
    final sessionStart = state.activeSession!.startTime;
    final localEndTime = DateTime.now();

    final completed = state.activeSession!.copyWith(
      endTime: localEndTime,
      isCompleted: true,
    );

    emit(state.copyWith(
      sessions: [completed, ...state.sessions],
      clearActiveSession: true,
      clearActiveTask: true,
      elapsedSeconds: 0,
      isStoppingSession: false,
      clearActiveTaskId: true,
      clearPendingTaskId: true,
      pendingFeedbackTaskId: justCompletedTaskId,
      completedSessionStart: sessionStart,
      completedSessionEnd: localEndTime,
      reconnectAttempt: 0,
      isReconnectExhausted: false,
      isSocketReconnecting: false,
      isAuthFailure: false,
    ));

    AthleteForegroundService.cleanupAfterSessionEnd();
  }

  // UI sheet handle karne ke baad call karega (Save / Resume / Discard) —
  // taaki dobara open na ho jab cubit rebuild ho ya navigation ho.
  void acknowledgeFeedbackPrompt() {
    if (state.pendingFeedbackTaskId == null) return;
    emit(state.copyWith(
      clearPendingFeedbackTaskId: true,
      clearCompletedSession: true,
    ));
  }

  // ── BLE data — UI mein store karo + background ko forward karo ────────────

  void recordHeartRate(int bpm) {
    if (isClosed || !state.isSessionActive || bpm <= 0) return;

    final session = state.activeSession;
    if (session == null) return;

    final sample = HeartRateSample(time: DateTime.now(), bpm: bpm);
    final updated = session.copyWith(
      heartRateSamples: [...session.heartRateSamples, sample],
    );

    final currentSpo2 = state.spo2;
    final currentStress = state.stressLevel;
    final currentHrv = state.hrv;
    final currentLat = state.lat;
    final currentLng = state.lng;

    emit(state.copyWith(activeSession: updated));

    AthleteForegroundService.updateMetrics(
      heartRate: bpm,
      spo2: currentSpo2,
      stressLevel: currentStress,
      hrv: currentHrv,
      lat: currentLat,
      lng: currentLng,
    );
  }

  void updateBiometrics({
    double? sugarLevel,
    double? spo2,
    int? stressLevel,
    double? hrv,
  }) {
    if (isClosed) return;
    emit(state.copyWith(
      sugarLevel: sugarLevel,
      spo2: spo2,
      stressLevel: stressLevel,
      hrv: hrv,
    ));

    // Latest biometrics background ko forward karo
    if (state.isSessionActive) {
      final latestBpm = state.activeSession?.heartRateSamples.isNotEmpty == true
          ? state.activeSession!.heartRateSamples.last.bpm
          : 0;
      if (latestBpm > 0) {
        AthleteForegroundService.updateMetrics(
          heartRate: latestBpm,
          spo2: spo2,
          stressLevel: stressLevel,
          hrv: hrv,
          lat: state.lat,
          lng: state.lng,
        );
      }
    }
  }

  // ── UI Timer — sirf elapsed count, heartbeat nahi ─────────────────────────
  // Heartbeat ab background onRepeatEvent mein jaata hai.

  void _startTimer() {
    _timer?.cancel();
    _autoStopTimer?.cancel();

    final session = state.activeSession;
    if (session == null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed || !state.isSessionActive) {
        _timer?.cancel();
        return;
      }
      emit(state.copyWith(elapsedSeconds: state.elapsedSeconds + 1));
    });

    final targetMinutes = session.targetDurationMinutes;
    if (targetMinutes > 0) {
      final remaining = (targetMinutes * 60) - state.elapsedSeconds;
      if (remaining > 0) {
        _autoStopTimer = Timer(Duration(seconds: remaining), () {
          if (!isClosed && state.isSessionActive) {
            requestStopSession();
          }
        });
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String formatSeconds(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _autoStopTimer?.cancel();
    _stopTimeoutTimer?.cancel();
    _reconnect.dispose();
    _bgSub?.cancel();
    _bleSub?.cancel();
    _netSub?.cancel();
    for (final cubit in _activeUploads) {
      cubit.close();
    }
    _activeUploads.clear();
    return super.close();
  }
}
