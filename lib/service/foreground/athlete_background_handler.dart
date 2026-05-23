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
    if (_activeTaskId == null) return;

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
    // App swipe-kill / system kill scenario: agar active session abhi tak
    // explicitly stop nahi hui (user ne "Stop" nahi dabaaya), to server ko
    // bata do taki session "in progress" stuck na rahe.
    final taskId = _activeTaskId;
    if (taskId != null && _taskSocket.isConnected) {
      debugPrint('[BG HANDLER] onDestroy — stopping active task $taskId');
      _taskSocket.stopTask(taskId);
      // Socket buffer flush ka thoda time do
      await Future.delayed(const Duration(milliseconds: 400));
    }
    _activeTaskId = null;
    if (_taskSocket.isConnected) _taskSocket.disconnect();
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
