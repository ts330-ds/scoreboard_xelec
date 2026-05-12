import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/service/foreground/athlete_foreground_service.dart';
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
  final SharedPreferences _prefs;
  StreamSubscription<Map<String, dynamic>>? _sub;
  final ReconnectController _reconnect =
      ReconnectController(tag: 'HEALTH RECONNECT');

  AthleteHealthMonitorCubit({required SharedPreferences prefs})
      : _prefs = prefs,
        super(const HealthMonitorState(HealthMonitorStatus.idle)) {
    _sub = AthleteForegroundService.eventStream.listen(_onBackgroundEvent);
    // Broadcast stream events buffer nahi karta. Agar cubit late create hua
    // (e.g. fresh login → dashboard khulte hi cubit bana, lekin BLE already
    // connect ho chuka tha aur events fire ho chuke the) to current status
    // ko replay karo taki banner correct dikhe.
    final cached = AthleteForegroundService.lastHealthEvent;
    if (cached != null) _onBackgroundEvent(cached);
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
    _reconnect.schedule(
      onAttempt: (attempt) {
        if (isClosed) return;
        debugPrint('[HEALTH CUBIT] Reconnect attempt #$attempt');
        emit(state.copyWith(reconnectAttempt: attempt));
        _restartMonitor();
      },
      onExhausted: () {
        if (isClosed) return;
        debugPrint('[HEALTH CUBIT] Reconnect budget exhausted');
        emit(state.copyWith(isReconnectExhausted: true));
      },
    );
  }

  // User ne "Retry" dabaya — budget reset + immediate attempt.
  void retryConnectionManually() {
    if (isClosed) return;
    _reconnect.reset();
    emit(state.copyWith(
      status: HealthMonitorStatus.reconnecting,
      isReconnectExhausted: false,
      reconnectAttempt: 0,
    ));
    _restartMonitor();
  }

  void _restartMonitor() {
    final token = _prefs.getString(PrefKeys.userToken) ?? '';
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    if (token.isEmpty || baseUrl.isEmpty) return;
    AthleteForegroundService.startHealthMonitor(token, baseUrl);
  }

  @override
  Future<void> close() {
    _reconnect.dispose();
    _sub?.cancel();
    return super.close();
  }
}
