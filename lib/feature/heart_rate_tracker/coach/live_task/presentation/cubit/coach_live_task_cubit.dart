import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/service/network/network_reconnect_notifier.dart';
import 'package:xelex_esp/service/socket/coach_live_task_socket_service.dart';
import 'package:xelex_esp/service/socket/reconnect_controller.dart';
import 'coach_live_task_state.dart';

class CoachLiveTaskCubit extends Cubit<CoachLiveTaskState>
    with WidgetsBindingObserver {
  final CoachLiveTaskSocketService _socketService;
  final SharedPreferences _prefs;

  static const int _maxReadings = 60;

  int? _currentTaskId;
  final ReconnectController _reconnect = ReconnectController(tag: 'COACH RECONNECT');
  StreamSubscription<void>? _netSub;

  CoachLiveTaskCubit({
    required CoachLiveTaskSocketService socketService,
    required SharedPreferences prefs,
  })  : _socketService = socketService,
        _prefs = prefs,
        super(const CoachLiveTaskState()) {
    WidgetsBinding.instance.addObserver(this);
    _setupCallbacks();
    // Network wapas aaye to coach socket bhi auto-retry kare — manual
    // Retry button ka wait nahi karna.
    _netSub = NetworkReconnectNotifier.instance.onNetworkRestored.listen((_) {
      if (isClosed || _currentTaskId == null || state.isAuthFailure) return;
      if (!_socketService.isConnected) {
        debugPrint('[COACH CUBIT] network restored — forcing retry');
        retryConnectionManually();
      }
    });
  }

  // ── App Lifecycle ─────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onAppResumed();
  }

  void _onAppResumed() {
    final taskId = _currentTaskId;
    if (taskId == null) return;
    if (!_socketService.isConnected) {
      debugPrint('[LIFECYCLE] Coach socket dropped — reconnecting for task $taskId');
      startWatching(taskId);
    }
  }

  void _setupCallbacks() {
    _socketService.onWatching = () {
      if (!isClosed) {
        // Reconnect successful — counters reset.
        _reconnect.reset();
        emit(state.copyWith(
          status: CoachLiveTaskStatus.watching,
          reconnectAttempt: 0,
          isReconnectExhausted: false,
        ));
      }
    };

    _socketService.onLiveUpdate = (reading, totalReadings) {
      if (isClosed) return;
      final updated = [...state.readings, reading];
      // Purane readings drop karo agar limit se zyada ho
      final trimmed = updated.length > _maxReadings
          ? updated.sublist(updated.length - _maxReadings)
          : updated;

      emit(state.copyWith(
        // watching_task event na aaye to pehli live update pe bhi switch karo
        status: state.status == CoachLiveTaskStatus.connecting
            ? CoachLiveTaskStatus.watching
            : state.status,
        readings: trimmed,
        totalReadings: totalReadings,
        latestBpm: reading.bpm,
        latestSugarLevel: reading.sugarLevel,
        latestSpo2: reading.spo2,
        latestLat: reading.lat,
        latestLng: reading.lng,
        latestStressLevel: reading.stressLevel,
        // Data wapas aana hi reconnect ka proof hai — banner clear karo.
        isAthleteConnectionLost: false,
      ));
    };

    _socketService.onAthleteStopped = () {
      if (!isClosed) {
        emit(state.copyWith(
          status: CoachLiveTaskStatus.athleteStopped,
          isAthleteStopped: true,
        ));
      }
    };

    _socketService.onAthleteConnectionLost = () {
      if (!isClosed) {
        // Banner ke liye flag set karo. Session end NAHI — dialog mat kholo.
        // Reconnect hone par next live_result_update flag reset kar dega.
        emit(state.copyWith(isAthleteConnectionLost: true));
      }
    };

    _socketService.onDisconnected = () {
      if (!isClosed &&
          (state.status == CoachLiveTaskStatus.watching ||
              state.status == CoachLiveTaskStatus.reconnecting) &&
          !state.isAuthFailure) {
        debugPrint('[COACH CUBIT] Socket dropped — scheduling reconnect');
        emit(state.copyWith(status: CoachLiveTaskStatus.reconnecting));
        _scheduleReconnect();
      }
    };

    _socketService.onError = (message) {
      if (!isClosed) {
        emit(state.copyWith(
          status: CoachLiveTaskStatus.error,
          errorMessage: message,
        ));
      }
    };

    _socketService.onAuthFailure = (message) {
      // Token expire/invalid — reconnect waste. UI re-login flow trigger kare.
      _reconnect.cancel();
      if (!isClosed) {
        emit(state.copyWith(
          status: CoachLiveTaskStatus.error,
          errorMessage: message,
          isAuthFailure: true,
        ));
      }
    };
  }

  void _scheduleReconnect() {
    _reconnect.schedule(
      onAttempt: (attempt) {
        final taskId = _currentTaskId;
        if (isClosed || taskId == null) return;
        if (_socketService.isConnected) return;
        debugPrint('[COACH CUBIT] Reconnect attempt #$attempt for task $taskId');
        emit(state.copyWith(reconnectAttempt: attempt));
        _connectAndWatch(taskId);
      },
      onExhausted: () {
        if (isClosed) return;
        debugPrint('[COACH CUBIT] Reconnect budget exhausted');
        emit(state.copyWith(isReconnectExhausted: true));
      },
    );
  }

  // User ne "Retry" button dabaya — budget reset, turant ek attempt.
  void retryConnectionManually() {
    final taskId = _currentTaskId;
    if (isClosed || taskId == null) return;
    _reconnect.reset();
    emit(state.copyWith(
      status: CoachLiveTaskStatus.reconnecting,
      isReconnectExhausted: false,
      reconnectAttempt: 0,
    ));
    _connectAndWatch(taskId);
  }

  void _connectAndWatch(int taskId) {
    final token = _prefs.getString(PrefKeys.coachToken) ?? '';
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    if (token.isEmpty || baseUrl.isEmpty) return;
    _socketService.connect(baseUrl, token, onConnected: () {
      if (!isClosed) _socketService.watchTask(taskId);
    });
  }

  // Coach jab live task screen open kare tab call karo
  void startWatching(int taskId) {
    _currentTaskId = taskId;
    final token = _prefs.getString(PrefKeys.coachToken) ?? '';
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    if (token.isEmpty || baseUrl.isEmpty) return;

    _reconnect.reset();
    emit(const CoachLiveTaskState(status: CoachLiveTaskStatus.connecting));

    // watch_task_results sirf tab emit karo jab socket actually connect ho jaye
    _socketService.connect(baseUrl, token, onConnected: () {
      if (!isClosed) _socketService.watchTask(taskId);
    });
  }

  // Coach jab page chhode tab call karo
  void stopWatching(int taskId) {
    _currentTaskId = null;
    _reconnect.cancel();
    _socketService.unwatchTask(taskId);
    _socketService.disconnect();
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnect.dispose();
    _netSub?.cancel();
    _socketService.disconnect();
    return super.close();
  }
}
