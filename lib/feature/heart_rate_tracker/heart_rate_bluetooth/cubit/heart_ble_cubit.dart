import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

class HeartBleCubit extends Cubit<HeartBleState> {
  static const _methodChannel = MethodChannel('com.example.cl800/sdk_methods');
  static const _eventChannel = EventChannel(
    'com.example.cl800/heartrate_stream',
  );

  StreamSubscription? _dataSubscription;
  Timer? _scanTimeout;

  final GlobalErrorCubit errorCubit;

  HeartBleCubit({required this.errorCubit}) : super(const HeartBleState()) {
    _listenToDeviceData();
  }

  // ─── EventChannel listener ──────────────────────────────────────────────────
  void _listenToDeviceData() {
    _dataSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        final map = event as Map<dynamic, dynamic>;
        final type = map['type'] as String;
        final value = map['value'];

        switch (type) {
          case "HEART_RATE":
            final hr = value is int
                ? value
                : int.tryParse(value.toString()) ?? state.heartRate;
            emit(state.copyWith(heartRate: hr));
            break;

          case "BATTERY":
            final bat = value is int
                ? value
                : int.tryParse(value.toString()) ?? state.battery;
            emit(state.copyWith(battery: bat));
            break;

          case "STATUS":
            final s = value as String;
            emit(
              state.copyWith(
                status: s,
                isConnected: s == "Connected",
                isScanning: s == "Scanning...",
              ),
            );
            break;

          case "DEVICE_FOUND":
            final d = value as Map<dynamic, dynamic>;
            final name = d['name'] as String? ?? 'Unknown';
            final uuid = d['uuid'] as String? ?? '';
            final rssi = int.tryParse(d['rssi'] as String? ?? '0') ?? 0;
            if (uuid.isEmpty) return;

            final alreadyExists = state.foundDevices.any(
              (dev) => dev.uuid == uuid,
            );
            if (!alreadyExists) {
              final updated = List<HeartBleDevice>.from(state.foundDevices)
                ..add(HeartBleDevice(name: name, uuid: uuid, rssi: rssi));
              emit(state.copyWith(foundDevices: updated));
            }
            break;
        }
      },
      onError: (dynamic error) {
        emit(state.copyWith(status: "Stream Error: $error"));
      },
    );
  }

  // ─── Permissions ────────────────────────────────────────────────────────────
  Future<bool> _checkPermissions() async {
    if (Platform.isIOS) {
      // On iOS 13+, CoreBluetooth triggers its own system Bluetooth permission
      // dialog automatically when scanning starts — controlled by
      // NSBluetoothAlwaysUsageDescription in Info.plist.
      // Requesting locationWhenInUse here was causing the "permission denied"
      // error, so we skip it entirely on iOS.
      return true;
    }

    // Android — request all needed permissions at runtime
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final granted =
        statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted &&
        statuses[Permission.location]!.isGranted;

    if (!granted) {
      emit(
        state.copyWith(status: "Bluetooth & Location permissions required"),
      );
    }
    return granted;
  }

  // ─── Scan ───────────────────────────────────────────────────────────────────
  Future<void> startScan() async {
    // Cancel any running timeout from a previous scan
    _scanTimeout?.cancel();

    final hasPermission = await _checkPermissions();
    if (!hasPermission) {
      emit(state.copyWith(status: "Permissions Denied", isScanning: false));
      return;
    }

    // Reset device list and mark scanning
    emit(
      state.copyWith(foundDevices: [], isScanning: true, status: "Scanning..."),
    );

    try {
      await _methodChannel.invokeMethod('startScan');

      // Auto-stop after 15 s so the spinner doesn't run forever
      _scanTimeout = Timer(const Duration(seconds: 15), () {
        _stopScanNative();
        if (!isClosed) emit(state.copyWith(isScanning: false));
      });
    } on PlatformException catch (e) {
      emit(
        state.copyWith(status: "Scan Failed: ${e.message}", isScanning: false),
      );
    }
  }

  // Stops the native BLE scan — no isScanning guard, safe to call anytime
  Future<void> _stopScanNative() async {
    try {
      await _methodChannel.invokeMethod('stopScan');
    } catch (_) {}
  }

  Future<void> stopScan() async {
    _scanTimeout?.cancel();
    await _stopScanNative();
    emit(state.copyWith(isScanning: false));
  }

  // ─── Connect ────────────────────────────────────────────────────────────────
  Future<void> connectToDevice(HeartBleDevice device) async {
    _scanTimeout?.cancel();
    emit(
      state.copyWith(
        lastDevice: device.name,
        status: "Connecting to ${device.name}...",
        isScanning: false,
      ),
    );
    try {
      await _methodChannel.invokeMethod('connectToDevice', {
        'uuid': device.uuid,
      });
    } on PlatformException catch (e) {
      emit(state.copyWith(status: "Connect Failed: ${e.message}"));
    }
  }

  // ─── Disconnect ─────────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      emit(state.copyWith(status: "Disconnect Error: ${e.message}"));
    }
  }

  @override
  Future<void> close() {
    _scanTimeout?.cancel();
    _dataSubscription?.cancel();
    return super.close();
  }
}
