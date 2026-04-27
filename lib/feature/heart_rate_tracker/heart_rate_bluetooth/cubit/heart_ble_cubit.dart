import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

class HeartBleCubit extends Cubit<HeartBleState> {
  static const _methodChannel = MethodChannel('com.example.cl800/sdk_methods');
  static const _eventChannel = EventChannel('com.example.cl800/heartrate_stream');

  StreamSubscription? _dataSubscription;
  Timer? _scanTimeout;
  Timer? _syncDoneTimer;

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

        // ── Log every arriving event (remove once debugging is done) ──────
        debugPrint('[BLE] ◀ type=$type  value=$value');

        switch (type) {
          case "HEART_RATE":
            emit(state.copyWith(heartRate: _toInt(value)));
            break;

          case "BATTERY":
            emit(state.copyWith(battery: _toInt(value)));
            break;

          case "RSSI":
            emit(state.copyWith(connectedRssi: _toInt(value)));
            break; // RSSI spam suppressed from debugPrint above (still emitted)

          case "STATUS":
            debugPrint('[BLE] STATUS → $value');
            _handleStatus(value as String);
            break;

          case "LAST_DEVICE_ADDRESS":
            emit(state.copyWith(lastDeviceAddress: value as String));
            break;

          case "DEVICE_FOUND":
            _handleDeviceFound(value as Map<dynamic, dynamic>);
            break;

          // ── Device Info ──────────────────────────────────────────────
          case "SYSTEM_ID":
            emit(state.copyWith(systemId: value as String));
            break;
          case "MODEL_NAME":
            emit(state.copyWith(modelName: value as String));
            break;
          case "SERIAL_NUMBER":
            emit(state.copyWith(serialNumber: value as String));
            break;
          case "FIRMWARE_VERSION":
            emit(state.copyWith(firmwareVersion: value as String));
            break;
          case "HARDWARE_VERSION":
            emit(state.copyWith(hardwareVersion: value as String));
            break;
          case "SOFTWARE_VERSION":
            emit(state.copyWith(softwareVersion: value as String));
            break;
          case "VENDOR_NAME":
            emit(state.copyWith(vendorName: value as String));
            break;
          case "BODY_SENSOR_LOCATION":
            emit(state.copyWith(bodySensorLocation: value as String));
            break;

          // ── Real-time Sport ─────────────────────────────────────────
          case "SPORT":
          case "BODY_SPORT":
            final d = value as Map<dynamic, dynamic>;
            emit(state.copyWith(
              steps: d['step'] as int? ?? state.steps,
              distance: d['distance'] as int? ?? state.distance,
              calorie: d['calorie'] as int? ?? state.calorie,
            ));
            break;

          // ── Bonding ─────────────────────────────────────────────────
          case "BONDING":
            emit(state.copyWith(bondingStatus: value as String));
            break;

          case "ERROR":
            emit(state.copyWith(status: "Error: ${value as String}"));
            break;

          // ── Real-time Health (v3.0.5) ───────────────────────────────
          case "BODY_HEALTH":
          case "BODY_SPORT_HEALTH":
            final d = value as Map<dynamic, dynamic>;
            emit(state.copyWith(
              spo2: d['spo2'] as int? ?? state.spo2,
              systolic: d['systolic'] as int? ?? state.systolic,
              diastolic: d['diastolic'] as int? ?? state.diastolic,
              stressLevel: d['stress'] as int? ?? state.stressLevel,
              bodyTemp1: (d['temperature1'] as num?)?.toDouble() ?? state.bodyTemp1,
              bodyTemp2: (d['temperature2'] as num?)?.toDouble() ?? state.bodyTemp2,
              bodyTemp3: (d['temperature3'] as num?)?.toDouble() ?? state.bodyTemp3,
            ));
            break;

          case "BLOOD_OXYGEN":
            final d = value as Map<dynamic, dynamic>;
            emit(state.copyWith(
              spo2: d['spo2'] as int? ?? state.spo2,
              systolic: d['systolic'] as int? ?? state.systolic,
              diastolic: d['diastolic'] as int? ?? state.diastolic,
            ));
            break;

          case "TEMPERATURE":
            final d = value as Map<dynamic, dynamic>;
            emit(state.copyWith(
              bodyTemp1: (d['temperature1'] as num?)?.toDouble() ?? state.bodyTemp1,
              bodyTemp2: (d['temperature2'] as num?)?.toDouble() ?? state.bodyTemp2,
              bodyTemp3: (d['temperature3'] as num?)?.toDouble() ?? state.bodyTemp3,
            ));
            break;

          case "HEART_RATE_MAX":
            emit(state.copyWith(hrMax: _toInt(value)));
            break;

          case "HEART_RATE_MEASUREMENT":
            final d = value as Map<dynamic, dynamic>;
            final rawRr = d['rrIntervals'];
            final rrList = rawRr is List
                ? rawRr.whereType<num>().map((e) => e.toInt()).toList()
                : <int>[];
            emit(state.copyWith(
              heartRate: d['heartRate'] as int? ?? state.heartRate,
              rrIntervals: rrList.isNotEmpty ? rrList : null,
              hrv: rrList.length >= 2 ? _calculateRmssd(rrList) : null,
            ));
            break;

          // ── History Callbacks ────────────────────────────────────────
          case "HISTORY_SPORT":
            final sportList = _toList(value);
            debugPrint('[BLE-HISTORY] HISTORY_SPORT → ${sportList.length} records  first=${sportList.isNotEmpty ? sportList.first : "—"}');
            emit(state.copyWith(historySport: sportList));
            break;
          case "HISTORY_HR_RECORD":
            final hrRec = _toList(value);
            debugPrint('[BLE-HISTORY] HISTORY_HR_RECORD → ${hrRec.length} records  first=${hrRec.isNotEmpty ? hrRec.first : "—"}');
            emit(state.copyWith(historyHrRecord: hrRec));
            break;
          case "HISTORY_HR_DATA_CHUNK":
            final chunk = _toList(value);
            debugPrint('[BLE-HISTORY] HR chunk +${chunk.length}  total=${state.historyHrData.length + chunk.length}');
            emit(state.copyWith(
              historyHrData: [...state.historyHrData, ...chunk],
            ));
            break;
          case "HISTORY_HR_DATA_DONE":
            debugPrint('[BLE-HISTORY] HR streaming done — ${state.historyHrData.length} total');
            _syncDoneTimer?.cancel();
            emit(state.copyWith(status: "Sync complete"));
            break;
          case "HISTORY_RR_RECORD":
            final rrRec = _toList(value);
            debugPrint('[BLE-HISTORY] HISTORY_RR_RECORD → ${rrRec.length} records  first=${rrRec.isNotEmpty ? rrRec.first : "—"}');
            emit(state.copyWith(historyRrRecord: rrRec));
            break;
          case "HISTORY_RR_DATA":
            final rrData = _toList(value);
            debugPrint('[BLE-HISTORY] HISTORY_RR_DATA → ${rrData.length} entries  first=${rrData.isNotEmpty ? rrData.first : "—"}');
            emit(state.copyWith(historyRrData: rrData));
            break;
          case "HISTORY_STEP_RECORD":
            final stepRec = _toList(value);
            debugPrint('[BLE-HISTORY] HISTORY_STEP_RECORD → ${stepRec.length} records  first=${stepRec.isNotEmpty ? stepRec.first : "—"}');
            emit(state.copyWith(historyStepRecord: stepRec));
            break;
          case "HISTORY_STEP_DATA":
            final stepData = _toList(value);
            debugPrint('[BLE-HISTORY] HISTORY_STEP_DATA → ${stepData.length} entries  first=${stepData.isNotEmpty ? stepData.first : "—"}');
            emit(state.copyWith(historyStepData: stepData));
            break;
          case "HISTORY_SLEEP":
            final sleepList = _toList(value);
            debugPrint('[BLE-HISTORY] HISTORY_SLEEP → ${sleepList.length} sessions  first=${sleepList.isNotEmpty ? sleepList.first : "—"}');
            emit(state.copyWith(historySleep: sleepList));
            break;
          case "HISTORY_SINGLE_RECORD":
            debugPrint('[BLE-HISTORY] HISTORY_SINGLE_RECORD → $value');
            emit(state.copyWith(historySingleRecord: value as Map<dynamic, dynamic>));
            break;
          case "HISTORY_3D_DATA":
            debugPrint('[BLE-HISTORY] HISTORY_3D_DATA frame → $value');
            _handle3DHistory(value as Map<dynamic, dynamic>);
            break;
          case "INTERVAL_STEPS":
            final intervals = _toList(value);
            debugPrint('[BLE-HISTORY] INTERVAL_STEPS → ${intervals.length} intervals  first=${intervals.isNotEmpty ? intervals.first : "—"}');
            emit(state.copyWith(intervalSteps: intervals));
            break;
          case "SINGLE_TAP_RECORDS":
            final taps = _toList(value);
            debugPrint('[BLE-HISTORY] SINGLE_TAP_RECORDS → ${taps.length} events  first=${taps.isNotEmpty ? taps.first : "—"}');
            emit(state.copyWith(singleTapRecords: taps));
            break;
          case "CUSTOM_DATA":
            final bytes = (value as List).cast<int>();
            debugPrint('[BLE-HISTORY] CUSTOM_DATA → ${bytes.length} bytes  hex=${bytes.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}…');
            emit(state.copyWith(customData: bytes));
            break;

          case "HISTORY_SYNC_START":
            debugPrint('[BLE] History sync started — clearing old HR data');
            emit(state.copyWith(
              status: "Syncing history…",
              historyHrData: const [],   // clear old data for fresh stream
            ));
            // Auto-dismiss syncing overlay after 35 s (all timeouts done by then)
            _syncDoneTimer?.cancel();
            _syncDoneTimer = Timer(const Duration(seconds: 35), () {
              if (!isClosed && state.status.contains('yncing')) {
                debugPrint('[BLE] Sync timer expired — marking done');
                emit(state.copyWith(status: "Sync complete"));
              }
            });
            break;

          default:
            debugPrint('[BLE] ⚠ UNHANDLED type=$type  value=$value');
            break;
        }
      },
      onError: (dynamic error) {
        debugPrint('[BLE] ✖ Stream error: $error');
        emit(state.copyWith(status: "Stream Error: $error"));
      },
    );
  }

  // ─── Private Handlers ──────────────────────────────────────────────────────
  void _handleStatus(String s) {
    // After connection, check if notification permission was granted
    if (s == "Connected") _checkNotificationPermission();

    final isDisconnected = s == "Disconnected";
    final rssiReset = (s == "Disconnected" || s == "Reconnecting..." || s == "Link Lost") ? 0 : null;
    emit(state.copyWith(
      status: s,
      isConnected: s == "Connected",
      isScanning: s == "Scanning...",
      isReconnecting: s == "Reconnecting..." || s == "Link Lost",
      isBluetoothOff: s == "BLUETOOTH_OFF",
      isPermissionDenied: s == "PERMISSION_DENIED",
      connectedRssi: rssiReset,
      // Clear all data on disconnect
      heartRate: isDisconnected ? 0 : null,
      modelName: isDisconnected ? "" : null,
      firmwareVersion: isDisconnected ? "" : null,
      hardwareVersion: isDisconnected ? "" : null,
      softwareVersion: isDisconnected ? "" : null,
      serialNumber: isDisconnected ? "" : null,
      systemId: isDisconnected ? "" : null,
      vendorName: isDisconnected ? "" : null,
      steps: isDisconnected ? 0 : null,
      distance: isDisconnected ? 0 : null,
      calorie: isDisconnected ? 0 : null,
      bodySensorLocation: isDisconnected ? "" : null,
      bondingStatus: isDisconnected ? "" : null,
      spo2: isDisconnected ? 0 : null,
      systolic: isDisconnected ? 0 : null,
      diastolic: isDisconnected ? 0 : null,
      stressLevel: isDisconnected ? 0 : null,
      bodyTemp1: isDisconnected ? 0.0 : null,
      bodyTemp2: isDisconnected ? 0.0 : null,
      bodyTemp3: isDisconnected ? 0.0 : null,
      hrMax: isDisconnected ? 0 : null,
      rrIntervals: isDisconnected ? const [] : null,
      hrv: isDisconnected ? 0.0 : null,
    ));
  }

  void _handleDeviceFound(Map<dynamic, dynamic> d) {
    final uuid = d['uuid'] as String? ?? '';
    if (uuid.isEmpty || state.foundDevices.any((dev) => dev.uuid == uuid)) return;
    final dev = HeartBleDevice(
      name: d['name'] as String? ?? 'Unknown',
      uuid: uuid,
      rssi: int.tryParse(d['rssi']?.toString() ?? '0') ?? 0,
    );
    emit(state.copyWith(foundDevices: [...state.foundDevices, dev]));
  }

  void _handle3DHistory(Map<dynamic, dynamic> d) {
    final isLast = d['isLast'] as bool? ?? false;
    final updated = [...state.tempHistory3D, d];
    debugPrint('[BLE-3D] frame #${updated.length}  isLast=$isLast  data=$d');
    if (isLast) {
      debugPrint('[BLE-3D] ✔ 3D batch complete: ${updated.length} frames saved to history3D');
      emit(state.copyWith(history3D: updated, tempHistory3D: []));
    } else {
      emit(state.copyWith(tempHistory3D: updated));
    }
  }

  // ─── Permissions ────────────────────────────────────────────────────────────
  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      final permissions = [Permission.bluetoothScan, Permission.bluetoothConnect];
      if (info.version.sdkInt < 31) permissions.add(Permission.location);
      // Android 13+ (SDK 33) requires POST_NOTIFICATIONS for foreground service notification
      if (info.version.sdkInt >= 33) permissions.add(Permission.notification);
      await permissions.request();
    }
  }

  /// Check notification permission after connection — if denied, set flag for UI dialog
  Future<void> _checkNotificationPermission() async {
    if (!Platform.isAndroid) return;
    final info = await DeviceInfoPlugin().androidInfo;
    if (info.version.sdkInt < 33) return; // not needed below Android 13
    final status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      emit(state.copyWith(isNotificationDenied: true));
    }
  }

  void clearNotificationDeniedFlag() {
    emit(state.copyWith(isNotificationDenied: false));
  }

  // ─── Scan ───────────────────────────────────────────────────────────────────
  /// Returns true if scan started successfully, false if blocked (e.g. BT off)
  Future<bool> startScan() async {
    _scanTimeout?.cancel();
    await _checkPermissions();
    emit(state.copyWith(foundDevices: [], isScanning: true, status: "Scanning..."));
    try {
      await _methodChannel.invokeMethod('startScan');
      _scanTimeout = Timer(const Duration(seconds: 15), () {
        _stopScanNative();
        if (!isClosed) emit(state.copyWith(isScanning: false));
      });
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'BLUETOOTH_OFF') {
        emit(state.copyWith(
          status: "Bluetooth is off",
          isScanning: false,
          isBluetoothOff: true,
        ));
      } else if (e.code == 'PERMISSION_DENIED') {
        emit(state.copyWith(
          status: "PERMISSION_DENIED",
          isScanning: false,
          isPermissionDenied: true,
        ));
        await openAppSettings();
      } else {
        emit(state.copyWith(
          status: "Scan Failed: ${e.message}",
          isScanning: false,
        ));
      }
      return false;
    }
  }

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
    emit(state.copyWith(
      lastDevice: device.name,
      status: "Connecting to ${device.name}...",
      isScanning: false,
    ));
    try {
      await _methodChannel.invokeMethod('connectToDevice', {'uuid': device.uuid});
    } on PlatformException catch (e) {
      emit(state.copyWith(status: "Connect Failed: ${e.message}"));
    }
  }

  // ─── Disconnect ─────────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod('disconnect');
      emit(state.copyWith(
        isReconnecting: false,
        lastDeviceAddress: "",
      ));
    } on PlatformException catch (e) {
      emit(state.copyWith(status: "Disconnect Error: ${e.message}"));
    }
  }

  // ─── History Sync ──────────────────────────────────────────────────────────
  /// Requests all history data from the connected device.
  /// Results arrive asynchronously via the EventChannel callbacks.
  Future<void> syncAllHistory() async {
    debugPrint('[BLE] syncAllHistory() called');
    try {
      await _methodChannel.invokeMethod('syncAllHistory');
    } on PlatformException catch (e) {
      if (e.code == 'NOT_CONNECTED') {
        emit(state.copyWith(status: "Not connected — connect a device first"));
      } else {
        emit(state.copyWith(status: "Sync failed: ${e.message}"));
      }
      debugPrint('[BLE] syncAllHistory error: ${e.code} ${e.message}');
    }
  }

  // ─── Bluetooth Off / Permission Denied flags ───────────────────────────────
  void clearBluetoothOffFlag() {
    emit(state.copyWith(isBluetoothOff: false));
  }

  void clearPermissionDeniedFlag() {
    emit(state.copyWith(isPermissionDenied: false));
  }

  // ─── Open Bluetooth Settings ───────────────────────────────────────────────
  Future<void> openBluetoothSettings() async {
    try {
      await _methodChannel.invokeMethod('openBluetoothSettings');
    } catch (_) {}
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  double _calculateRmssd(List<int> rr) {
    double sumSq = 0;
    for (int i = 1; i < rr.length; i++) {
      final diff = (rr[i] - rr[i - 1]).toDouble();
      sumSq += diff * diff;
    }
    return math.sqrt(sumSq / (rr.length - 1));
  }

  int _toInt(dynamic v) => v is int ? v : int.tryParse(v.toString()) ?? 0;
  List<Map<dynamic, dynamic>> _toList(dynamic v) =>
      (v as List).cast<Map<dynamic, dynamic>>();

  @override
  Future<void> close() {
    _scanTimeout?.cancel();
    _syncDoneTimer?.cancel();
    _dataSubscription?.cancel();
    return super.close();
  }
}
