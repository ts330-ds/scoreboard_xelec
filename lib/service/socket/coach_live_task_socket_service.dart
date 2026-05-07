import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

class CoachLiveTaskSocketService {
  sio.Socket? _socket;

  // Callbacks — cubit set karega
  void Function()? onWatching;
  void Function(CoachLiveReading reading, int totalReadings)? onLiveUpdate;
  void Function()? onAthleteStopped;
  void Function(String message)? onError;
  void Function()? onDisconnected;

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

    final url = _socketUrl(baseUrl);
    debugPrint('[COACH SOCKET] Connecting to $url');

    _socket = sio.io(
      url,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[COACH SOCKET] Connected');
      onConnected?.call();
    });

    _socket!.onDisconnect((_) {
      debugPrint('[COACH SOCKET] Disconnected');
      onDisconnected?.call();
    });

    _socket!.onConnectError((err) {
      debugPrint('[COACH SOCKET] Connection error: $err');
      onError?.call('Socket connection failed');
    });

    _socket!.on('watching_task', (data) {
      debugPrint('[COACH SOCKET] watching_task: $data');
      onWatching?.call();
    });

    _socket!.on('live_result_update', (data) {
      debugPrint('[COACH SOCKET] live_result_update: $data');
      if (data is! Map) return;

      final latestRaw = data['latestReading'];
      if (latestRaw is! Map) return;

      final bpm = _toInt(latestRaw['heart_rate']);
      if (bpm <= 0) return;

      final reading = CoachLiveReading(
        bpm: bpm,
        sugarLevel: latestRaw['sugar_level'] != null ? _toDouble(latestRaw['sugar_level']) : null,
        spo2: latestRaw['spo2'] != null ? _toDouble(latestRaw['spo2']) : null,
        lat: latestRaw['lat'] != null ? _toDouble(latestRaw['lat']) : null,
        lng: latestRaw['lng'] != null ? _toDouble(latestRaw['lng']) : null,
        stressLevel: latestRaw['stress_level'] != null ? _toInt(latestRaw['stress_level']) : null,
        timestamp: DateTime.tryParse(latestRaw['timestamp']?.toString() ?? '') ?? DateTime.now(),
      );

      onLiveUpdate?.call(reading, _toInt(data['totalReadings']));
    });

    _socket!.on('athlete_stopped', (data) {
      debugPrint('[COACH SOCKET] athlete_stopped: $data');
      onAthleteStopped?.call();
    });

    _socket!.on('request_error', (data) {
      final msg = data is Map
          ? data['message']?.toString() ?? 'Socket error'
          : 'Socket error';
      onError?.call(msg);
    });

    _socket!.connect();
  }

  // Task ko watch karna shuru karo
  void watchTask(int taskId) {
    if (!isConnected) return;
    debugPrint('[COACH SOCKET] Emitting watch_task_results for task $taskId');
    _socket!.emit('watch_task_results', taskId);
  }

  // Watch band karo jab coach page chhode
  void unwatchTask(int taskId) {
    if (!isConnected) return;
    debugPrint('[COACH SOCKET] Emitting unwatch_task_results for task $taskId');
    _socket!.emit('unwatch_task_results', taskId);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    onWatching = null;
    onLiveUpdate = null;
    onAthleteStopped = null;
    onError = null;
    onDisconnected = null;
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

class CoachLiveReading {
  final int bpm;
  final double? sugarLevel;
  final double? spo2;
  final double? lat;
  final double? lng;
  final int? stressLevel;
  final DateTime timestamp;

  const CoachLiveReading({
    required this.bpm,
    required this.timestamp,
    this.sugarLevel,
    this.spo2,
    this.lat,
    this.lng,
    this.stressLevel,
  });
}
