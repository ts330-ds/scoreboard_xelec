import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Process-wide singleton that fires when the device transitions from
/// "no network" to "has network".
///
/// Cubits with their own reconnect logic (health monitor, activity, coach
/// live task) subscribe to [onNetworkRestored]. When the user comes back
/// from airplane mode / Wi-Fi outage after the reconnect budget has
/// expired, this notifier nudges them to retry instead of waiting for the
/// user to tap a "Retry" button.
class NetworkReconnectNotifier {
  NetworkReconnectNotifier._();
  static final NetworkReconnectNotifier instance = NetworkReconnectNotifier._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  final StreamController<void> _restored = StreamController<void>.broadcast();

  bool _wasOnline = true;
  bool _started = false;

  /// Fires (no payload) each time we go from offline → online.
  /// Late subscribers get nothing for the past — listen before going offline.
  Stream<void> get onNetworkRestored => _restored.stream;

  /// Best-effort current state. `false` if connectivity hasn't been probed
  /// yet — callers should treat it as "assume online".
  bool get isOnline => _wasOnline;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final initial = await _connectivity.checkConnectivity();
      _wasOnline = _hasNetwork(initial);
    } catch (e) {
      debugPrint('[NET NOTIFIER] initial check failed: $e');
      _wasOnline = true;
    }
    _sub = _connectivity.onConnectivityChanged.listen(_onChange);
    debugPrint('[NET NOTIFIER] started — online=$_wasOnline');
  }

  void _onChange(List<ConnectivityResult> results) {
    final online = _hasNetwork(results);
    debugPrint('[NET NOTIFIER] change: $results → online=$online (was=$_wasOnline)');
    if (!_wasOnline && online) {
      debugPrint('[NET NOTIFIER] network restored — notifying listeners');
      _restored.add(null);
    }
    _wasOnline = online;
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _restored.close();
    _started = false;
  }
}
