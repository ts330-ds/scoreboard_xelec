import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

/// Coach "Whole Team" live dashboard socket.
///
/// NOTE: Ye `watch_team`/`team_live_update` par depend NAHI karta (wo server-side
/// mirror chahta hai jo athlete_coaches link + single Node worker maangta hai).
/// Iske bajaaye ye SAME proven per-task events use karta hai jo single-athlete
/// live view me already chal rahe hain:
///   emit  : watch_task_results / unwatch_task_results  (har active task ke liye)
///   listen: watching_task, live_result_update, athlete_stopped,
///           athlete_connection_lost
/// Har event me `task_id` aata hai, isliye coach kai tasks ek saath watch karke
/// task_id se demux kar leta hai. Koi backend change nahi chahiye.
class TeamLiveSocketService {
  sio.Socket? _socket;

  // Callbacks — cubit set karega.
  void Function(int taskId)? onWatchingTask;
  void Function(int taskId, TeamTaskReading reading)? onLiveUpdate;
  void Function(int taskId)? onAthleteStopped;
  void Function(int taskId)? onAthleteConnectionLost;
  void Function(String message)? onError;
  void Function()? onDisconnected;
  // Auth fail — coach ko re-login pe bhejna padega.
  void Function(String message)? onAuthFailure;
  // Server abhi authenticate kar raha hai (race) — "Not authenticated yet".
  void Function()? onNotReady;

  bool get isConnected => _socket?.connected ?? false;

  String _socketUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
  }

  void connect(String baseUrl, String token, {VoidCallback? onConnected}) {
    if (_socket != null && _socket!.connected) {
      onConnected?.call();
      return;
    }

    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }
    final url = _socketUrl(baseUrl);

    _socket = sio.io(
      url,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'token': token})
          .disableAutoConnect()
          .disableReconnection()
          .build(),
    );

    debugPrint('[TEAM SOCKET] connecting to $url (token len=${token.length})');

    _socket!.onConnect((_) {
      debugPrint('[TEAM SOCKET] connected ✓ (id=${_socket?.id})');
      onConnected?.call();
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[TEAM SOCKET] disconnected: $reason');
      onDisconnected?.call();
    });

    _socket!.onConnectError((err) {
      debugPrint('[TEAM SOCKET] connect_error: $err');
      onError?.call('Socket connection failed');
      onDisconnected?.call();
    });

    // watch_task_results ka ack — task_id include hota hai.
    _socket!.on('watching_task', (data) {
      if (data is! Map) return;
      final taskId = _toInt(data['task_id']);
      if (taskId > 0) onWatchingTask?.call(taskId);
    });

    // Har athlete reading — live_result_update me task_id aur latestReading.
    _socket!.on('live_result_update', (data) {
      if (data is! Map) return;
      final taskId = _toInt(data['task_id']);
      final latest = data['latestReading'];
      if (taskId <= 0 || latest is! Map) return;

      final reading = TeamTaskReading(
        heartRate: _toInt(latest['heart_rate']),
        spo2: latest['spo2'] != null ? _toDouble(latest['spo2']) : null,
        sugarLevel: latest['sugar_level'] != null ? _toDouble(latest['sugar_level']) : null,
        stressLevel: latest['stress_level'] != null ? _toInt(latest['stress_level']) : null,
        lat: latest['lat'] != null ? _toDouble(latest['lat']) : null,
        lng: latest['lng'] != null ? _toDouble(latest['lng']) : null,
        timestamp: DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now(),
      );
      onLiveUpdate?.call(taskId, reading);
    });

    // Athlete ne stop dabaya / session ended — card hatao.
    _socket!.on('athlete_stopped', (data) {
      final taskId = data is Map ? _toInt(data['task_id']) : _toInt(data);
      if (taskId > 0) onAthleteStopped?.call(taskId);
    });

    // Athlete ka connection drop — card grey karo.
    _socket!.on('athlete_connection_lost', (data) {
      final taskId = data is Map ? _toInt(data['task_id']) : _toInt(data);
      if (taskId > 0) onAthleteConnectionLost?.call(taskId);
    });

    _socket!.on('request_error', (data) {
      final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final msg = map['message']?.toString() ?? 'Socket error';
      // "Not authenticated yet" — server abhi DB se auth kar raha hai (race).
      // Fatal mat samjho; cubit watch retry karega.
      if (_isNotReady(msg)) {
        debugPrint('[TEAM SOCKET] not-ready (auth racing) — will retry watch');
        onNotReady?.call();
      } else if (_isAuthError(msg)) {
        onAuthFailure?.call(msg);
      } else {
        // "You are not authorized to watch this task" jaise per-task errors ko
        // chup-chaap ignore karo — ek task fail hone se poora grid na ruke.
        debugPrint('[TEAM SOCKET] request_error (ignored): $msg');
      }
    });

    _socket!.connect();
  }

  // Ek task ka live watch shuru karo.
  void watchTask(int taskId) {
    if (!isConnected) return;
    _socket!.emit('watch_task_results', taskId);
  }

  // Ek task ka watch band karo.
  void unwatchTask(int taskId) {
    if (!isConnected) return;
    _socket!.emit('unwatch_task_results', taskId);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    onWatchingTask = null;
    onLiveUpdate = null;
    onAthleteStopped = null;
    onAthleteConnectionLost = null;
    onError = null;
    onDisconnected = null;
    onAuthFailure = null;
    onNotReady = null;
  }

  // Transient: server abhi auth kar raha hai. Sirf yahi message retry-able hai.
  static bool _isNotReady(String msg) =>
      msg.toLowerCase().contains('not authenticated yet');

  // Genuine auth failure — re-login chahiye.
  static bool _isAuthError(String msg) {
    final m = msg.toLowerCase();
    return m.contains('invalid or expired') ||
        m.contains('user not found') ||
        m.contains('invalid token') ||
        m.contains('no token');
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

/// Ek live_result_update reading (per task).
class TeamTaskReading {
  final int heartRate;
  final double? spo2;
  final double? sugarLevel;
  final int? stressLevel;
  final double? lat;
  final double? lng;
  final DateTime timestamp;

  const TeamTaskReading({
    required this.heartRate,
    required this.timestamp,
    this.spo2,
    this.sugarLevel,
    this.stressLevel,
    this.lat,
    this.lng,
  });
}
