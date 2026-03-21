import 'dart:async';

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

  TimingGateBleCubit({
    required this.errorCubit,
    required this.bleService,
  }) : super(const TimingGateBleState()) {
    // Unexpected disconnects
    _connSub = bleService.connectionStream.listen((connected) {
      if (!connected && state.isConnected) {
        emit(const TimingGateBleState(
          status: 'Disconnected',
          isConnected: false,
        ));
        errorCubit.showWarning('Timing gate disconnected.');
      }
    });

    // RSSI updates
    _rssiSub = bleService.rssiStream.listen((rssi) {
      if (!isClosed && state.isConnected) {
        emit(state.copyWith(connectedRssi: rssi));
      }
    });
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

  Future<void> disconnect() async {
    await bleService.disconnect();
    if (!isClosed) emit(const TimingGateBleState());
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
