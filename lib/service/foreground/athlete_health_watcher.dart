import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/service/foreground/athlete_foreground_service.dart';

// Yeh ek pure Dart service hai — koi Cubit nahi, koi Widget nahi.
// Iska ek hi kaam: HeartBleCubit listen karo, BLE connect hote hi
// foreground service shuru karo.
//
// Kyun alag service? Kyunki AthleteHealthMonitorCubit tab banta hai jab
// athlete dashboard screen khulti hai. Yeh watcher main.dart mein
// seedha initialize hota hai — kisi screen ka wait nahi karta.
class AthleteHealthWatcher with WidgetsBindingObserver {
  final HeartBleCubit _bleCubit;
  final SharedPreferences _prefs;

  StreamSubscription<HeartBleState>? _bleSub;
  Timer? _bleDisconnectDebounce;
  bool _monitoring = false;

  AthleteHealthWatcher({
    required HeartBleCubit bleCubit,
    required SharedPreferences prefs,
  })  : _bleCubit = bleCubit,
        _prefs = prefs;

  // main.dart se call karo — ek baar.
  void start() {
    WidgetsBinding.instance.addObserver(this);
    _bleSub = _bleCubit.stream.listen(_onBleState);
    // Agar app start hone ke waqt BLE already connected thi
    if (_bleCubit.state.isConnected) {
      _onBleState(_bleCubit.state);
    }
    debugPrint('[HEALTH WATCHER] Started — listening to BLE');
  }

  // App resume hone pe check karo — agar BLE connected hai lekin
  // foreground service band ho gayi thi to dobara shuru karo
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _bleCubit.state.isConnected &&
        !_monitoring) {
      debugPrint('[HEALTH WATCHER] App resumed — restarting monitor');
      _startMonitoring();
    }
  }

  void _onBleState(HeartBleState state) {
    if (state.isConnected) {
      // BLE connected — pending disconnect debounce cancel karo
      _bleDisconnectDebounce?.cancel();
      _bleDisconnectDebounce = null;

      // Latest sensor data forward karo background handler ko
      AthleteForegroundService.updateMetrics(
        heartRate: state.heartRate,
        spo2: state.spo2 > 0 ? state.spo2.toDouble() : null,
        stressLevel: state.stressLevel > 0 ? state.stressLevel : null,
        hrv: state.hrv > 0 ? state.hrv : null,
      );

      // Pehli baar connect hua — foreground service shuru karo
      if (!_monitoring) {
        _startMonitoring();
      }
    } else {
      // BLE disconnect — turant band mat karo, 12 sec wait karo
      // (screen lock/unlock ya short glitch me disconnect hota hai)
      if (_bleDisconnectDebounce != null) return;
      _bleDisconnectDebounce = Timer(const Duration(seconds: 12), () {
        _bleDisconnectDebounce = null;
        if (!_bleCubit.state.isConnected && _monitoring) {
          debugPrint('[HEALTH WATCHER] BLE disconnected — stopping monitor');
          _stopMonitoring();
        }
      });
    }
  }

  void _startMonitoring() {
    final token = _prefs.getString(PrefKeys.userToken) ?? '';
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    debugPrint('[HEALTH WATCHER] _startMonitoring — token=${token.isNotEmpty ? "ok" : "EMPTY"} baseUrl=${baseUrl.isNotEmpty ? baseUrl : "EMPTY"}');
    if (token.isEmpty || baseUrl.isEmpty) return;

    _monitoring = true;
    debugPrint('[HEALTH WATCHER] BLE connected — starting foreground service');
    AthleteForegroundService.startHealthMonitor(token, baseUrl);
  }

  void _stopMonitoring() {
    _monitoring = false;
    AthleteForegroundService.stopHealthMonitor();
  }

  // Athlete logout pe call karo
  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _bleSub?.cancel();
    _bleDisconnectDebounce?.cancel();
    if (_monitoring) _stopMonitoring();
    debugPrint('[HEALTH WATCHER] Stopped');
  }
}
