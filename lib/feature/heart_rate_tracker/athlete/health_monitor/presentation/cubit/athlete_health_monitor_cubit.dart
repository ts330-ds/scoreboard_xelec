import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/service/socket/athlete_health_monitor_socket_service.dart';

enum HealthMonitorStatus { idle, connecting, monitoring, error }

class AthleteHealthMonitorCubit extends Cubit<HealthMonitorStatus>
    with WidgetsBindingObserver {
  final AthleteHealthMonitorSocketService _socketService;
  final HeartBleCubit _bleCubit;
  final SharedPreferences _prefs;

  StreamSubscription<HeartBleState>? _bleSubscription;
  Timer? _metricTimer;
  Timer? _reconnectTimer;
  // BLE disconnect ke baad itni der wait karo — short glitches ignore hote hain
  Timer? _bleDisconnectDebounce;

  int _heartRate = 0;
  double? _spo2;
  int? _stressLevel;
  double? _hrv;
  bool _appInForeground = true;

  AthleteHealthMonitorCubit({
    required AthleteHealthMonitorSocketService socketService,
    required HeartBleCubit bleCubit,
    required SharedPreferences prefs,
  })  : _socketService = socketService,
        _bleCubit = bleCubit,
        _prefs = prefs,
        super(HealthMonitorStatus.idle) {
    WidgetsBinding.instance.addObserver(this);
    _listenToBle();
  }

  // ── App Lifecycle ───────────────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _appInForeground = false;
        // Metric timer background me bhi chalta rahe — socket alive + data flowing
        debugPrint('[HEALTH MONITOR] App paused — socket + metric timer kept alive');
        break;

      case AppLifecycleState.resumed:
        _appInForeground = true;
        debugPrint('[HEALTH MONITOR] App resumed — checking socket state');
        _onAppResumed();
        break;

      default:
        break;
    }
  }

  void _onAppResumed() {
    if (_bleCubit.state.isConnected && !_socketService.isConnected) {
      // BLE hai lekin socket gir gaya — reconnect
      debugPrint('[HEALTH MONITOR] Resumed — socket dropped, reconnecting');
      if (!isClosed) emit(HealthMonitorStatus.connecting);
      _connectAndStart();
    }
    // Socket connected: timer already running in background, nothing to do
  }

  // ── BLE listener ────────────────────────────────────────────────────────────
  void _listenToBle() {
    _bleSubscription = _bleCubit.stream.listen(_onBleStateChanged);
    if (_bleCubit.state.isConnected) _onBleStateChanged(_bleCubit.state);
  }

  void _onBleStateChanged(HeartBleState bleState) {
    _heartRate = bleState.heartRate;
    if (bleState.spo2 > 0) _spo2 = bleState.spo2.toDouble();
    if (bleState.stressLevel > 0) _stressLevel = bleState.stressLevel;
    if (bleState.hrv > 0) _hrv = bleState.hrv;

    if (bleState.isConnected) {
      // BLE wapas aaya — pending debounce cancel karo
      _bleDisconnectDebounce?.cancel();
      _bleDisconnectDebounce = null;

      if (!_socketService.isConnected &&
          (state == HealthMonitorStatus.idle ||
              state == HealthMonitorStatus.error)) {
        _connectAndStart();
      } else if (_socketService.isConnected &&
          state == HealthMonitorStatus.monitoring &&
          _metricTimer == null &&
          _appInForeground) {
        // Socket connected but timer stopped (app was paused) — restart
        _startMetricTimer();
      }
    } else {
      // BLE disconnected — 12 second debounce (screen lock/unlock ignore ho)
      if (_bleDisconnectDebounce != null) return;
      _bleDisconnectDebounce = Timer(const Duration(seconds: 12), () {
        _bleDisconnectDebounce = null;
        if (!_bleCubit.state.isConnected && _socketService.isConnected) {
          debugPrint('[HEALTH MONITOR] BLE disconnected (confirmed after debounce)');
          _stopAndDisconnect();
        }
      });
    }
  }

  // ── Socket connect ──────────────────────────────────────────────────────────
  void _connectAndStart() {
    final token = _prefs.getString(PrefKeys.userToken) ?? '';
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    if (token.isEmpty || baseUrl.isEmpty) return;

    if (!isClosed) emit(HealthMonitorStatus.connecting);

    _socketService.onMonitoringStarted = () {
      debugPrint('[HEALTH MONITOR] Monitoring started');
      _reconnectTimer?.cancel();
      if (!isClosed) emit(HealthMonitorStatus.monitoring);
      _startMetricTimer();
    };

    _socketService.onMonitoringStopped = () {
      debugPrint('[HEALTH MONITOR] Monitoring stopped');
      _stopMetricTimer();
      if (!isClosed) emit(HealthMonitorStatus.idle);
    };

    _socketService.onError = (msg) {
      debugPrint('[HEALTH MONITOR] Error: $msg');
      if (!isClosed) emit(HealthMonitorStatus.error);
      _scheduleReconnect();
    };

    // Socket OS ke wajah se drop ho jaaye to status update karo
    _socketService.onSocketDisconnected = () {
      debugPrint('[HEALTH MONITOR] Socket dropped unexpectedly');
      _stopMetricTimer();
      if (!isClosed && state == HealthMonitorStatus.monitoring) {
        emit(HealthMonitorStatus.error);
        if (_bleCubit.state.isConnected) _scheduleReconnect();
      }
    };

    _socketService.connect(baseUrl, token);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!isClosed && _bleCubit.state.isConnected && !_socketService.isConnected) {
        debugPrint('[HEALTH MONITOR] Reconnecting...');
        _connectAndStart();
      }
    });
  }

  // ── Metric timer ────────────────────────────────────────────────────────────
  void _startMetricTimer() {
    _metricTimer?.cancel();
    _metricTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_heartRate <= 0) return;
      _socketService.submitHealthMetric(
        heartRate: _heartRate,
        spo2: _spo2,
        stressLevel: _stressLevel,
        hrv: _hrv,
      );
    });
  }

  void _stopMetricTimer() {
    _metricTimer?.cancel();
    _metricTimer = null;
  }

  void _stopAndDisconnect() {
    _stopMetricTimer();
    _reconnectTimer?.cancel();
    _socketService.notifyDeviceDisconnected();
    Future.delayed(const Duration(seconds: 3), () {
      if (_socketService.isConnected) _socketService.disconnect();
      if (!isClosed) emit(HealthMonitorStatus.idle);
    });
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _bleSubscription?.cancel();
    _bleDisconnectDebounce?.cancel();
    _stopMetricTimer();
    _reconnectTimer?.cancel();
    if (_socketService.isConnected) {
      _socketService.notifyDeviceDisconnected();
      _socketService.disconnect();
    }
    return super.close();
  }
}
