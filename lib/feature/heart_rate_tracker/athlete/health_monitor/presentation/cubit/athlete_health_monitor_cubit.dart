import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/service/foreground/athlete_foreground_service.dart';
import 'package:xelex_esp/service/network/network_reconnect_notifier.dart';
import 'package:xelex_esp/service/socket/reconnect_controller.dart';

enum HealthMonitorStatus { idle, connecting, monitoring, reconnecting, error }

class HealthMonitorState {
  final HealthMonitorStatus status;
  final DateTime? lastSavedAt;
  final int reconnectAttempt;
  final bool isReconnectExhausted;
  final bool isAuthFailure;
  final String? errorMessage;

  const HealthMonitorState(
    this.status, {
    this.lastSavedAt,
    this.reconnectAttempt = 0,
    this.isReconnectExhausted = false,
    this.isAuthFailure = false,
    this.errorMessage,
  });

  HealthMonitorState copyWith({
    HealthMonitorStatus? status,
    DateTime? lastSavedAt,
    int? reconnectAttempt,
    bool? isReconnectExhausted,
    bool? isAuthFailure,
    String? errorMessage,
  }) =>
      HealthMonitorState(
        status ?? this.status,
        lastSavedAt: lastSavedAt ?? this.lastSavedAt,
        reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
        isReconnectExhausted: isReconnectExhausted ?? this.isReconnectExhausted,
        isAuthFailure: isAuthFailure ?? this.isAuthFailure,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class AthleteHealthMonitorCubit extends Cubit<HealthMonitorState> {
  StreamSubscription<Map<String, dynamic>>? _sub;
  StreamSubscription<void>? _netSub;
  final ReconnectController _reconnect =
      ReconnectController(tag: 'HEALTH RECONNECT');

  AthleteHealthMonitorCubit({required SharedPreferences prefs})
      : super(const HealthMonitorState(HealthMonitorStatus.idle)) {
    _sub = AthleteForegroundService.eventStream.listen(_onBackgroundEvent);
    // Broadcast stream events buffer nahi karta. Agar cubit late create hua
    // (e.g. fresh login → dashboard khulte hi cubit bana, lekin BLE already
    // connect ho chuka tha aur events fire ho chuke the) to current status
    // ko replay karo taki banner correct dikhe.
    final cached = AthleteForegroundService.lastHealthEvent;
    if (cached != null) _onBackgroundEvent(cached);
    // Airplane mode / Wi-Fi outage ke baad jab network wapas aaye, agar
    // hum reconnecting/exhausted/error state mein hain to turant retry karo
    // — user ko manually "Retry" tap karne ki zaroorat nahi.
    _netSub = NetworkReconnectNotifier.instance.onNetworkRestored.listen((_) {
      if (isClosed) return;
      if (state.isAuthFailure) return;
      final s = state.status;
      if (s == HealthMonitorStatus.reconnecting ||
          s == HealthMonitorStatus.error ||
          state.isReconnectExhausted) {
        debugPrint('[HEALTH CUBIT] network restored — forcing retry');
        retryConnectionManually();
      }
    });
  }

  void _onBackgroundEvent(Map<String, dynamic> event) {
    debugPrint('[HEALTH CUBIT] event: $event');
    final name = event['event'] as String?;
    switch (name) {
      case 'health_connecting':
        if (!isClosed) {
          emit(state.copyWith(status: HealthMonitorStatus.connecting));
        }

      case 'health_monitoring_started':
        // Successful connect — reconnect counters reset.
        _reconnect.reset();
        if (!isClosed) {
          emit(state.copyWith(
            status: HealthMonitorStatus.monitoring,
            reconnectAttempt: 0,
            isReconnectExhausted: false,
          ));
        }

      case 'health_monitoring_stopped':
        // User-initiated stop — reconnect cancel kar do.
        _reconnect.cancel();
        if (!isClosed) {
          emit(const HealthMonitorState(HealthMonitorStatus.idle));
        }

      case 'health_metric_saved':
        // Data flow back — reconnect successful confirm.
        _reconnect.reset();
        if (!isClosed) {
          emit(state.copyWith(
            status: HealthMonitorStatus.monitoring,
            lastSavedAt: DateTime.now(),
            reconnectAttempt: 0,
            isReconnectExhausted: false,
          ));
        }

      case 'health_socket_disconnected':
        // Unintentional disconnect — auto reconnect.
        if (!isClosed && !state.isAuthFailure) {
          emit(state.copyWith(status: HealthMonitorStatus.reconnecting));
          _scheduleReconnect();
        }

      case 'health_auth_failure':
        // Token invalid/expired — reconnect waste.
        _reconnect.cancel();
        if (!isClosed) {
          emit(state.copyWith(
            status: HealthMonitorStatus.error,
            isAuthFailure: true,
            errorMessage: event['message'] as String? ?? 'Session expired',
          ));
        }

      case 'health_error':
        if (!isClosed) {
          emit(state.copyWith(
            status: HealthMonitorStatus.error,
            errorMessage: event['message'] as String?,
          ));
        }
    }
  }

  void _scheduleReconnect() {
    // 24/7 health monitoring removed — push ab on-demand HeartBleCubit karta hai.
    // Reconnect scheduling no-op rakhi hai taaki existing UI banner code (jo
    // `reconnecting`/`exhausted` flags read karta hai) bina crash kaam kare.
    _reconnect.cancel();
  }

  // User ne "Retry" dabaya — health monitoring removed, ye method ab no-op.
  // Push retry HeartBleCubit handle karta hai (BLE reconnect pe automatic).
  void retryConnectionManually() {
    if (isClosed) return;
    emit(const HealthMonitorState(HealthMonitorStatus.idle));
  }

  @override
  Future<void> close() {
    _reconnect.dispose();
    _sub?.cancel();
    _netSub?.cancel();
    return super.close();
  }
}
