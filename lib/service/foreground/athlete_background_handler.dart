import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:xelex_esp/service/socket/athlete_health_monitor_socket_service.dart';
import 'package:xelex_esp/service/socket/athlete_task_socket_service.dart';

// @pragma annotation zaroori hai — warna release build mein tree shaking
// is function ko remove kar deta hai kyunki isko koi directly call nahi karta.
// Flutter foreground task isko string naam se dhundh ke call karta hai.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(AthleteBackgroundHandler());
}

// Yeh class background isolate mein run hogi.
// Main isolate se bilkul alag — apne khud ke socket instances banayegi.
class AthleteBackgroundHandler extends TaskHandler {
  // Background isolate ke khud ke socket instances.
  // Main isolate wale socket services yahan available nahi hain.
  late final AthleteHealthMonitorSocketService _healthSocket;
  late final AthleteTaskSocketService _taskSocket;

  // Latest sensor values — main isolate 'update_metrics' bhejta hai
  // aur yahan store hote hain. onRepeatEvent inhe use karta hai.
  int _heartRate = 0;
  double? _spo2;
  int? _stressLevel;
  double? _hrv;
  double? _lat;
  double? _lng;

  // State tracking
  bool _healthActive = false;
  int? _activeTaskId;
  bool _readyAnnounced = false;
  // Track if we initiated the disconnect (BLE chla gaya / user logout) — us case
  // me socket-disconnect ko error nahi treat karna chahiye.
  bool _intentionalHealthDisconnect = false;

