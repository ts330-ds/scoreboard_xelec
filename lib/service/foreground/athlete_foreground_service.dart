import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'athlete_background_handler.dart';

// Yeh wrapper class cubits ko direct FlutterForegroundTask se shield karta hai.
// Iska faida: ek jagah se service manage hoti hai — koi cubit accidentally
// doosre cubit ki service band na kar sake.
class AthleteForegroundService {
  AthleteForegroundService._();

  // Health monitoring 24/7 removed — sirf activity (training) BG isolate use karta hai.
  static bool _activityActive = false;

  // BG isolate ready handshake — `onStart` complete hone pe BG handler
  // 'bg_ready' event bhejta hai. Main isolate is event ka wait karta hai
  // before sending start_health / start_activity. Hardcoded delay (600ms)
  // unreliable thi — kabhi BG isolate spawn slow hota tha aur start_health
  // drop ho jaata tha.
  static bool _bgReady = false;
  static Completer<void>? _bgReadyCompleter;

  // Background se aane wale events ke liye broadcast stream
  static final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  // Latest health/activity status events cache — broadcast stream events
  // buffer nahi karta, isliye late subscriber (cubit jo dashboard khulne pe
  // bante hain) ke liye yahan store karte hain. Cubit subscribe hote hi
  // `replayLatest()` se current state pa lega.
  static Map<String, dynamic>? _lastHealthEvent;
  static Map<String, dynamic>? _lastActivityEvent;

  static Map<String, dynamic>? get lastHealthEvent => _lastHealthEvent;
  static Map<String, dynamic>? get lastActivityEvent => _lastActivityEvent;

  static void _onDataFromBackground(Object data) {
    debugPrint('[FG SERVICE] data from background: ${data.runtimeType} = $data');
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final name = map['event'] as String?;
    if (name == 'bg_ready') {
      _bgReady = true;
      if (_bgReadyCompleter != null && !_bgReadyCompleter!.isCompleted) {
        _bgReadyCompleter!.complete();
      }
      return;
    }
    if (name != null) {
      if (name.startsWith('health_')) {
        _lastHealthEvent = map;
      } else if (name.startsWith('activity_')) {
        _lastActivityEvent = map;
      }
    }
    _eventController.add(map);
  }

  static Future<void> _waitForBgReady() async {
    if (_bgReady) return;
    _bgReadyCompleter ??= Completer<void>();
    try {
      await _bgReadyCompleter!.future.timeout(const Duration(seconds: 2));
    } catch (_) {
      debugPrint('[FG SERVICE] ⚠️ bg_ready timeout — proceeding anyway');
    }
  }

  // App startup pe ek baar call karo (main.dart mein).
  static void init() {
    FlutterForegroundTask.addTaskDataCallback(_onDataFromBackground);
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'xelex_athlete_session_v2',
        channelName: 'Active Session',
        channelDescription: 'Shows while a training session is running',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // onRepeatEvent har 1000ms (1 second) pe fire hoga
        // Yahi hamara timer hai — main isolate ka Timer.periodic nahi
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> preWarmService() async {
    await _ensureServiceRunning();
    await _waitForBgReady();
  }

  static Future<void> stopIfIdle() => _stopServiceIfIdle();

  /// FG service abhi chal rahi hai ya nahi — launch-time orphan (zombie)
  /// detection ke liye (persisted/UI session gayab par service zinda).
  static Future<bool> get isServiceRunning =>
      FlutterForegroundTask.isRunningService;

  // Activity session start karo
  static Future<void> startActivitySession({
    required String token,
    required String baseUrl,
    required int taskId,
  }) async {
    _activityActive = true;
    await _ensureServiceRunning();
    await _waitForBgReady();
    FlutterForegroundTask.sendDataToTask({
      'cmd': 'start_activity',
      'token': token,
      'base_url': baseUrl,
      'task_id': taskId,
    });
  }

  static Future<void> stopActivitySession(int taskId) async {
    FlutterForegroundTask.sendDataToTask({
      'cmd': 'stop_activity',
      'task_id': taskId,
    });
    // _activityActive abhi false mat karo — server confirm hone tak BLE data
    // flow chalta rahe. cleanupAfterSessionEnd() mein false hoga.
  }

  static Future<void> cleanupAfterSessionEnd() async {
    _activityActive = false;
    await _stopServiceIfIdle();
  }

  /// App-exit (user ne "Exit App" confirm kiya) par foreground service + BG
  /// isolate band karo — LEKIN server ko koi stop command mat bhejo. Session
  /// `in_progress` rehti hai taaki agli launch pe recovery use resume kar sake
  /// (bilkul swipe-kill jaisa).
  ///
  /// NOTE: `stopActivitySession()` se ALAG — wo `stop_activity` bhejta hai jo
  /// server pe `stopTask` → session COMPLETE kar deta hai (resume ka mauka
  /// khatam). Yahan seedha `stopService()` — BG handler ka `onDestroy` sirf
  /// local cleanup karta hai, server ko chhedta nahi.
  static Future<void> stopServiceKeepSession() async {
    // Guard 1: koi active session hi nahi → kuch mat karo. (Idle me service
    // waise bhi running nahi hoti; galti se kisi aur cheez ko touch na karein.)
    if (!_activityActive) return;
    // Guard 2: service actually running (i.e. native service null nahi) tabhi
    // stop karo. Warna stopService() call bekaar / no-op.
    if (!await FlutterForegroundTask.isRunningService) return;

    _activityActive = false;
    await FlutterForegroundTask.stopService();
    // Service band — next start fresh handshake karega.
    _bgReady = false;
    _bgReadyCompleter = null;
  }

  // BLE se nayi reading aayi — background handler ko batao
  // Background handler onRepeatEvent mein latest value use karega
  static void updateMetrics({
    required int heartRate,
    double? spo2,
    int? stressLevel,
    double? hrv,
    double? lat,
    double? lng,
  }) {
    if (!_activityActive) return;
    FlutterForegroundTask.sendDataToTask({
      'cmd': 'update_metrics',
      'hr': heartRate,
      if (spo2 != null) 'spo2': spo2,
      if (stressLevel != null) 'stress': stressLevel,
      if (hrv != null) 'hrv': hrv,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  static Future<void> _ensureServiceRunning() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 300,
      notificationTitle: 'Sports IQ — Active',
      notificationText: 'Monitoring your health data',
      callback: startCallback,
    );
  }

  // Reference count zero ho jaaye tabhi band karo
  static Future<void> _stopServiceIfIdle() async {
    if (!_activityActive) {
      await FlutterForegroundTask.stopService();
      // Service stop hone ke baad next start fresh handshake karega
      _bgReady = false;
      _bgReadyCompleter = null;
    }
  }
}
