// import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

class AthleteTaskSocketService {
  sio.Socket? _socket;

  // Callbacks — cubit inhe set karega
  void Function(Map<String, dynamic> data)? onTaskSaved;
  void Function(Map<String, dynamic> data)? onRecordingStopped;
  void Function(String message)? onError;
  void Function()? onDisconnected;
  // Auth fail (token expired/invalid) — caller user ko re-login pe bhejega,
  // reconnect attempt waste nahi hoga.
  void Function(String message)? onAuthFailure;

  bool get isConnected => _socket?.connected ?? false;

  String _socketUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
  }

  int _heartbeatCount = 0;

  void connect(String baseUrl, String token) {
    if (_socket != null && _socket!.connected) {
      // debugPrint('[SESSION SOCKET] Already connected — skipping reconnect');
      return;
    }

    final url = _socketUrl(baseUrl);
    // debugPrint('[SESSION SOCKET] ▶ Connecting to $url');

    _socket = sio.io(
      url,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'token': token})
          .disableAutoConnect()
          // Library ka auto-reconnect band — ReconnectController handle karega.
          // Single source of truth, double-attempts ka risk nahi.
          .disableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      _heartbeatCount = 0;
      // debugPrint('[SESSION SOCKET] ✅ Connected');
    });

    _socket!.onDisconnect((_) {
      // debugPrint('[SESSION SOCKET] ❌ Disconnected (heartbeats sent: $_heartbeatCount)');
      onDisconnected?.call();
    });

    _socket!.onConnectError((err) {
      // debugPrint('[SESSION SOCKET] ⚠️ Connection error: $err');
      onError?.call('Socket connection failed');
    });

    _socket!.on('task_result_saved', (data) {
      // debugPrint('[SESSION SOCKET] ← task_result_saved: $data');
      if (data is Map<String, dynamic>) onTaskSaved?.call(data);
    });

    _socket!.on('recording_stopped', (data) {
      // debugPrint('[SESSION SOCKET] ← recording_stopped: $data');
      onRecordingStopped?.call(data is Map<String, dynamic> ? data : {});
    });

    _socket!.on('request_error', (data) {
      // debugPrint('[SESSION SOCKET] ← request_error: $data');
      final msg = data is Map ? data['message']?.toString() ?? 'Socket error' : 'Socket error';
      if (_isAuthError(msg)) {
        onAuthFailure?.call(msg);
      } else {
        onError?.call(msg);
      }
    });

    _socket!.connect();
  }

  String _mysqlTimestamp() {
    final t = DateTime.now().toUtc();
    final mm = t.month.toString().padLeft(2, '0');
    final dd = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');
    return '${t.year}-$mm-$dd $hh:$min:$ss';
  }

  void submitHeartbeat({
    required int taskId,
    required int heartRate,
    double? sugarLevel,
    double? spo2,
    double? lat,
    double? lng,
    int? stressLevel,
    double? hrv,
  }) {
    if (!isConnected) {
      // debugPrint('[SESSION SOCKET] submitHeartbeat skipped — not connected');
      return;
    }

    _heartbeatCount++;
    final payload = <String, dynamic>{
      'task_id': taskId,
      'heart_rate': heartRate,
      'timestamp': _mysqlTimestamp(),
    };

    if (sugarLevel != null) payload['sugar_level'] = sugarLevel;
    if (spo2 != null) payload['spo2'] = spo2;
    if (lat != null) payload['lat'] = lat;
    if (lng != null) payload['lng'] = lng;
    if (stressLevel != null) payload['stress_level'] = stressLevel;
    if (hrv != null && hrv > 0) payload['sugar_level'] = double.parse(hrv.toStringAsFixed(2));

    // Every 10th heartbeat log karo taaki logs flood na ho
    if (_heartbeatCount % 10 == 1) {
      // debugPrint('[SESSION SOCKET] → task_result_submit #$_heartbeatCount | '
          // 'task=$taskId hr=$heartRate spo2=$spo2 sugar=$sugarLevel hrv=$hrv stress=$stressLevel');
    }

    _socket!.emit('task_result_submit', payload);
  }

  void stopTask(int taskId) {
    if (!isConnected) {
      // debugPrint('[SESSION SOCKET] stopTask skipped — not connected (task=$taskId)');
      return;
    }
    // debugPrint('[SESSION SOCKET] → stop_task_result (task=$taskId)');
    _socket!.emit('stop_task_result', taskId);
  }

  void disconnect() {
    // debugPrint('[SESSION SOCKET] disconnect() called (heartbeats sent: $_heartbeatCount)');
    _heartbeatCount = 0;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    onTaskSaved = null;
    onRecordingStopped = null;
    onError = null;
    onDisconnected = null;
    onAuthFailure = null;
  }

  // Backend ke auth-related messages — `authenticateSocket` se aate hain.
  static bool _isAuthError(String msg) {
    final m = msg.toLowerCase();
    return m.contains('token') ||
        m.contains('not authenticated') ||
        m.contains('invalid or expired') ||
        m.contains('user not found');
  }
}
