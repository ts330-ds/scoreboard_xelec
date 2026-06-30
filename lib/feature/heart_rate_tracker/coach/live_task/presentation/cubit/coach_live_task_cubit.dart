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
  // App background me hai to reconnect attempts schedule mat karo — OS timers
  // throttle karta hai aur network restricted hota hai, budget waste jaata hai.
  bool _isBackgrounded = false;
  final ReconnectController _reconnect = ReconnectController(tag: 'COACH RECONNECT');
  StreamSubscription<void>? _netSub;
  // Athlete disconnect ka banner sirf tab dikhao jab sach mein lamba cut ho.
  // Quick reconnect (Vivo flicker) pe coach ko disturb nahi karna.
  Timer? _connectionLostDebounce;
  static const _connectionLostDelay = Duration(seconds: 6);

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
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _onAppPaused();
    }
  }

  void _onAppPaused() {
    // Screen off / app background. Pending reconnect cancel karo taaki
    // background me attempts waste na hon aur 2-min budget na khatm ho —
    // resume pe fresh reconnect karenge.
    _isBackgrounded = true;
    _reconnect.cancel();
  }

  void _onAppResumed() {
    _isBackgrounded = false;
    final taskId = _currentTaskId;
    if (taskId == null || state.isAuthFailure) return;
    if (!_socketService.isConnected) {
      debugPrint('[LIFECYCLE] Coach socket dropped — reconnecting for task $taskId');
      // startWatching nahi — woh state wipe kar deta hai (readings, vitals sab gayab).
      // Sirf socket reconnect karo, existing data preserve rakhke.
      _reconnect.reset();
      emit(state.copyWith(
        status: CoachLiveTaskStatus.reconnecting,
        isReconnectExhausted: false,
        reconnectAttempt: 0,
      ));
      _connectAndWatch(taskId);
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
      // Athlete reconnect ho gaya — pending disconnect banner cancel karo
      _connectionLostDebounce?.cancel();
      _connectionLostDebounce = null;
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
      if (isClosed) return;
      // Turant banner mat dikhao — 6s wait karo.
      // Agar is dauran live data aa jaye (athlete reconnect ho gaya) to
      // timer cancel ho jayega aur coach ko kuch dikhe ga hi nahi.
      _connectionLostDebounce?.cancel();
      _connectionLostDebounce = Timer(_connectionLostDelay, () {
        if (!isClosed) {
          debugPrint('[COACH CUBIT] athlete still disconnected after ${_connectionLostDelay.inSeconds}s — showing banner');
          emit(state.copyWith(isAthleteConnectionLost: true));
        }
      });
    };

    _socketService.onDisconnected = () {
      // `connecting` bhi include — warna pehla connect fail hone par kabhi
      // reconnect schedule hi nahi hota aur screen "Connecting…" pe atak jaati
      // (same fix jo TeamLiveCubit me hai).
      if (!isClosed &&
          (state.status == CoachLiveTaskStatus.watching ||
              state.status == CoachLiveTaskStatus.reconnecting ||
              state.status == CoachLiveTaskStatus.connecting) &&
          !state.isAuthFailure) {
        debugPrint('[COACH CUBIT] Socket dropped — scheduling reconnect');
        emit(state.copyWith(status: CoachLiveTaskStatus.reconnecting));
        // Background me schedule mat karo — resume pe _onAppResumed fresh
        // reconnect kar dega.
        if (!_isBackgrounded) _scheduleReconnect();
      }
    };

    _socketService.onError = (message) {
      if (isClosed) return;
      // Active session ya reconnect ke dauran transient connect errors
      // ("Socket connection failed") ko snackbar me mat dikhao — reconnecting
      // banner already feedback de raha hai. Screen off/on pe aane wale scary
      // error flash ko isi se roka jaata hai. Initial connect ya genuine
      // errors normally surface honge.
      if (state.status == CoachLiveTaskStatus.watching ||
          state.status == CoachLiveTaskStatus.reconnecting) {
        return;
      }
      emit(state.copyWith(errorMessage: message));
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
    _connectionLostDebounce?.cancel();
    _socketService.dispose();
    return super.close();
  }
}
