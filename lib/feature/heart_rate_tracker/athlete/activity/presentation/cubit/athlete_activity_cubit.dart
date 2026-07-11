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
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/domain/usecase/get_my_tasks_usecase.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_zip_submit_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/task_zip_submit_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/service/foreground/athlete_foreground_service.dart';
import 'package:xelex_esp/service/network/network_reconnect_notifier.dart';
import 'package:xelex_esp/service/socket/reconnect_controller.dart';
import 'athlete_activity_state.dart';

class AthleteActivityCubit extends Cubit<AthleteActivityState>
    with WidgetsBindingObserver {
  final CreateAthleteTaskUseCase _createTask;
  final GetMyTasksUseCase _getMyTasks;
  final SharedPreferences _prefs;
  final HeartBleCubit _bleCubit;

  // Socket ab yahan nahi — background isolate mein.
  // Cubit ka kaam: UI state, timer, BLE data forwarding, events receive karna.

  AthleteActivityCubit({
    required CreateAthleteTaskUseCase createTask,
    required GetMyTasksUseCase getMyTasks,
    required SharedPreferences prefs,
    required HeartBleCubit bleCubit,
  })  : _createTask = createTask,
        _getMyTasks = getMyTasks,
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
      if (isClosed ||
          !state.isSessionActive ||
          state.isAuthFailure ||
          state.isStoppingSession) {
        return;
      }
      if (!state.isSocketConnected) {
        debugPrint('[ACTIVITY CUBIT] network restored — forcing retry');
        retryConnectionManually();
      }
    });
  }

  /// Active upload cubits — kept alive so uploads continue even if
  /// the user navigates away. Cleaned up when upload completes.
  final List<TaskZipSubmitCubit> _activeUploads = [];

  /// Creates a new upload cubit for a session, keeps reference alive.
  TaskZipSubmitCubit createUploadCubit(TaskZipSubmitCubit cubit) {
    _activeUploads.add(cubit);
    late final StreamSubscription<TaskZipSubmitState> sub;
    sub = cubit.stream.listen((uploadState) {
      if (isClosed) return;
      if (uploadState.status == TaskZipStatus.complete) {
        _activeUploads.remove(cubit);
        sub.cancel();
        cubit.close();
      }
    });
    return cubit;
  }

  void cleanupUploadCubit(TaskZipSubmitCubit cubit) {
    _activeUploads.remove(cubit);
    cubit.close();
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
      // Device wapas connect hua — reconnect loop band karo
      _bleReconnectTimer?.cancel();
      _bleReconnectTimer = null;
    } else if (!nowConnected && _bleWasConnected) {
      if (!state.isSessionActive) {
        AthleteForegroundService.stopIfIdle();
      } else {
        // Session active hai aur device disconnect hua — periodic reconnect shuru
        _startBleReconnectLoop();
      }
    }
    _bleWasConnected = nowConnected;

    if (!state.isSessionActive) return;

    final spo2 = bleState.spo2 > 0 ? bleState.spo2.toDouble() : null;
    final stress = bleState.stressLevel > 0 ? bleState.stressLevel : null;
    final hrv = bleState.hrv > 0 ? bleState.hrv : null;

    if (bleState.heartRate > 0) {
      // Biometrics ko pehle state mein update karo (forward NAHI), phir
      // recordHeartRate ek hi IPC call mein HR + freshest biometrics forward
      // kare. Warna har BLE tick pe updateMetrics background ko DO baar jaata
      // tha (recordHeartRate + updateBiometrics dono se).
      updateBiometrics(spo2: spo2, stressLevel: stress, hrv: hrv, forward: false);
      recordHeartRate(bleState.heartRate);
    } else if (!nowConnected) {
      // Device disconnect ho gaya (band off / out of range). BG handler ka
      // _heartRate apni aakhri value pe atak jaata hai aur har 1s wahi (jhooti)
      // flat-line server pe bhejta rehta hai. Isliye BG ko HR=0 forward karke
      // clear karo — server pe jhooti reading ki jagah honest gap aaye. Reconnect
      // hote hi real HR wapas flow karega. (updateBiometrics yahan use nahi kar
      // sakte — wo last valid bpm forward kar deta, jo dobara stale HR bhej deta.)
      AthleteForegroundService.updateMetrics(
        heartRate: 0,
        lat: state.lat,
        lng: state.lng,
      );
    } else {
      // Connected hai par HR abhi 0 (sensor warm-up) — biometrics aage bhejo.
      updateBiometrics(spo2: spo2, stressLevel: stress, hrv: hrv);
    }
  }

  // ── BLE reconnect loop ────────────────────────────────────────────────────
  // Session active hai aur device out of range chala gaya — har 30s pe
  // reconnect attempt karo. Jab device wapas range mein aayega, connect
  // hoga aur _onBleState mein timer cancel ho jayega.

  void _startBleReconnectLoop() {
    _bleReconnectTimer?.cancel();
    _bleReconnectTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isClosed || !state.isSessionActive || _bleCubit.state.isConnected) {
        _bleReconnectTimer?.cancel();
        _bleReconnectTimer = null;
        return;
      }
      debugPrint('[CUBIT] BLE reconnect attempt — device disconnected during session');
      _bleCubit.reconnectLastDevice();
    });
    // Pehla attempt turant — 30s wait mat karo
    _bleCubit.reconnectLastDevice();
  }

  // UI ke liye timer — sirf elapsed seconds update karta hai
  Timer? _timer;
  // Auto-stop — jab duration puri ho
  Timer? _autoStopTimer;
  // Server se response na aaye to fallback
  Timer? _stopTimeoutTimer;
  // BLE reconnect timer — jab session active hai aur device out of range ho
  Timer? _bleReconnectTimer;
  // Connection watchdog — event-independent safety net. Disconnect/reconnect
  // loops sirf disconnect EVENT pe trigger hote hain; lekin agar start_activity
  // command BG isolate tak na pahunche (bg_ready race) ya connect attempt hi na
  // ho, to koi event aata hi nahi aur task pura session 'pending' reh jaata hai.
  // Ye timer har few-seconds check karta hai — session active aur socket
  // disconnected ho to connect dobara trigger karta hai (BG connect() idempotent
  // hai). Connect hote hi (first ping → task_result_saved) ruk-ruk ke band ho
  // jaata hai kyunki isSocketConnected true ho jaata hai.
  Timer? _connWatchdog;
  static const _connWatchdogInterval = Duration(seconds: 5);
  final ReconnectController _reconnect = ReconnectController(tag: 'ACTIVITY RECONNECT');
  static const _uuid = Uuid();

  // ── Background events ───────────────────────────────────────────────────────
  // Background isolate se socket events aate hain yahan.
  // Event naam 'activity_' prefix se start hote hain — health monitor events ignore ho jaate hain.

  void _onBackgroundEvent(Map<String, dynamic> data) {
    if (isClosed) return;
    final event = data['event'] as String?;
    debugPrint('🛑 [SESSION DEBUG] BG event received: $event — isSessionActive=${state.isSessionActive}');

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
        debugPrint('🛑 [SESSION DEBUG] BG event: activity_recording_stopped — data=$data');
        _stopTimeoutTimer?.cancel();
        _stopTimeoutTimer = null;
        _endSession(stopConfirmed: true);

      case 'activity_stop_abandoned':
        // BG ne pending stop deadline cross hone pe chhod diya (internet bahut
        // der off raha). UI to pehle hi end ho chuka — ab sirf service tear
        // down karo taaki wo hamesha alive na rahe.
        debugPrint('🛑 [SESSION DEBUG] BG event: activity_stop_abandoned');
        _stopTimeoutTimer?.cancel();
        _stopTimeoutTimer = null;
        _endSession(stopConfirmed: true);

      case 'activity_disconnected':
        // Stop ke dauraan disconnect EXPECTED hai — tab reconnect mat schedule
        // karo (warna stop window mein socket resurrect ho jaata hai).
        if (!isClosed &&
            state.isSessionActive &&
            !state.isAuthFailure &&
            !state.isStoppingSession) {
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
        if (isClosed || !state.isSessionActive || state.isStoppingSession) return;
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
  // Elapsed hamesha wall-clock (session.startTime) se derive hota hai — isliye
  // resume pe seedha `now - startTime` reconcile ho jaata hai. Ye kisi bhi
  // lifecycle event (paused/resumed) ke reliably fire hone pe depend nahi karta,
  // isliye aggressive OEM battery-managers (Vivo/Oppo/MIUI) pe bhi time drift nahi hota.

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isClosed) return;
    debugPrint('🛑 [SESSION DEBUG] lifecycle=$state, isSessionActive=${this.state.isSessionActive}, taskId=${this.state.activeTaskId}');
    switch (state) {
      case AppLifecycleState.paused:
        _onAppPaused();
      case AppLifecycleState.resumed:
        _onAppResumed();
      case AppLifecycleState.detached:
        // Swipe-kill / system kill pe BG handler ka onDestroy server ko
        // stop bhejta hai — yahan kuch karne ki zaroorat nahi.
        // NOTE: kuch OEMs (Vivo/Xiaomi/Samsung) pe detached wrongly fire
        // hota hai on background/minimize, jo session auto-stop kar deta tha.
        break;
      default:
        break;
    }
  }

  void _onAppPaused() {
    if (!state.isSessionActive) return;
    // UI timer cancel — background mein drift ho sakta hai. Elapsed startTime se
    // derive hota hai, isliye resume pe wall-clock se sahi value mil jaati hai —
    // koi _pausedAt track karne ki zaroorat nahi.
    _timer?.cancel();
    _timer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _bleReconnectTimer?.cancel();
    _bleReconnectTimer = null;
    debugPrint('[LIFECYCLE] Session paused');
    // NOTE: Background service chalta rehta hai — socket alive hai
  }

  void _onAppResumed() {
    // Upload cubits ko resume signal do — agar iOS ne suspend kiya tha
    // to stuck uploads auto-retry honge.
    for (final cubit in _activeUploads) {
      cubit.onAppResumed();
    }

    if (isClosed || !state.isSessionActive) return;

    final session = state.activeSession;
    if (session == null) return;

    // Wall-clock se elapsed reconcile — chahe `paused`/`resumed` reliably fire
    // hue ho ya na (kuch OEMs pe miss hote hain). _pausedAt pe depend nahi.
    final elapsed = DateTime.now().difference(session.startTime).inSeconds;
    final newElapsed = elapsed < 0 ? 0 : elapsed;
    final targetSeconds = session.targetDurationMinutes * 60;

    debugPrint('[LIFECYCLE] Resumed — elapsed(from startTime): ${newElapsed}s');

    if (targetSeconds > 0 && newElapsed >= targetSeconds) {
      debugPrint('🛑 [SESSION DEBUG] AUTO-STOP on resume — elapsed($newElapsed) >= target($targetSeconds)');
      if (isClosed) return;
      emit(state.copyWith(elapsedSeconds: targetSeconds));
      if (isClosed) return;
      requestStopSession();
      return;
    }

    if (isClosed) return;
    emit(state.copyWith(
        elapsedSeconds:
            targetSeconds > 0 ? newElapsed.clamp(0, targetSeconds) : newElapsed));

    if (isClosed || !state.isSessionActive) return;
    _startTimer();

    // Agar BLE abhi bhi disconnected hai aur session active — reconnect loop restart
    if (!_bleCubit.state.isConnected && _bleReconnectTimer == null) {
      _startBleReconnectLoop();
    }
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

  // ── Connection watchdog ──────────────────────────────────────────────────
  // Event-driven reconnect (BG handler + ReconnectController) sirf disconnect
  // EVENT par chalta hai. Agar connect attempt hi na ho (start_activity drop /
  // bg_ready race) to koi event nahi aata aur task pura session 'pending' reh
  // jaata hai. Ye watchdog us silent gap ko bharta hai.
  void _startConnWatchdog() {
    _connWatchdog?.cancel();
    _connWatchdog = Timer.periodic(_connWatchdogInterval, (_) {
      if (isClosed || !state.isSessionActive) {
        _connWatchdog?.cancel();
        _connWatchdog = null;
        return;
      }
      // Token invalid/expired — re-issue se kuch nahi hoga, user ko re-login chahiye.
      if (state.isAuthFailure) return;
      // Stop in progress — socket ko resurrect mat karo.
      if (state.isStoppingSession) return;
      // Pehle se connected hai to kuch mat karo.
      if (state.isSocketConnected) return;

      debugPrint('[CUBIT] conn watchdog — socket disconnected, re-issuing connect');
      _connectSocket();
    });
  }

  // ── Session start ──────────────────────────────────────────────────────────

  void startSession() {
    final taskId = state.pendingTaskId;
    debugPrint('🟢 [SESSION DEBUG] startSession — taskId=$taskId, duration=${state.selectedDuration}min, activity=${state.selectedActivity}');
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

    // Process death (phone off / app kill) se bachne ke liye session ko disk
    // pe persist karo — launch pe attemptSessionRecovery() ise padhega.
    _persistActiveSession(session, taskId);

    _connectSocket();
    _startConnWatchdog();
    _startTimer();
  }

  // ── Session persistence (process-death recovery) ──────────────────────────
  // Active session ko disk pe likhte hain taaki phone off / app swipe-kill ke
  // baad bhi app dobara khulne par session recover ho sake. Sirf wo cheezein
  // store karte hain jo recovery ke liye chahiye: taskId, startTime, target,
  // activity, location. (HR samples band ki memory me hain — wahan se re-fetch
  // ho jaate hain, isliye yahan store karne ki zaroorat nahi.)

  void _persistActiveSession(ActivitySession session, int taskId) {
    _prefs.setInt(PrefKeys.activeSessionTaskId, taskId);
    _prefs.setInt(
        PrefKeys.activeSessionStartMs, session.startTime.millisecondsSinceEpoch);
    _prefs.setInt(
        PrefKeys.activeSessionTargetMin, session.targetDurationMinutes);
    _prefs.setString(PrefKeys.activeSessionActivity, session.activityType);
    _prefs.setString(PrefKeys.activeSessionLocation, session.location);
  }

  void _clearPersistedSession() {
    _prefs.remove(PrefKeys.activeSessionTaskId);
    _prefs.remove(PrefKeys.activeSessionStartMs);
    _prefs.remove(PrefKeys.activeSessionTargetMin);
    _prefs.remove(PrefKeys.activeSessionActivity);
    _prefs.remove(PrefKeys.activeSessionLocation);
  }

  // ── Launch-time session recovery ──────────────────────────────────────────
  // App launch pe ek baar call karo (athlete main screen se). Agar process
  // death (phone off / app swipe-kill) se ek active session adhoori reh gayi
  // thi, to disk se padh ke `?status=in_progress` se verify karta hai:
  //   • task abhi in_progress hai  → resume (persisted startMs se sahi elapsed,
  //                                   socket reconnect + timer)
  //   • in_progress nahi (complete/khatam) → resume NAHI; persisted discard
  //   • offline / fetch fail       → kuch nahi; persisted rakho, agla launch resolve karega
  // Stale (bahut purani) session ko bhi resume nahi karta — persisted discard.
  // NOTE: `?page=1` (bina status) in_progress ko exclude karta hai, isliye
  // in_progress check ke liye status filter zaroori hai.
  static const _maxRecoveryWindow = Duration(hours: 12);

  /// Server pe `in_progress` mili session ko banner-tap pe live resume karta
  /// hai — taaki task-detail screen seedha ActiveSessionView dikhaye (na ki
  /// PendingTaskView "Start" wali). App-kill / process-death ke baad jab local
  /// `isSessionActive` gum ho chuka ho, ye us running session ko wapas wire
  /// karta hai: socket reconnect + foreground service + timer.
  ///
  /// Start time priority: persisted state (kill survive karta hai, sabse
  /// accurate) → server `startedAt` → ab (last resort). Elapsed target se
  /// upar ho to resume ki jagah clean stop bhejta hai (server complete karega).
  void resumeInProgressTask(AthleteTaskEntity task) {
    if (isClosed) return;
    // Pehle se yahi session live hai → kuch mat karo (bas navigate hoga).
    if (state.isSessionActive && state.activeTaskId == task.id) return;

    final targetMin = int.tryParse(task.duration) ?? 0;

    // Start/activity/location — persisted (agar wahi task) sabse accurate.
    DateTime startTime;
    String activity = state.selectedActivity;
    String location = '';
    final persistedId = _prefs.getInt(PrefKeys.activeSessionTaskId);
    final persistedStartMs = _prefs.getInt(PrefKeys.activeSessionStartMs);
    if (persistedId == task.id && persistedStartMs != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(persistedStartMs);
      activity = _prefs.getString(PrefKeys.activeSessionActivity) ?? activity;
      location = _prefs.getString(PrefKeys.activeSessionLocation) ?? '';
    } else {
      final serverStart =
          task.startedAt != null ? DateTime.tryParse(task.startedAt!) : null;
      startTime = serverStart?.toLocal() ?? DateTime.now();
    }

    final elapsed = DateTime.now().difference(startTime).inSeconds;
    final safeElapsed = elapsed < 0 ? 0 : elapsed;

    // Duration puri ho chuki par server abhi in_progress — resume mat karo,
    // clean stop bhejo (server complete karega → feedback/upload chalega).
    if (targetMin > 0 && safeElapsed >= targetMin * 60) {
      _reconstructActiveSession(
          task.id, activity, targetMin, startTime, location, safeElapsed,
          task: task);
      _persistActiveSession(state.activeSession!, task.id);
      requestStopSession();
      return;
    }

    _reconstructActiveSession(
        task.id, activity, targetMin, startTime, location, safeElapsed,
        task: task);
    _persistActiveSession(state.activeSession!, task.id);
    _connectSocket();
    _startConnWatchdog();
    _startTimer();
  }

  Future<void> attemptSessionRecovery() async {
    // Pehle se koi session active hai (cubit singleton hai, dobara call ho gaya)
    // to kuch mat karo.
    if (isClosed || state.isSessionActive) return;

    final taskId = _prefs.getInt(PrefKeys.activeSessionTaskId);
    final startMs = _prefs.getInt(PrefKeys.activeSessionStartMs);
    if (taskId == null || startMs == null) return; // koi adhoori session nahi

    final startTime = DateTime.fromMillisecondsSinceEpoch(startMs);
    final targetMin = _prefs.getInt(PrefKeys.activeSessionTargetMin) ?? 0;
    final activity =
        _prefs.getString(PrefKeys.activeSessionActivity) ?? 'Running';
    final location = _prefs.getString(PrefKeys.activeSessionLocation) ?? '';
    final elapsed = DateTime.now().difference(startTime).inSeconds;

    debugPrint('🟡 [RECOVERY] persisted session mila — task=$taskId '
        'elapsed=${elapsed}s target=${targetMin}min');

    // Guard A: staleness — clock anomaly ya bahut purani session (e.g. agle din
    // khuli). Resume mat karo; persisted discard kar do (agar data chahiye to
    // task result screen ke manual "Upload Session" se ja sakta hai).
    if (elapsed < 0 ||
        DateTime.now().difference(startTime) > _maxRecoveryWindow) {
      debugPrint('🟡 [RECOVERY] stale session — discarding');
      _clearPersistedSession();
      return;
    }

    // Guard B: server pe ye session abhi bhi in_progress hai kya?
    // ZAROORI: `?page=1` (bina status) in_progress tasks ko EXCLUDE karta hai,
    // isliye `status=in_progress` chahiye. Pehle plain page-1 se check hota tha
    // → running session "task not found" ban ke galti se discard ho jaata tha,
    // aur persisted startMs (jo sahi elapsed / upload-range ka source hai) udd
    // jaata tha. Isi se resume pe timer 0 se dikhta tha aur stop pe sirf thoda
    // data fetch hota tha.
    final result = await _getMyTasks(page: 1, status: 'in_progress').run();
    if (isClosed || state.isSessionActive) return;

    result.fold(
      (failure) {
        // Offline / error — socket ko blind touch mat karo. Persisted rakho;
        // agla launch (online) resolve kar dega.
        debugPrint('🟡 [RECOVERY] in_progress fetch fail (${failure.message}) — '
            'keeping persisted for next launch');
      },
      (page) {
        AthleteTaskEntity? task;
        for (final t in page.tasks) {
          if (t.id == taskId) {
            task = t;
            break;
          }
        }

        if (task == null) {
          // Server pe ye session ab in_progress nahi (complete / khatam ho gaya)
          // — resume nahi, persisted discard. (Data chahiye to task result se
          // manual "Upload Session".)
          debugPrint('🟡 [RECOVERY] task server pe in_progress nahi — discarding');
          _clearPersistedSession();
          return;
        }

        // Abhi bhi in_progress — resume karo. Persisted startMs se elapsed sahi
        // rehta hai (real session start), isliye timer aur upload-range dono
        // theek. (Past-target ho to bhi resume — user khud stop karega.)
        debugPrint('🟡 [RECOVERY] resuming in_progress session — elapsed=${elapsed}s');
        _reconstructActiveSession(
            taskId, activity, targetMin, startTime, location, elapsed,
            task: task);
        _connectSocket();
        _startConnWatchdog();
        _startTimer();
      },
    );
  }

  // Recovered session ko UI state me wapas wire karta hai (live resume ke liye).
  // [task] pass karne par activeTask bhi set hota hai (banner-tap resume) —
  // recovery se null aata hai (tab entity available nahi hoti).
  void _reconstructActiveSession(int taskId, String activity, int targetMin,
      DateTime startTime, String location, int elapsed,
      {AthleteTaskEntity? task}) {
    final session = ActivitySession(
      id: _uuid.v4(),
      activityType: activity,
      targetDurationMinutes: targetMin,
      startTime: startTime,
      location: location,
    );
    _bleCubit.setSessionActive(true);
    emit(state.copyWith(
      activeSession: session,
      activeTask: task,
      activeTaskId: taskId,
      elapsedSeconds: targetMin > 0 ? elapsed.clamp(0, targetMin * 60) : elapsed,
      clearPendingTaskId: true,
    ));
    // App kill ke baad cold launch — band ka connection toot chuka hai aur
    // disconnect EVENT kabhi nahi aayega (jo normal reconnect loop trigger
    // karta hai). Isliye yahan explicitly loop chalu karo — pehla attempt
    // turant hota hai, connect hote hi loop khud cancel ho jaata hai.
    if (!_bleCubit.state.isConnected) {
      _startBleReconnectLoop();
    }
  }

  void requestStopSession() {
    if (isClosed) return;
    final taskId = state.activeTaskId;
    debugPrint('🛑 [SESSION DEBUG] requestStopSession called — taskId=$taskId, isSessionActive=${state.isSessionActive}');
    debugPrint('🛑 [SESSION DEBUG] caller stack: ${StackTrace.current.toString().split('\n').take(5).join(' | ')}');

    _timer?.cancel();
    _timer = null;

    if (taskId != null) {
      emit(state.copyWith(isStoppingSession: true));
      // Background ko stop command bhejo
      AthleteForegroundService.stopActivitySession(taskId);

      _stopTimeoutTimer?.cancel();
      _stopTimeoutTimer = Timer(const Duration(seconds: 8), () {
        if (!isClosed && state.isStoppingSession) {
          debugPrint('🛑 [SESSION DEBUG] 8s stop TIMEOUT — ending UI, service alive for BG delivery');
          _endSession(stopConfirmed: false);
        }
      });
    } else {
      // Koi server-task hi nahi — kuch deliver nahi karna, service safe to stop.
      _endSession(stopConfirmed: true);
    }
  }

  /// [stopConfirmed]: true jab server ne stop confirm kiya (`activity_recording_stopped`)
  /// ya koi server-task hi nahi tha (taskId == null) ya BG ne stop abandon kiya.
  /// Sirf is case mein foreground service tear down hoti hai. false (8s timeout /
  /// offline) pe UI to end hota hai par service ALIVE rehti hai taaki BG isolate
  /// connectivity wapas aate hi pending stop deliver kar sake (Layer 1).
  void _endSession({bool stopConfirmed = false}) {
    debugPrint('🛑 [SESSION DEBUG] _endSession called — activeTaskId=${state.activeTaskId}, isSessionActive=${state.isSessionActive}, stopConfirmed=$stopConfirmed');
    debugPrint('🛑 [SESSION DEBUG] _endSession caller: ${StackTrace.current.toString().split('\n').take(5).join(' | ')}');
    _bleCubit.setSessionActive(false);
    _timer?.cancel();
    _timer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _stopTimeoutTimer?.cancel();
    _stopTimeoutTimer = null;
    _bleReconnectTimer?.cancel();
    _bleReconnectTimer = null;
    _connWatchdog?.cancel();
    _connWatchdog = null;
    _reconnect.cancel();
    // UI session end ho chuki — disk se persisted session hata do. Iske baad
    // recovery kabhi is session ko resume na kare (stop delivery BG ka kaam hai).
    _clearPersistedSession();

    if (isClosed) return;
    // Session pehle hi end ho chuka (duplicate stop event / 8s timeout +
    // real event dono) — dobara complete-session add mat karo, par stopping
    // spinner ko stuck mat chhodo.
    if (state.activeSession == null) {
      // UI session pehle hi end ho chuka (8s timeout). Agar ye confirmed stop /
      // abandon late aaya hai, to ab service tear down karo — Layer 1 ne usse
      // pending-stop delivery ke liye alive rakha tha.
      if (stopConfirmed) AthleteForegroundService.cleanupAfterSessionEnd();
      if (state.isStoppingSession) {
        emit(state.copyWith(isStoppingSession: false));
      }
      return;
    }

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

    if (stopConfirmed) {
      AthleteForegroundService.cleanupAfterSessionEnd();
    } else {
      // Stop abhi server pe deliver nahi hua (offline / 8s timeout). UI end kar
      // diya, par foreground service ALIVE rakho — BG isolate connectivity wapas
      // aate hi stop deliver karega. Service tab band hogi jab BG
      // 'activity_recording_stopped' (delivered) ya 'activity_stop_abandoned'
      // (deadline cross) bhejega.
      debugPrint('🛑 [SESSION DEBUG] stop unconfirmed — service alive for BG delivery');
    }
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
    // Defensive upper bound — unbounded memory growth rokne ke liye. 50k samples
    // ~13.8 ghante @ 1Hz, yani koi bhi realistic session iske paas nahi aata
    // (count display aur .last dono unaffected rehte hain). Sirf pathological
    // high-rate / stuck-session edge case mein trigger hota hai.
    const maxSamples = 50000;
    final appended = [...session.heartRateSamples, sample];
    final updated = session.copyWith(
      heartRateSamples: appended.length > maxSamples
          ? appended.sublist(appended.length - maxSamples)
          : appended,
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
    // false hone par sirf state update — background ko forward nahi. Caller
    // (_onBleState) HR ke saath ek hi baar forward karta hai, duplicate IPC se
    // bachne ke liye.
    bool forward = true,
  }) {
    if (isClosed) return;
    emit(state.copyWith(
      sugarLevel: sugarLevel,
      spo2: spo2,
      stressLevel: stressLevel,
      hrv: hrv,
    ));

    // Latest biometrics background ko forward karo
    if (forward && state.isSessionActive) {
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

    final targetMinutes = session.targetDurationMinutes;
    final targetSeconds = targetMinutes * 60;

    // Elapsed hamesha wall-clock (startTime) se — counter increment se nahi.
    // Isse timer drift nahi karta aur missed lifecycle events pe bhi sahi rehta.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed || !state.isSessionActive) {
        _timer?.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(session.startTime).inSeconds;
      final safe = elapsed < 0 ? 0 : elapsed;
      emit(state.copyWith(
          elapsedSeconds:
              targetSeconds > 0 ? safe.clamp(0, targetSeconds) : safe));
    });

    if (targetMinutes > 0) {
      final remaining = targetSeconds - state.elapsedSeconds;
      if (remaining > 0) {
        _autoStopTimer = Timer(Duration(seconds: remaining), () {
          if (!isClosed && state.isSessionActive) {
            debugPrint('🛑 [SESSION DEBUG] AUTO-STOP timer fired — remaining was ${remaining}s');
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
    _bleReconnectTimer?.cancel();
    _connWatchdog?.cancel();
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
