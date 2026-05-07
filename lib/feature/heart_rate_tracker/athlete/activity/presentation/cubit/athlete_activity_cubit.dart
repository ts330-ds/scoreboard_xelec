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
import 'package:xelex_esp/service/socket/athlete_task_socket_service.dart';
import 'athlete_activity_state.dart';

class AthleteActivityCubit extends Cubit<AthleteActivityState>
    with WidgetsBindingObserver {
  final CreateAthleteTaskUseCase _createTask;
  final AthleteTaskSocketService _socketService;
  final SharedPreferences _prefs;

  AthleteActivityCubit({
    required CreateAthleteTaskUseCase createTask,
    required AthleteTaskSocketService socketService,
    required SharedPreferences prefs,
  })  : _createTask = createTask,
        _socketService = socketService,
        _prefs = prefs,
        super(const AthleteActivityState()) {
    WidgetsBinding.instance.addObserver(this);
    _setupSocketCallbacks();
  }

  Timer? _timer;
  Timer? _autoStopTimer;
  Timer? _stopTimeoutTimer;
  DateTime? _pausedAt; // app background gaya tab ka time
  static const _uuid = Uuid();

  // ── Socket callbacks ───────────────────────────────────────────────────────

  void _setupSocketCallbacks() {
    _socketService.onTaskSaved = (_) {
      if (!isClosed && !state.isSocketConnected) {
        emit(state.copyWith(isSocketConnected: true, isSocketReconnecting: false));
      }
    };

    _socketService.onRecordingStopped = (_) {
      debugPrint('[CUBIT] recording_stopped — ending session');
      _endSession();
    };

    _socketService.onDisconnected = () {
      if (!isClosed && state.isSessionActive) {
        emit(state.copyWith(
          isSocketConnected: false,
          isSocketReconnecting: true,
        ));
        _scheduleReconnect();
      }
    };

    _socketService.onError = (message) {
      if (!isClosed) {
        emit(state.copyWith(socketError: message, isSocketReconnecting: false));
      }
    };
  }

  Timer? _reconnectTimer;

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed && state.isSessionActive && !_socketService.isConnected) {
        debugPrint('[CUBIT] Reconnecting socket...');
        _connectSocket();
      }
    });
  }

  // ── App Lifecycle ─────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _onAppPaused();
      case AppLifecycleState.resumed:
        _onAppResumed();
      default:
        break;
    }
  }

  void _onAppPaused() {
    if (!state.isSessionActive) return;
    // Timer cancel karo — background mein drift ho sakta hai
    _timer?.cancel();
    _timer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _pausedAt = DateTime.now();
    debugPrint('[LIFECYCLE] Session paused at $_pausedAt');
  }

  void _onAppResumed() {
    if (!state.isSessionActive || _pausedAt == null) return;

    final gapSeconds = DateTime.now().difference(_pausedAt!).inSeconds;
    final newElapsed = state.elapsedSeconds + gapSeconds;
    final targetSeconds = state.activeSession!.targetDurationMinutes * 60;

    debugPrint(
        '[LIFECYCLE] Resumed — gap: ${gapSeconds}s, newElapsed: ${newElapsed}s, target: ${targetSeconds}s');

    _pausedAt = null;

    // Background mein hi duration puri ho gayi thi
    if (newElapsed >= targetSeconds) {
      emit(state.copyWith(elapsedSeconds: targetSeconds));
      requestStopSession();
      return;
    }

    emit(state.copyWith(elapsedSeconds: newElapsed));

    // Socket reconnect karo agar drop ho gaya tha
    if (!_socketService.isConnected && state.activeTaskId != null) {
      _connectSocket();
    }

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
    emit(state.copyWith(isLoadingLocation: true, locationText: 'Fetching location...'));
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
            isLoadingLocation: false, locationText: 'Location permission denied'));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
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
    } catch (_) {
      emit(state.copyWith(
          isLoadingLocation: false, locationText: 'Unable to fetch location'));
    }
  }

  // ── Create task via API (session start nahi hoti) ─────────────────────────

  Future<bool> createTask() async {
    final name = state.taskName.trim();
    if (name.isEmpty) {
      emit(state.copyWith(taskError: 'Task ka naam daalein'));
      return false;
    }

    emit(state.copyWith(isCreatingTask: true, clearTaskError: true));

    final result = await _createTask(
      name: name,
      duration: state.selectedDuration.toString(),
      assignedBy: 'self',
    ).run();

    return result.fold(
      (failure) {
        emit(state.copyWith(isCreatingTask: false, taskError: failure.message));
        return false;
      },
      (task) {
        emit(state.copyWith(
          isCreatingTask: false,
          clearTaskError: true,
          pendingTaskId: task.id,
        ));
        return true;
      },
    );
  }

  // ── Existing task select karo (API list se) ───────────────────────────────

  void selectExistingTask(AthleteTaskEntity task) {
    if (state.isSessionActive) return;
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
    if (token.isEmpty || baseUrl.isEmpty) return;
    _socketService.connect(baseUrl, token);
  }

  // ── Session start (user ne tap kiya) ──────────────────────────────────────

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

    emit(state.copyWith(
      activeSession: session,
      elapsedSeconds: 0,
      activeTaskId: taskId,
      clearPendingTaskId: true,
    ));

    _connectSocket();
    emit(state.copyWith(isSocketConnected: true, isSocketReconnecting: false));
    _startTimer();
  }

  // User ne stop button dabaya — server se confirmation ka wait karo
  void requestStopSession() {
    final taskId = state.activeTaskId;

    // Timer turant cancel karo taaki heartbeat bhejne band ho
    _timer?.cancel();
    _timer = null;

    if (taskId != null) {
      emit(state.copyWith(isStoppingSession: true));
      _socketService.stopTask(taskId);

      // Server 8 sec mein respond na kare to forcefully end karo
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

  // Server se recording_stopped aane pe ya fallback pe call hota hai
  void _endSession() {
    _timer?.cancel();
    _timer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _stopTimeoutTimer?.cancel();
    _stopTimeoutTimer = null;
    _socketService.disconnect();

    if (state.activeSession == null) return;

    final completed = state.activeSession!.copyWith(
      endTime: DateTime.now(),
      isCompleted: true,
    );

    emit(state.copyWith(
      sessions: [completed, ...state.sessions],
      clearActiveSession: true,
      elapsedSeconds: 0,
      isStoppingSession: false,
      clearActiveTaskId: true,
      clearPendingTaskId: true,
    ));
  }

  void recordHeartRate(int bpm) {
    if (!state.isSessionActive || bpm <= 0) return;

    final sample = HeartRateSample(time: DateTime.now(), bpm: bpm);
    final updated = state.activeSession!.copyWith(
      heartRateSamples: [...state.activeSession!.heartRateSamples, sample],
    );
    emit(state.copyWith(activeSession: updated));
  }

  void updateBiometrics({
    double? sugarLevel,
    double? spo2,
    int? stressLevel,
    double? hrv,
  }) {
    emit(state.copyWith(
      sugarLevel: sugarLevel,
      spo2: spo2,
      stressLevel: stressLevel,
      hrv: hrv,
    ));
  }

  // ── Timer — har second elapsed update + heartbeat emit ───────────────────

  void _startTimer() {
    _timer?.cancel();
    _autoStopTimer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isSessionActive) {
        _timer?.cancel();
        return;
      }

      emit(state.copyWith(elapsedSeconds: state.elapsedSeconds + 1));

      // Latest biometrics socket pe bhejo
      final taskId = state.activeTaskId;
      final latestBpm = state.activeSession?.heartRateSamples.isNotEmpty == true
          ? state.activeSession!.heartRateSamples.last.bpm
          : 0;
      if (taskId != null && latestBpm > 0) {
        _socketService.submitHeartbeat(
          taskId: taskId,
          heartRate: latestBpm,
          sugarLevel: state.sugarLevel,
          spo2: state.spo2,
          lat: state.lat,
          lng: state.lng,
          stressLevel: state.stressLevel,
          hrv: state.hrv,
        );
      }
    });

    // Exact duration ke baad ek baar fire — tick-by-tick check se zyada reliable
    final targetDuration =
        Duration(minutes: state.activeSession!.targetDurationMinutes);
    _autoStopTimer = Timer(targetDuration, () {
      if (!isClosed && state.isSessionActive) {
        requestStopSession();
      }
    });
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
    _reconnectTimer?.cancel();
    _socketService.disconnect();
    return super.close();
  }
}
