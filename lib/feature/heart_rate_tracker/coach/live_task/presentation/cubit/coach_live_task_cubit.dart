import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/service/socket/coach_live_task_socket_service.dart';
import 'coach_live_task_state.dart';

class CoachLiveTaskCubit extends Cubit<CoachLiveTaskState>
    with WidgetsBindingObserver {
  final CoachLiveTaskSocketService _socketService;
  final SharedPreferences _prefs;

  static const int _maxReadings = 60;

  int? _currentTaskId;
  Timer? _reconnectTimer;

  CoachLiveTaskCubit({
    required CoachLiveTaskSocketService socketService,
    required SharedPreferences prefs,
  })  : _socketService = socketService,
        _prefs = prefs,
        super(const CoachLiveTaskState()) {
    WidgetsBinding.instance.addObserver(this);
    _setupCallbacks();
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
        emit(state.copyWith(status: CoachLiveTaskStatus.watching));
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

    _socketService.onDisconnected = () {
      if (!isClosed && state.status == CoachLiveTaskStatus.watching) {
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
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      final taskId = _currentTaskId;
      if (!isClosed && taskId != null && !_socketService.isConnected) {
        debugPrint('[COACH CUBIT] Reconnecting for task $taskId');
        startWatching(taskId);
      }
    });
  }

  // Coach jab live task screen open kare tab call karo
  void startWatching(int taskId) {
    _currentTaskId = taskId;
    final token = _prefs.getString(PrefKeys.coachToken) ?? '';
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    if (token.isEmpty || baseUrl.isEmpty) return;

    emit(const CoachLiveTaskState(status: CoachLiveTaskStatus.connecting));

    // watch_task_results sirf tab emit karo jab socket actually connect ho jaye
    _socketService.connect(baseUrl, token, onConnected: () {
      if (!isClosed) _socketService.watchTask(taskId);
    });
  }

  // Coach jab page chhode tab call karo
  void stopWatching(int taskId) {
    _currentTaskId = null;
    _reconnectTimer?.cancel();
    _socketService.unwatchTask(taskId);
    _socketService.disconnect();
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _socketService.disconnect();
    return super.close();
  }
}
