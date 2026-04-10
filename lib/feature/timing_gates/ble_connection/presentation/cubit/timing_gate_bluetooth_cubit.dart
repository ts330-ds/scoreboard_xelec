import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/data/timing_gate_ble_service.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/presentation/cubit/timing_gate_bluetooth_state.dart';

class TimingGateBleCubit extends Cubit<TimingGateBleState> {
  final GlobalErrorCubit errorCubit;
  final TimingGateBleService bleService;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<int>? _rssiSub;
  StreamSubscription<bool>? _connSub;

  /// When true, the user manually disconnected → skip auto-reconnect.
  bool _userDisconnected = false;

  /// Tracks if a reconnect loop is currently running to avoid duplicates.
  bool _reconnectInProgress = false;

  TimingGateBleCubit({
    required this.errorCubit,
    required this.bleService,
  }) : super(const TimingGateBleState()) {
    // Listen for connection state changes
    _connSub = bleService.connectionStream.listen((connected) {
      if (!connected && state.isConnected) {
        // ── Connection lost ──
        if (_userDisconnected) {
          // User pressed disconnect → just reset state, no auto-reconnect
          emit(const TimingGateBleState(
            status: 'Disconnected',
            isConnected: false,
          ));
        } else {
          // Unexpected disconnect → start auto-reconnect
          final deviceName = state.connectedDeviceName;
          emit(state.copyWith(
            isConnected: false,
            isReconnecting: true,
            reconnectAttempt: 0,
            status: 'Connection lost. Reconnecting...',
          ));
          errorCubit.showWarning('Connection lost. Attempting to reconnect...');
          _startAutoReconnect(deviceName);
        }
      }
    });

    // RSSI updates
    _rssiSub = bleService.rssiStream.listen((rssi) {
      if (!isClosed && state.isConnected) {
        emit(state.copyWith(connectedRssi: rssi));
      }
    });
  }

  // ── Auto-Reconnect ─────────────────────────────────────────────────────

  Future<void> _startAutoReconnect(String deviceName) async {
    // Guard: only one reconnect loop at a time
    if (_reconnectInProgress) return;
    _reconnectInProgress = true;

    const maxAttempts = TimingGateBleState.maxReconnectAttempts;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      // Stop if cubit is closed, user manually disconnected, or already reconnected
      if (isClosed || _userDisconnected || state.isConnected) break;

      // Check if the service still has a device to reconnect to
      if (!bleService.canReconnect) {
        debugPrint('[BLE] No previous device — cannot auto-reconnect.');
        break;
      }

      // Update UI: show which attempt we're on
      emit(state.copyWith(
        isReconnecting: true,
        reconnectAttempt: attempt,
        status: 'Reconnecting ($attempt/$maxAttempts)...',
      ));

      // Wait before attempting (exponential backoff: 2s, 4s, 8s, 16s, 32s)
      final delay = Duration(seconds: 1 << attempt); // 2^attempt seconds
      await Future.delayed(delay);

      // Re-check guards after the delay
      if (isClosed || _userDisconnected || state.isConnected) break;

      try {
        debugPrint('[BLE] Auto-reconnect attempt $attempt/$maxAttempts');
        await bleService.reconnect();

        // ── Success! ──
        if (isClosed) break;
        emit(state.copyWith(
          isConnected: true,
          isReconnecting: false,
          reconnectAttempt: 0,
          status: 'Connected',
          connectedDeviceName: deviceName,
        ));
        errorCubit.showWarning('Reconnected successfully!');
        _reconnectInProgress = false;
        return;
      } catch (e) {
        debugPrint('[BLE] Auto-reconnect attempt $attempt failed: $e');
        // Continue to next attempt
      }
    }

