// import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

class AthleteTaskSocketService {
  sio.Socket? _socket;
  bool _isConnecting = false;

  // Callbacks — cubit inhe set karega
  void Function()? onConnected;
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
    if (_socket != null && _socket!.connected) return;
    if (_isConnecting) return;

    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    _isConnecting = true;
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

    _socket!.onConnect((_) {
      _isConnecting = false;
      _heartbeatCount = 0;
      onConnected?.call();
    });

    _socket!.onDisconnect((_) {
      _isConnecting = false;
      onDisconnected?.call();
    });

    _socket!.onConnectError((err) {
      _isConnecting = false;
      onError?.call('Socket connection failed');
      onDisconnected?.call();
    });

    _socket!.on('task_result_saved', (data) {
      onTaskSaved?.call(_toStringKeyMap(data));
    });

    _socket!.on('recording_stopped', (data) {
      onRecordingStopped?.call(_toStringKeyMap(data));
    });

    _socket!.on('request_error', (data) {
      final map = _toStringKeyMap(data);
      final msg = map['message']?.toString() ?? 'Socket error';
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

  static Map<String, dynamic> _toStringKeyMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
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

  /// Minimal `task_result_submit` jisme sirf task_id (+ timestamp) hai.
  /// Server kisi bhi `task_result_submit` par pending → in_progress kar deta hai,
  /// chahe heart_rate na ho. Isse session start hote hi (BLE sensor ke valid
  /// HR dene se PEHLE) task in_progress ho jaata hai — coach ko turant pata
  /// chal jaata hai ki athlete active hai.
  void notifySessionStart(int taskId) {
    if (!isConnected) return;
    _socket!.emit('task_result_submit', <String, dynamic>{
      'task_id': taskId,
      'timestamp': _mysqlTimestamp(),
    });
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
    _isConnecting = false;
    _heartbeatCount = 0;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    onConnected = null;
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
