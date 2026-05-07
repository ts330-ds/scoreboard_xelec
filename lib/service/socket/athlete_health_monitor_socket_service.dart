import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

class AthleteHealthMonitorSocketService {
  sio.Socket? _socket;

  void Function()? onMonitoringStarted;
  void Function()? onMonitoringStopped;
  void Function(Map<String, dynamic> data)? onMetricSaved;
  void Function(String message)? onError;
  void Function()? onSocketDisconnected;

  bool get isConnected => _socket?.connected ?? false;

  int _metricCount = 0;

  String _socketUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
  }

  void connect(String baseUrl, String token) {
    if (_socket != null && _socket!.connected) {
      debugPrint('[HEALTH SOCKET] Already connected — skipping');
      return;
    }

    final url = _socketUrl(baseUrl);
    debugPrint('[HEALTH SOCKET] ▶ Connecting to $url');

    _socket = sio.io(
      url,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _metricCount = 0;
      debugPrint('[HEALTH SOCKET] ✅ Connected — emitting device_connected');
      _socket!.emit('device_connected');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[HEALTH SOCKET] ❌ Disconnected (metrics sent: $_metricCount)');
      onSocketDisconnected?.call();
    });

    _socket!.onConnectError((err) {
      debugPrint('[HEALTH SOCKET] ⚠️ Connection error: $err');
      onError?.call('Health socket connection failed');
    });

    _socket!.on('device_monitoring_started', (_) {
      debugPrint('[HEALTH SOCKET] ← device_monitoring_started ✅');
      onMonitoringStarted?.call();
    });

    _socket!.on('health_metric_saved', (data) {
      debugPrint('[HEALTH SOCKET] ← health_metric_saved: $data');
      if (data is Map<String, dynamic>) onMetricSaved?.call(data);
    });

    _socket!.on('device_monitoring_stopped', (_) {
      debugPrint('[HEALTH SOCKET] ← device_monitoring_stopped');
      onMonitoringStopped?.call();
    });

    _socket!.on('request_error', (data) {
      debugPrint('[HEALTH SOCKET] ← request_error: $data');
      final msg = data is Map ? data['message']?.toString() ?? 'Socket error' : 'Socket error';
      onError?.call(msg);
    });

    _socket!.connect();
  }

  void submitHealthMetric({
    required int heartRate,
    double? sugarLevel,
    double? spo2,
    int? stressLevel,
    double? hrv,
    double? lat,
    double? lng,
  }) {
    if (!isConnected) {
      debugPrint('[HEALTH SOCKET] submitHealthMetric skipped — not connected');
      return;
    }

    _metricCount++;
    final payload = <String, dynamic>{
      'heart_rate': heartRate,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    if (sugarLevel != null) payload['sugar_level'] = sugarLevel;
    if (spo2 != null) payload['spo2'] = spo2;
    if (stressLevel != null) payload['stress_level'] = stressLevel;
    // HRV (RMSSD) — backend will rename this key later
    if (hrv != null && hrv > 0) payload['sugar_level'] = double.parse(hrv.toStringAsFixed(2));
    if (lat != null) payload['lat'] = lat;
    if (lng != null) payload['lng'] = lng;

    if (_metricCount % 10 == 1) {
      debugPrint('[HEALTH SOCKET] → health_metric_submit #$_metricCount | '
          'hr=$heartRate spo2=$spo2 stress=$stressLevel hrv=$hrv');
    }

    _socket!.emit('health_metric_submit', payload);
  }

  void notifyDeviceDisconnected() {
    if (!isConnected) {
      debugPrint('[HEALTH SOCKET] notifyDeviceDisconnected skipped — not connected');
      return;
    }
    debugPrint('[HEALTH SOCKET] → device_disconnected');
    _socket!.emit('device_disconnected');
  }

  void disconnect() {
    debugPrint('[HEALTH SOCKET] disconnect() called (metrics sent: $_metricCount)');
    _metricCount = 0;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    onMonitoringStarted = null;
    onMonitoringStopped = null;
    onMetricSaved = null;
    onError = null;
    onSocketDisconnected = null;
  }
}
