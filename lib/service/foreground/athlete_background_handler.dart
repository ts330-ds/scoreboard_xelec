import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:xelex_esp/core/logging/file_logger.dart';
import 'package:xelex_esp/service/socket/athlete_task_socket_service.dart';

// @pragma annotation zaroori hai — warna release build mein tree shaking
// is function ko remove kar deta hai kyunki isko koi directly call nahi karta.
// Flutter foreground task isko string naam se dhundh ke call karta hai.
@pragma('vm:entry-point')
void startCallback() {
  // Background isolate ka apna FileLogger (alag file: bg_log.txt) — taaki
  // session socket activity bhi log ho. Main isolate ki file se merge hoti hai.
  FileLogger.instance.init(fileName: FileLogger.bgFileName);
  installDebugPrintCapture();
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

  // Kya is session ki pehli REAL (HR > 0) reading ja chuki hai? Jab tak nahi,
  // hum har tick par ek presence-ping bhejte hain taaki task pending → in_progress
  // ho jaaye (sensor slow ho ya socket abhi connect hua ho tab bhi).
  bool _firstHrSent = false;

  // BG-side self-reconnect — Vivo/Xiaomi screen-off pe main isolate throttle
  // ho jaata hai, isliye main isolate pe depend nahi karte.
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  String? _lastToken;
  String? _lastBaseUrl;
  static const _maxReconnectAttempts = 5; // 2+4+8+16+30 = ~60s max

  // Pending stop — jab stop_activity aaye lekin socket disconnected ho,
  // reconnect karke stop deliver karo. Delivery ek wall-clock deadline tak
  // retry hoti hai (fixed retry-count nahi) — internet wapas aate hi turant
  // bhej dete hain (connectivity listener), warna deadline pe abandon.
  int? _pendingStopTaskId;
  Timer? _stopDeliveryTimer;
  DateTime? _pendingStopDeadline;
  static const _pendingStopMaxDuration = Duration(minutes: 10);

  // Connectivity-aware delivery (Layer 2) — net wapas aate hi reconnect.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Notification throttle — onRepeatEvent har 1s pe fire hota hai, lekin
  // notification ko har 3s pe update karte hain (battery + OEM spam-filter ke liye).
  int _notifTick = 0;
  int _lastShownBpm = -1;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[BG HANDLER] onStart — background isolate ready');
    _taskSocket = AthleteTaskSocketService();
    _setupActivitySocketCallbacks();
    _listenConnectivity();
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

    if (_activeTaskId != null && _taskSocket.isConnected) {
      if (_heartRate > 0) {
        _taskSocket.submitHeartbeat(
          taskId: _activeTaskId!,
          heartRate: _heartRate,
          spo2: _spo2,
          stressLevel: _stressLevel,
          hrv: _hrv,
          lat: _lat,
          lng: _lng,
        );
        _firstHrSent = true;
      } else if (!_firstHrSent) {
        // Sensor abhi tak valid HR nahi de raha — phir bhi task ko in_progress
        // karne ke liye presence-ping bhejo. Har 1s retry hota hai, isliye
        // server-side auth race / late connect bhi cover ho jaata hai.
        _taskSocket.notifySessionStart(_activeTaskId!);
      }
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
    // Cross-isolate map kabhi-kabhi Map<Object?, Object?> ke roop me aata hai —
    // strict Map<String, dynamic> check use silently drop kar deta tha (main-
    // side _onDataFromBackground me yahi lesson pehle seekha ja chuka hai).
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final cmd = map['cmd'] as String?;
    debugPrint('[BG HANDLER] received cmd: $cmd');

    switch (cmd) {
      case 'start_activity':
        _startActivity(
          map['token'] as String,
          map['base_url'] as String,
          (map['task_id'] as num).toInt(),
        );
      case 'stop_activity':
        _handleStopActivity(
          (map['task_id'] as num?)?.toInt(),
          token: map['token'] as String?,
          baseUrl: map['base_url'] as String?,
        );
      case 'update_metrics':
        // Main isolate se BLE data aata hai — yahan store karo
        _heartRate = (map['hr'] as num?)?.toInt() ?? 0;
        _spo2 = (map['spo2'] as num?)?.toDouble();
        _stressLevel = (map['stress'] as num?)?.toInt();
        _hrv = (map['hrv'] as num?)?.toDouble();
        _lat = (map['lat'] as num?)?.toDouble();
        _lng = (map['lng'] as num?)?.toDouble();
    }
  }

  void _handleStopActivity(int? taskId, {String? token, String? baseUrl}) {
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    _activeTaskId = null;

    // Cold-start stop (app-kill ke baad overdue resume-stop): fresh isolate ke
    // paas creds nahi hote — command ke saath aaye ho to store karo, warna
    // reconnect/delivery kabhi ho hi nahi sakti thi.
    if (token != null) _lastToken = token;
    if (baseUrl != null) _lastBaseUrl = baseUrl;

    if (taskId == null) return;

    _pendingStopTaskId = taskId;
    _pendingStopDeadline = DateTime.now().add(_pendingStopMaxDuration);
    _stopRetryCount = 0;

    // Connected ho ya na ho — hamesha delivery loop se jao. Pehle connected-
    // case single-shot emit tha: ack kho jaaye to koi retry nahi, service
    // zombie + task in_progress atka rehta tha.
    _attemptStopDelivery();
  }

  int _stopRetryCount = 0;

  // Retry-until-ack: stop tab tak re-send hota hai jab tak server
  // `recording_stopped` na bhej de (onRecordingStopped sab clear karta hai)
  // ya deadline cross ho jaye (abandon).
  void _attemptStopDelivery() {
    final taskId = _pendingStopTaskId;
    if (taskId == null) return;

    // Deadline cross — itni der internet off raha ki ab give-up karo.
    // Main isolate ko batao taaki wo foreground service tear down kar de.
    // (Ye check creds-check se PEHLE — token na ho tab bhi abandon fire ho,
    // warna service hamesha ke liye zinda rehti.)
    if (_pendingStopDeadline != null &&
        DateTime.now().isAfter(_pendingStopDeadline!)) {
      debugPrint('[BG HANDLER] pending stop deadline exceeded — abandoning delivery');
      _abandonPendingStop();
      return;
    }

    if (_taskSocket.isConnected) {
      // Re-send safe hai — server ack aate hi onRecordingStopped loop band
      // kar deta hai; duplicate stop server pe idempotent no-op hai.
      _taskSocket.stopTask(taskId);
    } else {
      final token = _lastToken;
      final baseUrl = _lastBaseUrl;
      if (token != null && baseUrl != null) {
        _taskSocket.connect(baseUrl, token);
      }
    }

    // Backoff fallback retry — connectivity listener bhi parallel mein turant
    // try karega jab net wapas aaye.
    _stopDeliveryTimer?.cancel();
    _stopRetryCount++;
    final delaySec = (2 * (1 << (_stopRetryCount - 1))).clamp(2, 15);
    _stopDeliveryTimer = Timer(Duration(seconds: delaySec), () {
      if (_pendingStopTaskId == null) return;
      debugPrint('[BG HANDLER] stop delivery retry #$_stopRetryCount');
      _attemptStopDelivery();
    });
  }

  void _abandonPendingStop() {
    _stopDeliveryTimer?.cancel();
    _pendingStopTaskId = null;
    _pendingStopDeadline = null;
    FlutterForegroundTask.sendDataToMain({'event': 'activity_stop_abandoned'});
  }

  // Net wapas aate hi (Layer 2) — pending stop ya active task ko turant
  // reconnect karke deliver/resume karo, fixed backoff ka wait kiye bina.
  void _listenConnectivity() {
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!online) return;
      if (_taskSocket.isConnected) return;
      if (_pendingStopTaskId == null && _activeTaskId == null) return;
      final token = _lastToken;
      final baseUrl = _lastBaseUrl;
      if (token == null || baseUrl == null) return;
      debugPrint('[BG HANDLER] connectivity restored — immediate reconnect');
      _reconnectTimer?.cancel();
      if (_pendingStopTaskId != null) {
        // Delivery-loop se jao (connect + agla retry schedule) — seedha
        // connect karne se retry timer mar jaata tha aur ack kho jaane par
        // koi dobara koshish nahi hoti thi.
        _stopDeliveryTimer?.cancel();
        _attemptStopDelivery();
      } else {
        _taskSocket.connect(baseUrl, token);
      }
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[BG HANDLER] onDestroy — cleaning up');
    _reconnectTimer?.cancel();
    _stopDeliveryTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _pendingStopDeadline = null;
    // App swipe-kill / system kill pe session ko STOP nahi karte — server pe
    // khuli rehne do taaki agli launch pe recovery use resume kar sake. Yahan
    // sirf local cleanup + socket dispose (isolate waise bhi mar raha hai).
    _activeTaskId = null;
    _pendingStopTaskId = null;
    _taskSocket.dispose();
  }

  // ── Private: Activity socket ────────────────────────────────────────────────

  void _startActivity(String token, String baseUrl, int taskId) {
    _pendingStopTaskId = null;
    _stopDeliveryTimer?.cancel();
    _activeTaskId = taskId;
    _firstHrSent = false;
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
        // Pending stop yahan clear NAHI hota — sirf server ack
        // (onRecordingStopped) pe. Emit ke turant baad socket gir jaaye to
        // stop hamesha ke liye kho jaata tha (task in_progress atka + service
        // zombie). Retry timer chalta rehta hai jab tak ack/abandon na ho.
        _taskSocket.stopTask(pendingStop);
      }

      // Connect hote hi turant task ko in_progress kar do — HR ka wait mat karo.
      // onRepeatEvent fallback bhi cover karta hai, lekin yeh fast path hai.
      final activeTask = _activeTaskId;
      if (activeTask != null && !_firstHrSent) {
        _taskSocket.notifySessionStart(activeTask);
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
      _pendingStopDeadline = null;
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