  // Notification throttle — onRepeatEvent har 1s pe fire hota hai, lekin
  // notification ko har 3s pe update karte hain (battery + OEM spam-filter ke liye).
  int _notifTick = 0;
  int _lastShownBpm = -1;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[BG HANDLER] onStart — background isolate ready');
    _healthSocket = AthleteHealthMonitorSocketService();
    _taskSocket = AthleteTaskSocketService();
    _setupHealthSocketCallbacks();
    _setupActivitySocketCallbacks();
    // Note: bg_ready event onStart se directly bhejne pe main tak reliably
    // nahi pahunchta — IPC channel onStart ke andar abhi fully wired nahi
    // hota. Isliye onRepeatEvent ke first tick me bhejte hain (max 1s wait).
  }

  // Yeh method har 1 second pe fire hoti hai (foreground task options mein set kiya hai).
  // Yahan socket pe data bhejte hain — yeh timer ka replacement hai.
  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!_readyAnnounced) {
      _readyAnnounced = true;
      FlutterForegroundTask.sendDataToMain({'event': 'bg_ready'});
    }

    if (_healthActive && _heartRate > 0 && _healthSocket.isConnected) {
      _healthSocket.submitHealthMetric(
        heartRate: _heartRate,
        spo2: _spo2,
        stressLevel: _stressLevel,
        hrv: _hrv,
        lat: _lat,
        lng: _lng,
      );
    }

    if (_activeTaskId != null && _heartRate > 0 && _taskSocket.isConnected) {
      _taskSocket.submitHeartbeat(
        taskId: _activeTaskId!,
        heartRate: _heartRate,
        spo2: _spo2,
        stressLevel: _stressLevel,
        hrv: _hrv,
        lat: _lat,
        lng: _lng,
      );
    }

    _maybeUpdateNotification();
  }

  // Har 3rd tick (~3s) pe notification refresh karo, aur sirf tab jab
  // BPM badla ho — varna OEMs (Vivo/Xiaomi) spam maan ke hide kar dete hain.
  void _maybeUpdateNotification() {
    _notifTick++;
    if (_notifTick % 3 != 0) return;
    if (!_healthActive && _activeTaskId == null) return;

    final bpm = _heartRate;
    if (bpm == _lastShownBpm) return;
    _lastShownBpm = bpm;

    final text = bpm > 0 ? 'Heart Rate: $bpm bpm' : 'Waiting for sensor…';
    FlutterForegroundTask.updateService(
      notificationTitle: 'Sports IQ — Active',
      notificationText: text,
    );
  }

  // Main isolate se commands aate hain yahan.
  // Har command ek Map hai jisme 'cmd' key hoti hai.
  @override
  void onReceiveData(Object data) {
    if (data is! Map<String, dynamic>) return;
    final cmd = data['cmd'] as String?;
    debugPrint('[BG HANDLER] received cmd: $cmd');

    switch (cmd) {
      case 'start_health':
        _startHealth(data['token'] as String, data['base_url'] as String);
      case 'stop_health':
        _stopHealth();
      case 'start_activity':
        _startActivity(
          data['token'] as String,
          data['base_url'] as String,
          data['task_id'] as int,
        );
      case 'stop_activity':
        final taskId = data['task_id'] as int?;
        if (taskId != null) _taskSocket.stopTask(taskId);
        _activeTaskId = null;
      case 'update_metrics':
        // Main isolate se BLE data aata hai — yahan store karo
        _heartRate = (data['hr'] as num?)?.toInt() ?? 0;
        _spo2 = (data['spo2'] as num?)?.toDouble();
        _stressLevel = (data['stress'] as num?)?.toInt();
        _hrv = (data['hrv'] as num?)?.toDouble();
        _lat = (data['lat'] as num?)?.toDouble();
        _lng = (data['lng'] as num?)?.toDouble();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[BG HANDLER] onDestroy — cleaning up');
    if (_healthSocket.isConnected) _healthSocket.disconnect();
    if (_taskSocket.isConnected) _taskSocket.disconnect();
  }

  // ── Private: Health socket ──────────────────────────────────────────────────

  void _startHealth(String token, String baseUrl) {
    _healthActive = true;
    _intentionalHealthDisconnect = false;
    if (_healthSocket.isConnected) {
      FlutterForegroundTask.sendDataToMain({'event': 'health_monitoring_started'});
      return;
    }
    FlutterForegroundTask.sendDataToMain({'event': 'health_connecting'});
    _healthSocket.connect(baseUrl, token);
  }

  void _stopHealth() {
    _healthActive = false;
    _intentionalHealthDisconnect = true;
    // Banner ko abhi hide kar do — wait nahi karna 3s disconnect ke liye.
    FlutterForegroundTask.sendDataToMain({'event': 'health_monitoring_stopped'});
    if (_healthSocket.isConnected) {
      _healthSocket.notifyDeviceDisconnected();
      Future.delayed(const Duration(seconds: 3), () {
        if (_healthSocket.isConnected) _healthSocket.disconnect();
      });
    }
  }

  void _setupHealthSocketCallbacks() {
    _healthSocket.onMonitoringStarted = () {
      debugPrint('[BG HANDLER] health monitoring started');
      FlutterForegroundTask.sendDataToMain({'event': 'health_monitoring_started'});
    };

    _healthSocket.onMonitoringStopped = () {
      _healthActive = false;
      FlutterForegroundTask.sendDataToMain({'event': 'health_monitoring_stopped'});
    };

    _healthSocket.onMetricSaved = (data) {
      FlutterForegroundTask.sendDataToMain({
        'event': 'health_metric_saved',
        'data': data,
      });
    };

    _healthSocket.onError = (msg) {
      FlutterForegroundTask.sendDataToMain({
        'event': 'health_error',
        'message': msg,
      });
    };

    _healthSocket.onSocketDisconnected = () {
      // Agar humne khud disconnect kara (BLE gone / stop_health) to error
      // nahi — banner already 'monitoring_stopped' bhej chuka hai.
      if (_intentionalHealthDisconnect) {
        _intentionalHealthDisconnect = false;
        return;
      }
      FlutterForegroundTask.sendDataToMain({'event': 'health_socket_disconnected'});
    };

    _healthSocket.onAuthFailure = (msg) {
      // Token invalid/expired — reconnect waste. Main isolate ko bata do
      // taaki re-login flow trigger ho.
      FlutterForegroundTask.sendDataToMain({
        'event': 'health_auth_failure',
        'message': msg,
      });
    };
  }

  // ── Private: Activity socket ────────────────────────────────────────────────

  void _startActivity(String token, String baseUrl, int taskId) {
    _activeTaskId = taskId;
    _taskSocket.connect(baseUrl, token);
  }

  void _setupActivitySocketCallbacks() {
    _taskSocket.onTaskSaved = (data) {
      FlutterForegroundTask.sendDataToMain({
        'event': 'activity_task_saved',
        'data': data,
      });
    };

    _taskSocket.onRecordingStopped = (data) {
      _activeTaskId = null;
      FlutterForegroundTask.sendDataToMain({
        'event': 'activity_recording_stopped',
        'data': data,
      });
    };

    _taskSocket.onError = (msg) {
      FlutterForegroundTask.sendDataToMain({
        'event': 'activity_error',
        'message': msg,
      });
    };

    _taskSocket.onDisconnected = () {
      FlutterForegroundTask.sendDataToMain({'event': 'activity_disconnected'});
    };

    _taskSocket.onAuthFailure = (msg) {
      // Token invalid/expired — caller (activity cubit) reconnect band karega
      // aur user ko re-login pe bhejega.
      FlutterForegroundTask.sendDataToMain({
        'event': 'activity_auth_failure',
        'message': msg,
      });
    };
  }
}