    // ── All attempts failed ──
    _reconnectInProgress = false;
    if (!isClosed && !_userDisconnected && !state.isConnected) {
      emit(state.copyWith(
        isReconnecting: false,
        reconnectAttempt: 0,
        status: 'Reconnect failed',
        connectedDeviceName: '',
      ));
      errorCubit.showError(
        'Could not reconnect after $maxAttempts attempts. Please reconnect manually.',
      );
    }
  }

  /// Call this to cancel any ongoing auto-reconnect (e.g. user wants to stop).
  void cancelReconnect() {
    _userDisconnected = true;
    _reconnectInProgress = false;
    if (!isClosed) {
      emit(state.copyWith(
        isReconnecting: false,
        reconnectAttempt: 0,
        status: 'Disconnected',
      ));
    }
  }

  // ── Send Command ─────────────────────────────────────────────────────────
  /// BLE se connected device ko command bhejta hai (e.g. 'RESET').
  /// Agar connected nahi hai toh silently ignore karega.
  void sendCommand(String command) {
    if (!state.isConnected) {
      debugPrint('[BLE] ⚠️ Cannot send "$command" — not connected');
      return;
    }
    debugPrint('[BLE] 📤 Sending command: $command');
    bleService.send(command);
  }

  // ── Scan ──────────────────────────────────────────────────────────────────

  Future<bool> startScan() async {
    final granted = await _requestPermissions();
    if (!granted) {
      emit(state.copyWith(isPermissionDenied: true));
      return false;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      emit(state.copyWith(isBluetoothOff: true));
      return false;
    }

    emit(state.copyWith(
      foundDevices: [],
      isScanning: true,
      status: 'Scanning...',
    ));

    _scanSub?.cancel();
    _scanSub = bleService.scanStream.listen((results) {
      if (isClosed) return;
      final seen = <String, TimingGateBleDevice>{};
      for (final r in results) {
        final name = r.device.platformName;
        if (name.isEmpty) continue;
        final d = TimingGateBleDevice(
          name: name,
          uuid: r.device.remoteId.str,
          rssi: r.rssi,
        );
        if (!seen.containsKey(d.uuid) || seen[d.uuid]!.rssi < d.rssi) {
          seen[d.uuid] = d;
        }
      }
      final sorted = seen.values.toList()
        ..sort((a, b) => b.rssi.compareTo(a.rssi));
      emit(state.copyWith(
        foundDevices: sorted,
        status: '${sorted.length} device${sorted.length == 1 ? '' : 's'} found',
      ));
    });

    await bleService.startScan(timeout: const Duration(seconds: 10));
    if (!isClosed) emit(state.copyWith(isScanning: false));
    return true;
  }

  Future<void> stopScan() async {
    _scanSub?.cancel();
    await bleService.stopScan();
    if (!isClosed) emit(state.copyWith(isScanning: false));
  }

  // ── Connect ───────────────────────────────────────────────────────────────

  Future<void> connectToDevice(TimingGateBleDevice device) async {
    // User is manually connecting → reset the flag so auto-reconnect works later
    _userDisconnected = false;

    await stopScan();
    emit(state.copyWith(
      connectedDeviceName: device.name,
      status: 'Connecting to ${device.name}...',
      isConnecting: true,
    ));

    try {
      final allResults = FlutterBluePlus.lastScanResults;
      final match = allResults
          .where((r) => r.device.remoteId.str == device.uuid)
          .toList();

      if (match.isEmpty) {
        throw Exception('Device not found. Please scan again.');
      }

      await bleService.connect(match.first.device);

      if (isClosed) return;
      emit(state.copyWith(
        isConnected: true,
        isConnecting: false,
        status: 'Connected',
        connectedDeviceName: device.name,
        connectedRssi: device.rssi,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isConnecting: false,
        isConnected: false,
        status: 'Connection failed',
        connectedDeviceName: '',
      ));
      errorCubit.showError('Could not connect: $e');
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  /// User manually disconnects → set flag so auto-reconnect does NOT trigger.
  Future<void> disconnect() async {
    _userDisconnected = true;
    _reconnectInProgress = false;
    await bleService.disconnect(clearLastDevice: true);
    if (!isClosed) {
      emit(const TimingGateBleState());
    }
  }

  // ── Permission helper ─────────────────────────────────────────────────────

  Future<bool> _requestPermissions() async {
    if (!await Permission.bluetoothScan.isGranted) {
      if (!(await Permission.bluetoothScan.request()).isGranted) return false;
    }
    if (!await Permission.bluetoothConnect.isGranted) {
      if (!(await Permission.bluetoothConnect.request()).isGranted) return false;
    }
    return true;
  }

  void clearBluetoothOffFlag() =>
      emit(state.copyWith(isBluetoothOff: false));

  void clearPermissionDeniedFlag() =>
      emit(state.copyWith(isPermissionDenied: false));

  Future<void> openBluetoothSettings() => openAppSettings();

  @override
  Future<void> close() {
    _scanSub?.cancel();
    _rssiSub?.cancel();
    _connSub?.cancel();
    return super.close();
  }
}
