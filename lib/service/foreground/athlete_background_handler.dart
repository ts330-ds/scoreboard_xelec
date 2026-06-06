import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
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
//
// Health monitoring (24/7 live HR streaming) ab REMOVED hai — sirf activity/
// training session ka real-time data BG isolate me jaata hai. History push
// HeartBleCubit on-demand main isolate se karta hai (sync ke baad).
class AthleteBackgroundHandler extends TaskHandler {
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
  int? _activeTaskId;
  bool _readyAnnounced = false;

  // BG-side self-reconnect — Vivo/Xiaomi screen-off pe main isolate throttle
  // ho jaata hai, isliye main isolate pe depend nahi karte.
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  String? _lastToken;
  String? _lastBaseUrl;
  static const _maxReconnectAttempts = 5; // 2+4+8+16+30 = ~60s max

  // Pending stop — jab stop_activity aaye lekin socket disconnected ho,
  // reconnect karke stop deliver karo.
  int? _pendingStopTaskId;
  Timer? _stopDeliveryTimer;

  // Notification throttle — onRepeatEvent har 1s pe fire hota hai, lekin
  // notification ko har 3s pe update karte hain (battery + OEM spam-filter ke liye).
  int _notifTick = 0;
  int _lastShownBpm = -1;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[BG HANDLER] onStart — background isolate ready');
    _taskSocket = AthleteTaskSocketService();
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
    if (_activeTaskId == null && _pendingStopTaskId == null) return;

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
      case 'start_activity':
        _startActivity(
          data['token'] as String,
          data['base_url'] as String,
          data['task_id'] as int,
        );
      case 'stop_activity':
        _handleStopActivity(data['task_id'] as int?);
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

  void _handleStopActivity(int? taskId) {
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    _activeTaskId = null;

    if (taskId == null) return;

    _pendingStopTaskId = taskId;
    _stopRetryCount = 0;

    if (_taskSocket.isConnected) {
      _taskSocket.stopTask(taskId);
    } else {
      _attemptStopDelivery();
    }
  }

  static const _maxStopRetries = 5;
  int _stopRetryCount = 0;

  void _attemptStopDelivery() {
    final token = _lastToken;
    final baseUrl = _lastBaseUrl;
    if (token == null || baseUrl == null || _pendingStopTaskId == null) return;

    _taskSocket.connect(baseUrl, token);

    _stopDeliveryTimer?.cancel();
    _stopRetryCount++;
    final delaySec = (2 * (1 << (_stopRetryCount - 1))).clamp(2, 15);
    _stopDeliveryTimer = Timer(Duration(seconds: delaySec), () {
      if (_pendingStopTaskId == null) return;
      if (_stopRetryCount >= _maxStopRetries) {
        debugPrint('[BG HANDLER] stop delivery failed after $_maxStopRetries retries — giving up');
        _pendingStopTaskId = null;
        return;
      }
      debugPrint('[BG HANDLER] stop delivery retry #$_stopRetryCount');
      _attemptStopDelivery();
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[BG HANDLER] onDestroy — cleaning up');
    _reconnectTimer?.cancel();
    _stopDeliveryTimer?.cancel();
    // App swipe-kill / system kill scenario: agar active session abhi tak
    // explicitly stop nahi hui (user ne "Stop" nahi dabaaya), to server ko
    // bata do taki session "in progress" stuck na rahe.
    final taskId = _activeTaskId ?? _pendingStopTaskId;
    if (taskId != null && _taskSocket.isConnected) {
      debugPrint('[BG HANDLER] onDestroy — stopping active task $taskId');
      _taskSocket.stopTask(taskId);
      // Socket buffer flush ka thoda time do
      await Future.delayed(const Duration(milliseconds: 400));
    }
    _activeTaskId = null;
    _pendingStopTaskId = null;
    _taskSocket.dispose();
  }

  // ── Private: Activity socket ────────────────────────────────────────────────

  void _startActivity(String token, String baseUrl, int taskId) {
    _pendingStopTaskId = null;
    _stopDeliveryTimer?.cancel();
    _activeTaskId = taskId;
    _lastToken = token;
    _lastBaseUrl = baseUrl;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _taskSocket.connect(baseUrl, token);
  }

  void _scheduleBgReconnect() {
    if (_activeTaskId == null && _pendingStopTaskId == null) return;
    if (_reconnectAttempt >= _maxReconnectAttempts) {
      debugPrint('[BG HANDLER] max reconnect attempts reached — main isolate will handle');
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    // Exponential backoff: 2s → 4s → 8s → 16s → 30s
    final delayMs = (2000 * (1 << (_reconnectAttempt - 1))).clamp(0, 30000);
    debugPrint('[BG HANDLER] self-reconnect attempt #$_reconnectAttempt in ${delayMs}ms');
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_activeTaskId == null && _pendingStopTaskId == null) return;
      if (_taskSocket.isConnected) return;
      final token = _lastToken;
      final baseUrl = _lastBaseUrl;
      if (token == null || baseUrl == null) return;
      _taskSocket.connect(baseUrl, token);
    });
  }

  void _setupActivitySocketCallbacks() {
    _taskSocket.onConnected = () {
      _reconnectAttempt = 0;
      _reconnectTimer?.cancel();
      debugPrint('[BG HANDLER] socket connected — reconnect counters reset');

      final pendingStop = _pendingStopTaskId;
      if (pendingStop != null) {
        debugPrint('[BG HANDLER] delivering pending stop for task $pendingStop');
        _pendingStopTaskId = null;
        _stopDeliveryTimer?.cancel();
        _taskSocket.stopTask(pendingStop);
      }
    };

    _taskSocket.onTaskSaved = (data) {
      FlutterForegroundTask.sendDataToMain({
        'event': 'activity_task_saved',
        'data': data,
      });
    };

    _taskSocket.onRecordingStopped = (data) {
      _activeTaskId = null;
      _pendingStopTaskId = null;
      _stopDeliveryTimer?.cancel();
      _reconnectTimer?.cancel();
      _reconnectAttempt = 0;
      _taskSocket.disconnect();
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
      // Main isolate ke saath-saath BG handler khud bhi retry karta hai —
      // Vivo/Xiaomi screen-off pe main isolate throttle ho sakta hai.
      _scheduleBgReconnect();
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
