import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/data/repository/history_repository.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/push_status_event.dart';
import 'package:xelex_esp/service/api/api_service.dart';
import 'package:xelex_esp/service/socket/history_watermark_store.dart';

class HeartBleCubit extends Cubit<HeartBleState> {
  static const _methodChannel = MethodChannel('com.example.cl800/sdk_methods');
  static const _eventChannel = EventChannel('com.example.cl800/heartrate_stream');

  // Broadcast stream of push lifecycle events. UI (e.g. _PushNowButton)
  // listens to surface meaningful messages per phase.
  final StreamController<PushStatusEvent> _pushEvents =
      StreamController<PushStatusEvent>.broadcast();
  Stream<PushStatusEvent> get pushEvents => _pushEvents.stream;

  void _emitPushEvent(PushStatusEvent e) {
    if (!_pushEvents.isClosed) _pushEvents.add(e);
  }

  // BLE history sync cooldown — auto-triggers (tab open, etc.) skip if a
  // sync was completed within this window. Manual sync button passes
  // force:true to bypass.
  static const Duration _syncCooldown = Duration(minutes: 10);


  StreamSubscription? _dataSubscription;
  Timer? _scanTimeout;
  Timer? _syncDoneTimer;
  Timer? _autoPushTimer;

  bool _pushingHistory = false;
  Map<String, dynamic>? _pendingPayload;
  bool _showingPlaceholderHr = false;
  bool _historySyncing = false;

  final GlobalErrorCubit errorCubit;

  final HistoryRepository _historyRepo = HistoryRepository.instance;

  // Set true before a user-initiated range sync so the post-sync auto-push
  // is skipped — range fetches are exploration, not server commits.
  bool _skipNextAutoPush = false;

  bool _sessionActive = false;
  void setSessionActive(bool active) => _sessionActive = active;

  HeartBleCubit({required this.errorCubit}) : super(const HeartBleState()) {
    _hydrateFromDb();
    _listenToDeviceData();
    _resumePollingIfNeeded();
  }

  /// Exposes DB-backed sync metadata for the UI (last sync time, data range,
  /// total count) — used by the SyncStatusBanner.
  HistorySyncMeta get historyMeta => _historyRepo.getMeta();

  /// Clears all persisted history. Used by a future "reset" action.
  Future<void> clearPersistedHistory() async {
    await _historyRepo.clearAll();
    emit(state.copyWith(
      historyHrData: const [],
      historyRrData: const [],
      historySleep: const [],
    ));
  }

  /// Loads persisted history from Hive so the UI shows last-known data
  /// before any live sync arrives.
  void _hydrateFromDb() {
    final h = _historyRepo.hydrate();
    if (h.hr.isEmpty && h.rr.isEmpty && h.sleep.isEmpty) return;
    emit(state.copyWith(
      historyHrData: h.hr,
      historyRrData: h.rr,
      historySleep: h.sleep,
    ));
  }

  List<Map<dynamic, dynamic>> _generatePlaceholderHr() {
    final rng = math.Random();
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 1));
    final list = <Map<dynamic, dynamic>>[];
    for (int i = 0; i < 60; i++) {
      final t = start.add(Duration(minutes: i));
      final hr = 68 + rng.nextInt(15) + (5 * (0.5 - 0.5 * (i % 10) / 10)).round();
      list.add(<dynamic, dynamic>{
        'stamp': t.millisecondsSinceEpoch,
        'heartRate': hr.clamp(60, 95),
      });
    }
    return list;
  }

  // ─── EventChannel listener ──────────────────────────────────────────────────
  void _listenToDeviceData() {
    _dataSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map<dynamic, dynamic>) return;
        final map = event;
        final type = map['type'] as String?;
        if (type == null) return;
        final value = map['value'];

        // ── Log every arriving event (remove once debugging is done) ──────
       // debugPrint('[BLE] ◀ type=$type  value=$value');

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
           // debugPrint('[BLE] STATUS → $value');
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
            // accumulate across notifications — device sends 1 value at a time
            final newBuffer = rrList.isEmpty
                ? state.rrBuffer
                : ([...state.rrBuffer, ...rrList].length > 60
                    ? ([...state.rrBuffer, ...rrList]).sublist(
                        ([...state.rrBuffer, ...rrList]).length - 60)
                    : [...state.rrBuffer, ...rrList]);
            emit(state.copyWith(
              heartRate: d['heartRate'] as int? ?? state.heartRate,
              rrIntervals: rrList.isNotEmpty ? rrList : null,
              rrBuffer: newBuffer,
              hrv: newBuffer.length >= 2 ? _calculateRmssd(newBuffer) : null,
            ));
            break;

          // ── History Callbacks ────────────────────────────────────────
          case "HISTORY_SPORT":
            final sportList = _toList(value);
            _dumpHistory('HISTORY_SPORT', sportList);
            emit(state.copyWith(historySport: sportList));
            break;
          case "HISTORY_HR_RECORD":
            final hrRec = _toList(value);
            _dumpHistory('HISTORY_HR_RECORD', hrRec);
            emit(state.copyWith(historyHrRecord: hrRec));
            break;
          case "HISTORY_HR_DATA_CHUNK":
            final chunk = _toList(value);
            _dumpHistory('HR_CHUNK_DATA', chunk);
            _historyRepo.persistHrChunk(chunk);
            final base = _showingPlaceholderHr ? <Map<dynamic, dynamic>>[] : state.historyHrData;
            _showingPlaceholderHr = false;
            emit(state.copyWith(
              historyHrData: [...base, ...chunk],
            ));
            break;
          case "HISTORY_HR_DATA_DONE":
            _dumpHistory('HR_FULL_DATA', state.historyHrData);
            emit(state.copyWith(status: "HR sync complete"));
            break;
          case "HISTORY_RR_RECORD":
            final rrRec = _toList(value);
            _dumpHistory('HISTORY_RR_RECORD', rrRec);
            emit(state.copyWith(historyRrRecord: rrRec));
            break;
          case "HISTORY_RR_DATA":
            final rrData = _toList(value);
            _dumpHistory('HISTORY_RR_DATA', rrData);
            emit(state.copyWith(historyRrData: rrData));
            break;
          case "HISTORY_RR_DATA_CHUNK":
            final chunk = _toList(value);
            _dumpHistory('RR_CHUNK_DATA', chunk);
            _historyRepo.persistRrChunk(chunk);
            emit(state.copyWith(
              historyRrData: [...state.historyRrData, ...chunk],
            ));
            break;
          case "HISTORY_RR_DATA_DONE":
            // debugPrint(
                // '[BLE-HISTORY] ✅ RR streaming DONE — total ${state.historyRrData.length} samples');
            _dumpHistory('RR_FULL_DATA', state.historyRrData);
            break;
          case "HISTORY_STEP_RECORD":
            final stepRec = _toList(value);
            _dumpHistory('HISTORY_STEP_RECORD', stepRec);
            emit(state.copyWith(historyStepRecord: stepRec));
            break;
          case "HISTORY_STEP_DATA":
            final stepData = _toList(value);
            _dumpHistory('HISTORY_STEP_DATA', stepData);
            emit(state.copyWith(historyStepData: stepData));
            break;
          case "HISTORY_SLEEP":
            final sleepList = _toList(value);
            _dumpHistory('HISTORY_SLEEP', sleepList);
            _historyRepo.persistSleep(sleepList);
            emit(state.copyWith(historySleep: sleepList));
            break;
          case "HISTORY_SINGLE_RECORD":
            // debugPrint('[BLE-HISTORY] HISTORY_SINGLE_RECORD → $value');
            emit(state.copyWith(historySingleRecord: value as Map<dynamic, dynamic>));
            break;
          case "HISTORY_3D_DATA":
            // debugPrint('[BLE-HISTORY] HISTORY_3D_DATA frame → $value');
            _handle3DHistory(value as Map<dynamic, dynamic>);
            break;
          case "INTERVAL_STEPS":
            final intervals = _toList(value);
            _dumpHistory('INTERVAL_STEPS', intervals);
            emit(state.copyWith(intervalSteps: intervals));
            break;
          case "SINGLE_TAP_RECORDS":
            final taps = _toList(value);
            _dumpHistory('SINGLE_TAP_RECORDS', taps);
            emit(state.copyWith(singleTapRecords: taps));
            break;
          case "CUSTOM_DATA":
            final bytes = (value as List).cast<int>();
            // debugPrint(
                // '[BLE-HISTORY] CUSTOM_DATA → ${bytes.length} bytes  hex=${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
            emit(state.copyWith(customData: bytes));
            break;

          case "HISTORY_SYNC_START":
            _showingPlaceholderHr = true;
            _historySyncing = true;
            emit(state.copyWith(
              status: "Syncing history…",
              historyHrData: _generatePlaceholderHr(),
              historyRrData: const [],
              historySleep: const [],
            ));
            _syncDoneTimer?.cancel();
            _syncDoneTimer = Timer(const Duration(seconds: 30), () {
              if (!isClosed && _historySyncing) {
                debugPrint('[BLE-HISTORY] ⏱ sync safety timer expired — marking complete');
                _historySyncing = false;
                _showingPlaceholderHr = false;
                final h = _historyRepo.hydrate();
                emit(state.copyWith(
                  status: "Sync complete",
                  historyHrData: h.hr,
                  historyRrData: h.rr,
                  historySleep: h.sleep,
                ));
                _historyRepo.updateAllMeta();
                _commitSyncCompleted();
                _scheduleAutoPush();
              }
            });
            break;

          case "SYNC_COMPLETE":
            _syncDoneTimer?.cancel();
            _historySyncing = false;
            _showingPlaceholderHr = false;
            final hiveData = _historyRepo.hydrate();
            emit(state.copyWith(
              status: "Sync complete",
              historyHrData: hiveData.hr,
              historyRrData: hiveData.rr,
              historySleep: hiveData.sleep,
            ));
            _historyRepo.updateAllMeta();
            _commitSyncCompleted();
            if (_skipNextAutoPush) {
              _skipNextAutoPush = false;
            } else {
              _scheduleAutoPush();
            }
            break;

          default:
            //debugPrint('[BLE] ⚠ UNHANDLED type=$type  value=$value');
            break;
        }
      },
      onError: (dynamic error) {
        //debugPrint('[BLE] ✖ Stream error: $error');
        if (!isClosed) emit(state.copyWith(status: "Stream Error: $error"));
      },
    );
  }

  // ─── Private Handlers ──────────────────────────────────────────────────────
  void _handleStatus(String s) {
    if (isClosed) return;
    final wasConnected = state.isConnected;
    final isDisconnected = s == "Disconnected";
    final bleOff = s == "BLUETOOTH_OFF";
    final permDenied = s == "PERMISSION_DENIED";

    if (bleOff || permDenied || isDisconnected) {
      _scanTimeout?.cancel();
      _stopScanNative();
    }

    final rssiReset = (isDisconnected || s == "Reconnecting..." || s == "Link Lost") ? 0 : null;
    emit(state.copyWith(
      status: s,
      isConnected: s == "Connected",
      isScanning: (bleOff || permDenied || isDisconnected) ? false : null,
      isReconnecting: s == "Reconnecting..." || s == "Link Lost",
      isBluetoothOff: bleOff,
      isPermissionDenied: permDenied,
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
      rrBuffer: isDisconnected ? const [] : null,
      hrv: isDisconnected ? 0.0 : null,
    ));

    // BLE connect hote hi check karo — agar cooldown se zyada time ho gaya to
    // auto sync trigger karo. Sync complete pe push automatically chal jaayega.
    if (s == "Connected" && !wasConnected) {
      _maybeAutoSyncOnConnect();
    }
  }

  Future<void> _maybeAutoSyncOnConnect() async {
    // Small delay — device info exchange + handshake settle hone do
    await Future.delayed(const Duration(seconds: 2));
    if (isClosed || !state.isConnected) return;
    if (_sessionActive) {
      debugPrint('[BLE] auto-sync skipped — activity session active');
      return;
    }
    syncNewFromDevice();
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
    //debugPrint('[BLE-3D] frame #${updated.length}  isLast=$isLast  data=$d');
    if (isLast) {
      //debugPrint('[BLE-3D] ✔ 3D batch complete: ${updated.length} frames saved to history3D');
      emit(state.copyWith(history3D: updated, tempHistory3D: []));
    } else {
      emit(state.copyWith(tempHistory3D: updated));
    }
  }

  // ─── Permissions ────────────────────────────────────────────────────────────
  /// Returns `true` when all required permissions are granted.
  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      final permissions = [Permission.bluetoothScan, Permission.bluetoothConnect];
      if (info.version.sdkInt < 31) permissions.add(Permission.location);
      if (info.version.sdkInt >= 33) permissions.add(Permission.notification);
      final results = await permissions.request();

      final denied = results.entries
          .where((e) => e.key != Permission.notification)
          .where((e) => !e.value.isGranted)
          .toList();

      if (denied.isEmpty) return true;

      final permanentlyDenied = denied.any((e) => e.value.isPermanentlyDenied);
      if (permanentlyDenied) {
        emit(state.copyWith(
          status: "PERMISSION_DENIED",
          isPermissionDenied: true,
        ));
        await openAppSettings();
        return false;
      }

      emit(state.copyWith(
        status: "PERMISSION_DENIED",
        isPermissionDenied: true,
      ));
      return false;
    }
    return true;
  }

  // ─── Scan ───────────────────────────────────────────────────────────────────
  /// Returns true if scan started successfully, false if blocked (e.g. BT off)
  Future<bool> startScan() async {
    _scanTimeout?.cancel();
    if (state.isScanning) await _stopScanNative();
    final granted = await _checkPermissions();
    if (!granted) return false;
    emit(state.copyWith(foundDevices: [], isScanning: true, status: "Scanning..."));
    try {
      await _methodChannel.invokeMethod('startScan');
      _scanTimeout = Timer(const Duration(seconds: 15), () {
        _stopScanNative();
        if (!isClosed) {
          emit(state.copyWith(isScanning: false, status: "Scan complete"));
        }
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
    await _stopScanNative();
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
  ///
  /// [force]: bypass the cooldown gate. Use `true` for manual sync button
  /// taps; auto-triggers (tab open, BLE reconnect) should leave it `false`.
  Future<void> syncAllHistory({bool force = false}) async {
    if (_sessionActive) {
      debugPrint('[BLE] syncAllHistory skipped — activity session active');
      return;
    }
    if (!force) {
      final wm = await HistoryWatermarkStore.create();
      final lastSync = wm.lastSyncAt;
      if (lastSync.millisecondsSinceEpoch > 0) {
        final elapsed = DateTime.now().difference(lastSync);
        if (elapsed < _syncCooldown) {
          return;
        }
      }
    }
    try {
      await _methodChannel.invokeMethod('syncAllHistory');
    } on PlatformException catch (e) {
      if (e.code == 'NOT_CONNECTED') {
        emit(state.copyWith(status: "Not connected — connect a device first"));
      } else {
        emit(state.copyWith(status: "Sync failed: ${e.message}"));
      }
    }
  }

  /// Smart sync — fetches only data newer than the last successful push.
  /// Falls back to full sync if no watermark exists (first time).
  /// Unlike syncHistoryRange, this does NOT skip auto-push.
  Future<void> syncNewFromDevice() async {
    if (_sessionActive) {
      debugPrint('[BLE] syncNewFromDevice skipped — activity session active');
      return;
    }
    try {
      final wm = await HistoryWatermarkStore.create();

      // Server watermark is the source of truth — seed local before deciding range.
      final serverStamp = await _fetchServerWatermark();
      if (serverStamp > 0) {
        await wm.commitHr(serverStamp);
      }

      final lastStamp = wm.lastHrStamp;
      final toMs = DateTime.now().millisecondsSinceEpoch;
      final int fromMs;
      if (lastStamp > 0) {
        fromMs = lastStamp > 9999999999 ? lastStamp : lastStamp * 1000;
      } else {
        fromMs = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      }
      await _methodChannel.invokeMethod('syncHistoryRange', {
        'fromMs': fromMs,
        'toMs': toMs,
      });
    } on PlatformException catch (e) {
      if (e.code == 'NOT_CONNECTED') {
        emit(state.copyWith(status: "Not connected — connect a device first"));
      } else {
        emit(state.copyWith(status: "Sync failed: ${e.message}"));
      }
    }
  }

  /// Fetches only the latest HR session from the device.
  /// Flutter's _filteredData handles the duration-based display filter.
  Future<void> syncLatestSession() async {
    _skipNextAutoPush = true;
    try {
      await _methodChannel.invokeMethod('syncLatestSession');
    } on PlatformException catch (e) {
      _skipNextAutoPush = false;
      if (e.code == 'NOT_CONNECTED') {
        emit(state.copyWith(status: "Not connected — connect a device first"));
      } else {
        emit(state.copyWith(status: "Sync failed: ${e.message}"));
      }
    }
  }

  /// Range-filtered history sync — DEVICE-ONLY, no server push.
  ///
  /// User-initiated exploration: fetches the requested window from the device
  /// into local Hive DB. Does NOT trigger the auto-push pipeline.
  /// Server push happens only via:
  ///   • `syncAllHistory()` (full sync → auto-push) , OR
  ///   • Manual "Push to Server Now" button → `pushHistoryBatch()`.
  ///
  /// Native filters record headers by stamp so only stamps within
  /// [from, to] (plus a 24h session-buffer for in-progress sessions)
  /// trigger per-record BLE fetches.
  ///
  /// Sleep cannot be filtered at SDK level — full sleep list arrives;
  /// Flutter side filters for display.
  Future<void> syncHistoryRange({
    required DateTime from,
    required DateTime to,
  }) async {
    _skipNextAutoPush = true;
    try {
      await _methodChannel.invokeMethod('syncHistoryRange', {
        'fromMs': from.millisecondsSinceEpoch,
        'toMs': to.millisecondsSinceEpoch,
      });
    } on PlatformException catch (e) {
      _skipNextAutoPush = false; // reset on failure
      if (e.code == 'NOT_CONNECTED') {
        emit(state.copyWith(status: "Not connected — connect a device first"));
      } else {
        emit(state.copyWith(status: "Sync failed: ${e.message}"));
      }
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

  // ─── History → Socket Push ─────────────────────────────────────────────────
  // On-demand socket lifecycle:
  //   1. pushHistoryBatch() — filter, build payload, connect socket
  //   2. onMonitoringStarted callback → submit batch
  //   3. onMetricSaved callback → commit watermarks → disconnect
  //   4. 20s timeout fallback → disconnect, pending watermarks discarded
  //      (next push will rebuild — watermark hasn't advanced)

  Future<void> _commitSyncCompleted() async {
    try {
      final wm = await HistoryWatermarkStore.create();
      // Don't pollute prefs with anon watermarks — they'd survive into the
      // next user's session (until next logout's prefs.clear()).
      if (wm.isAnonymous) return;
      await wm.commitSyncAtNow();
    } catch (e) {
      // debugPrint('[BLE] commitSyncAtNow failed: $e');
    }
  }

  void _scheduleAutoPush() {
    if (_sessionActive) return;
    _autoPushTimer?.cancel();
    _autoPushTimer = Timer(const Duration(seconds: 2), () {
      if (!isClosed && !_sessionActive) pushHistoryBatch();
    });
  }

  /// Sync from device then push to server. Device must be connected.
  Future<void> syncAndPush() async {
    if (!state.isConnected) {
      _emitPushEvent(const PushNotConnected());
      return;
    }
    await syncNewFromDevice();
    // SYNC_COMPLETE → _scheduleAutoPush() → pushHistoryBatch() automatically
  }

  /// Fetches the server-side last pushed HR timestamp for this athlete.
  /// Returns the timestamp (ms) or 0 on failure (caller falls back to local).
  /// Caches the result for 30 seconds to avoid duplicate API calls
  /// (syncNewFromDevice + pushHistoryBatch fire within seconds of each other).
  int _cachedServerWatermark = 0;
  int _watermarkFetchedAtMs = 0;
  static const int _watermarkCacheTtlMs = 30 * 1000; // 30 seconds

  Future<int> _fetchServerWatermark() async {
    // Return cached value if recently fetched
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_cachedServerWatermark > 0 &&
        (now - _watermarkFetchedAtMs) < _watermarkCacheTtlMs) {
      return _cachedServerWatermark;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(PrefKeys.userToken) ?? '';
      if (token.isEmpty) return 0;
      ApiService.instance.setAuthToken(token);
      final response = await ApiService.instance.dio.get(
        '/athlete/health_metrics/last_timestamp',
      );
      final data = response.data as Map<String, dynamic>? ?? {};
      if (data['success'] == true) {
        final inner = data['data'] as Map<String, dynamic>? ?? {};
        final stamp = (inner['recorded_at'] as num?)?.toInt() ?? 0;
        if (stamp > 0) {
          _cachedServerWatermark = stamp;
          _watermarkFetchedAtMs = now;
        }
        return stamp;
      }
      return 0;
    } on DioException {
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> pushHistoryBatch() async {
    if (_pushingHistory) {
      _emitPushEvent(const PushAlreadyInFlight());
      return;
    }
    _pushingHistory = true;
    _emitPushEvent(const PushPreparing());
    try {
      final wm = await HistoryWatermarkStore.create();
      if (wm.isAnonymous) {
        _emitPushEvent(const PushAnonymous());
        _cleanupPush();
        return;
      }

      // Server is the single source of truth — fetch and seed local watermark.
      // On failure (no internet, timeout, etc.) local cache is used as fallback.
      final serverStamp = await _fetchServerWatermark();
      if (serverStamp > 0) {
        await wm.commitHr(serverStamp);
      }

      final watermark = wm.lastHrStamp;
      int stampMs(int s) => s > 9999999999 ? s : s * 1000;

      final hive = _historyRepo.hydrate();

      final hrFiltered = hive.hr.where((r) {
        final s = (r['stamp'] as num?)?.toInt() ?? 0;
        if (s <= 0) return false;
        return stampMs(s) > watermark;
      }).toList();

      final rrFiltered = hive.rr.where((r) {
        final s = (r['stamp'] as num?)?.toInt() ?? 0;
        if (s <= 0) return false;
        return stampMs(s) > watermark;
      }).toList();

      final sleepFiltered = hive.sleep.where((r) {
        final u = (r['utc'] as num?)?.toInt() ?? 0;
        if (u <= 0) return false;
        return stampMs(u) > watermark;
      }).toList();

      if (hrFiltered.isEmpty &&
          rrFiltered.isEmpty &&
          sleepFiltered.isEmpty) {
        // debugPrint('[HISTORY-PUSH] nothing new to push (all under watermark)');
        _emitPushEvent(const PushNothingNew());
        _pushingHistory = false;
        return;
      }

      final healthMetrics = hrFiltered.map((r) {
        final stamp = (r['stamp'] as num?)?.toInt() ?? 0;
        return <String, dynamic>{
          'heart_rate': (r['heartRate'] as num?)?.toInt() ?? 0,
          'sugar_level': null,
          'spo2': null,
          'stress_level': null,
          'lat': null,
          'lng': null,
          // Chileaf SDK stamps are already in milliseconds — backend expects ms.
          'timestamp': stamp,
        };
      }).toList();

      final sleepMetrics = sleepFiltered.map((r) {
        final actions = (r['actions'] as List?)
                ?.whereType<num>()
                .map((e) => e.toInt())
                .toList() ??
            const <int>[];
        return <String, dynamic>{
          'utc': (r['utc'] as num?)?.toInt() ?? 0,
          'actions': actions,
        };
      }).toList();

      // RR: ek hi session, sessionStamp = batch ka max stamp
      Map<String, dynamic>? rrSession;
      if (rrFiltered.isNotEmpty) {
        final samples = rrFiltered.map((r) {
          return <String, dynamic>{
            't': (r['stamp'] as num?)?.toInt() ?? 0,
            'value': (r['value'] as num?)?.toInt() ?? 0,
          };
        }).toList();
        final maxRrStamp = samples
            .map((s) => s['t'] as int)
            .reduce((a, b) => a > b ? a : b);
        rrSession = <String, dynamic>{
          'sessionStamp': maxRrStamp,
          'samples': samples,
        };
      }

      final payload = <String, dynamic>{};
      if (healthMetrics.isNotEmpty) payload['health_metrics'] = healthMetrics;
      if (sleepMetrics.isNotEmpty) payload['sleep_metrics'] = sleepMetrics;
      if (rrSession != null) payload['rr_interval'] = [rrSession];

      final rrSampleCount =
          rrSession != null ? (rrSession['samples'] as List).length : 0;
      // debugPrint(
          // '[HISTORY-PUSH] sending hr=${healthMetrics.length} sleep=${sleepMetrics.length} rr_samples=$rrSampleCount');

      // Snapshot counts for the uploading event (emitted once the socket
      // accepts the batch — see onMonitoringStarted in _connectAndPush).
      _pendingHrCount = healthMetrics.length;
      _pendingSleepCount = sleepMetrics.length;
      _pendingRrCount = rrSampleCount;

      _pendingPayload = payload;
      await _pushV3();
      // _pushingHistory cleared in _cleanupPush() — async lifecycle
    } catch (e) {
      // debugPrint('[HISTORY-PUSH] build failed: $e');
      _emitPushEvent(PushBuildFailed(e.toString()));
      _cleanupPush();
    }
  }

  // Count snapshots populated in pushHistoryBatch and surfaced via
  // PushUploading once the socket monitoring-started handshake completes.
  int _pendingHrCount = 0;
  int _pendingRrCount = 0;
  int _pendingSleepCount = 0;

  // Token fetch karke REST API call karo — 15-min windows mein chunked.
  Future<void> _connectAndPush() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(PrefKeys.userToken) ?? '';
    if (token.isEmpty) {
      _emitPushEvent(const PushMissingAuth());
      _cleanupPush();
      return;
    }

    final payload = _pendingPayload;
    if (payload == null) {
      _cleanupPush();
      return;
    }

    _emitPushEvent(PushUploading(
      hrCount: _pendingHrCount,
      rrCount: _pendingRrCount,
      sleepCount: _pendingSleepCount,
    ));

    try {
      ApiService.instance.setAuthToken(token);

      final chunks = _split15MinChunks(payload);
      Map<String, dynamic> lastAck = {};
      final wm = await HistoryWatermarkStore.create();

      for (final chunk in chunks) {
        final response = await ApiService.instance.dio.post(
          '/athlete/health_metrics',
          data: chunk,
        );
        if (response.data is Map<String, dynamic>) {
          lastAck = response.data as Map<String, dynamic>;
          await _commitChunkWatermark(wm, lastAck, chunk);
        }
      }

      await wm.commitPushAtNow();
      _emitPushEvent(PushSucceeded(lastAck));
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          _emitPushEvent(const PushTimedOut());
        case DioExceptionType.badResponse:
          if (status == 401 || status == 403) {
            final msg = _extractServerMessage(e.response?.data) ?? 'Auth failed';
            _emitPushEvent(PushAuthFailed(msg));
          } else {
            final msg = _extractServerMessage(e.response?.data) ??
                'Server error ($status)';
            _emitPushEvent(PushFailed(msg));
          }
        case DioExceptionType.connectionError:
          _emitPushEvent(const PushFailed('No internet connection'));
        default:
          _emitPushEvent(PushFailed(e.message ?? 'Unexpected error'));
      }
    } catch (e) {
      _emitPushEvent(PushFailed(e.toString()));
    } finally {
      _cleanupPush();
    }
  }

  // ─── V3 Push: gzip .zip file + job polling ─────────────────────────────────

  /// V3 push — payload ko in-memory gzip compress karke raw bytes
  /// POST karo /athlete/health_metrics/v3 pe.
  /// Response mein job_id milta hai — har 1s poll karo jab tak done/failed.
  Future<void> _pushV3() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(PrefKeys.userToken) ?? '';
    if (token.isEmpty) {
      _emitPushEvent(const PushMissingAuth());
      _cleanupPush();
      return;
    }

    final payload = _pendingPayload;
    if (payload == null) {
      _cleanupPush();
      return;
    }

    _emitPushEvent(PushUploading(
      hrCount: _pendingHrCount,
      rrCount: _pendingRrCount,
      sleepCount: _pendingSleepCount,
    ));

    try {
      // 1. JSON encode → gzip compress (in-memory)
      final jsonString = jsonEncode(payload);
      final jsonBytes = utf8.encode(jsonString);
      final gzipBytes = gzip.encode(jsonBytes);
      debugPrint('[V3-PUSH] JSON size: ${jsonBytes.length} bytes → Gzip size: ${gzipBytes.length} bytes (${(gzipBytes.length * 100 / jsonBytes.length).toStringAsFixed(1)}% ratio)');

      // 2. POST raw gzip bytes via dart:io HttpClient
      // Dio ka transformer List<int>/Uint8List ko JSON array [31,139,8,...] bana
      // deta hai — isliye direct HttpClient use karo for guaranteed raw bytes.
      final baseUrl = ApiService.instance.dio.options.baseUrl;
      final uri = Uri.parse('$baseUrl/athlete/health_metrics/v3');

      debugPrint('[V3-PUSH] ═══════════════════════════════════════════');
      debugPrint('[V3-PUSH] POST $uri');
      debugPrint('[V3-PUSH] Headers:');
      debugPrint('[V3-PUSH]   Content-Type: application/json');
      debugPrint('[V3-PUSH]   Content-Encoding: gzip');
      debugPrint('[V3-PUSH]   Content-Length: ${gzipBytes.length}');
      debugPrint('[V3-PUSH]   Authorization: Bearer ${token.substring(0, 20)}...');
      debugPrint('[V3-PUSH] Gzip magic bytes: ${gzipBytes.take(4).toList()}');
      debugPrint('[V3-PUSH] Sending ${gzipBytes.length} raw bytes...');

      final stopwatch = Stopwatch()..start();

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 60);

      final request = await httpClient.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Content-Encoding', 'gzip');
      request.headers.contentLength = gzipBytes.length;
      request.add(gzipBytes);

      final httpResponse = await request.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      httpClient.close();

      stopwatch.stop();

      debugPrint('[V3-PUSH] ───────────────────────────────────────────');
      debugPrint('[V3-PUSH] Status: ${httpResponse.statusCode} ${httpResponse.reasonPhrase}');
      debugPrint('[V3-PUSH] Time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('[V3-PUSH] Response headers:');
      httpResponse.headers.forEach((name, values) {
        debugPrint('[V3-PUSH]   $name: ${values.join(', ')}');
      });
      debugPrint('[V3-PUSH] Body: $responseBody');
      debugPrint('[V3-PUSH] ═══════════════════════════════════════════');

      final responseData = jsonDecode(responseBody) as Map<String, dynamic>? ?? {};
      final data = responseData['data'] as Map<String, dynamic>? ?? {};
      final statusCode = httpResponse.statusCode;

      // Auth check
      if (statusCode == 401 || statusCode == 403) {
        final msg = _extractServerMessage(responseData) ?? 'Auth failed';
        _emitPushEvent(PushAuthFailed(msg));
        return;
      }

      // V3 returns 202 Accepted — anything else is unexpected
      if (statusCode != 202) {
        final msg = _extractServerMessage(responseData) ??
            'Server error ($statusCode)';
        _emitPushEvent(PushFailed(msg));
        return;
      }

      final jobId = data['job_id']?.toString() ?? '';
      if (jobId.isEmpty) {
        _emitPushEvent(const PushFailed('No job_id in server response'));
        return;
      }

      // Invalidate watermark cache — push ke baad server watermark badal jaayega
      _cachedServerWatermark = 0;
      _watermarkFetchedAtMs = 0;

      // 3. Persist polling state — survives app kill
      await _savePollingState(jobId);
      emit(state.copyWith(
        isPolling: true,
        pollingJobId: jobId,
        pollingMessage: 'Processing on server…',
      ));

      // 4. Poll job status every 1 second
      _emitPushEvent(PushPolling(jobId));
      final pollResult = await _pollJobStatus(jobId);

      // 5. Clear polling state regardless of result
      await _clearPollingState();
      emit(state.copyWith(
        isPolling: false,
        pollingJobId: '',
        pollingMessage: '',
      ));

      if (pollResult == null) {
        _emitPushEvent(const PushFailed('Job timed out or failed on server'));
        return;
      }
      if (pollResult['error'] != null) {
        _emitPushEvent(PushFailed(pollResult['error'].toString()));
        return;
      }

      // 4. Commit watermarks — V3 job result wraps counts inside result
      // Response: { data: { job_id, status, result: { health_count, sleep_count, rr_count, ... } } }
      final wm = await HistoryWatermarkStore.create();
      await _commitV3Watermark(wm, pollResult, payload);
      await wm.commitPushAtNow();
      _emitPushEvent(PushSucceeded(pollResult));
    } on SocketException catch (e) {
      debugPrint('[V3-PUSH] ✖ SocketException: $e');
      _emitPushEvent(const PushFailed('No internet connection'));
    } on HttpException catch (e) {
      debugPrint('[V3-PUSH] ✖ HttpException: ${e.message}');
      _emitPushEvent(PushFailed('HTTP error: ${e.message}'));
    } on TimeoutException {
      debugPrint('[V3-PUSH] ✖ TimeoutException');
      _emitPushEvent(const PushTimedOut());
    } catch (e) {
      debugPrint('[V3-PUSH] ✖ Unexpected error: $e');
      _emitPushEvent(PushFailed(e.toString()));
    } finally {
      _cleanupPush();
    }
  }

  /// Poll GET /athlete/ingestion/job/:jobId every 1 second.
  /// Returns the result map on "done", null on timeout,
  /// or {'error': '...'} on server-side failure.
  Future<Map<String, dynamic>?> _pollJobStatus(String jobId) async {
    const maxAttempts = 60; // 60 seconds max
    int consecutiveErrors = 0;
    const maxConsecutiveErrors = 5;

    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 1));
      try {
        final response = await ApiService.instance.dio.get(
          '/athlete/ingestion/job/$jobId',
        );
        consecutiveErrors = 0; // Reset on success

        final respData = response.data as Map<String, dynamic>? ?? {};
        final data = respData['data'] as Map<String, dynamic>? ?? {};
        final status = data['status']?.toString() ?? '';

        if (status == 'done') {
          return data['result'] as Map<String, dynamic>? ?? data;
        }
        if (status == 'failed') {
          final reason = data['error']?.toString() ??
              data['message']?.toString() ??
              'Job failed on server';
          return <String, dynamic>{'error': reason};
        }
        // queued / processing — continue polling
      } on DioException catch (e) {
        consecutiveErrors++;
        // Auth error — stop immediately, no point retrying
        final code = e.response?.statusCode ?? 0;
        if (code == 401 || code == 403) {
          return <String, dynamic>{'error': 'Auth expired during polling'};
        }
        // Too many consecutive network errors — give up
        if (consecutiveErrors >= maxConsecutiveErrors) {
          return <String, dynamic>{'error': 'Network error during polling'};
        }
      } catch (_) {
        consecutiveErrors++;
        if (consecutiveErrors >= maxConsecutiveErrors) {
          return <String, dynamic>{'error': 'Unexpected error during polling'};
        }
      }
    }
    return null; // Timed out after 60s
  }

  // ─── Polling State Persistence ──────────────────────────────────────────────

  /// Save polling state to SharedPrefs — survives app kill.
  Future<void> _savePollingState(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.pollingActive, true);
    await prefs.setString(PrefKeys.pollingJobId, jobId);
    await prefs.setInt(
        PrefKeys.pollingStartedAt, DateTime.now().millisecondsSinceEpoch);
  }

  /// Clear polling state from SharedPrefs — called on done/failed/timeout.
  Future<void> _clearPollingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.pollingActive, false);
    await prefs.remove(PrefKeys.pollingJobId);
    await prefs.remove(PrefKeys.pollingStartedAt);
  }

  /// App reopen pe check karo — agar polling chal rahi thi toh resume karo.
  /// Stale check: 2 min se purana toh skip (server job already done/failed).
  static const int _pollingMaxAgeMs = 4 * 60 * 1000; // 4 minutes

  Future<void> _resumePollingIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool(PrefKeys.pollingActive) ?? false;
    if (!active) return;

    final jobId = prefs.getString(PrefKeys.pollingJobId) ?? '';
    final startedAt = prefs.getInt(PrefKeys.pollingStartedAt) ?? 0;
    if (jobId.isEmpty || startedAt <= 0) {
      await _clearPollingState();
      return;
    }

    // Stale check — 2 min se purana toh skip
    final elapsed = DateTime.now().millisecondsSinceEpoch - startedAt;
    if (elapsed > _pollingMaxAgeMs) {
      await _clearPollingState();
      return;
    }

    // Resume polling
    emit(state.copyWith(
      isPolling: true,
      pollingJobId: jobId,
      pollingMessage: 'Resuming server processing…',
    ));
    _emitPushEvent(PushPolling(jobId));

    final pollResult = await _pollJobStatus(jobId);
    await _clearPollingState();
    emit(state.copyWith(
      isPolling: false,
      pollingJobId: '',
      pollingMessage: '',
    ));

    if (pollResult == null) {
      _emitPushEvent(const PushFailed('Job timed out or failed on server'));
      return;
    }
    if (pollResult['error'] != null) {
      _emitPushEvent(PushFailed(pollResult['error'].toString()));
      return;
    }

    // Success — commit watermarks
    // Note: original payload not available after app kill, so we rely on
    // server's watermark update. Invalidate cache to force fresh fetch.
    _cachedServerWatermark = 0;
    _watermarkFetchedAtMs = 0;
    final wm = await HistoryWatermarkStore.create();
    await wm.commitPushAtNow();
    _emitPushEvent(PushSucceeded(pollResult));
  }

  /// V3 watermark commit — job result se counts & timestamps nikal ke
  /// local watermarks advance karo.
  /// V3 result: { health_count, sleep_count, rr_count, ... }
  /// (V2 had nested `data` wrapper — V3 result comes directly from poll)
  Future<void> _commitV3Watermark(
    HistoryWatermarkStore wm,
    Map<String, dynamic> result,
    Map<String, dynamic> payload,
  ) async {
    try {
      final hrCount = (result['health_count'] as num?)?.toInt() ?? 0;
      final sleepCount = (result['sleep_count'] as num?)?.toInt() ?? 0;
      final rrCount = (result['rr_count'] as num?)?.toInt() ?? 0;

      // HR watermark — payload se max timestamp nikalo
      if (hrCount > 0) {
        final hrList = payload['health_metrics'] as List? ?? [];
        final maxHrStamp = hrList
            .whereType<Map>()
            .map((r) => (r['timestamp'] as num?)?.toInt() ?? 0)
            .fold(0, (a, b) => a > b ? a : b);
        if (maxHrStamp > 0) await wm.commitHr(maxHrStamp);
      }

      // RR watermark
      if (rrCount > 0) {
        final rrList = payload['rr_interval'] as List? ?? [];
        final maxRrStamp = rrList
            .whereType<Map>()
            .map((r) => (r['sessionStamp'] as num?)?.toInt() ?? 0)
            .fold(0, (a, b) => a > b ? a : b);
        if (maxRrStamp > 0) await wm.commitRr(maxRrStamp);
      }

      // Sleep watermark
      if (sleepCount > 0) {
        final sleepList = payload['sleep_metrics'] as List? ?? [];
        final maxUtc = sleepList
            .whereType<Map>()
            .map((r) => (r['utc'] as num?)?.toInt() ?? 0)
            .fold(0, (a, b) => a > b ? a : b);
        if (maxUtc > 0) await wm.commitSleep(maxUtc);
      }
    } catch (_) {}
  }

  // ─── V2 Push (legacy — chunked, kept for reference) ────────────────────────

  // Payload ko 15-minute time windows mein split karta hai, phir har window
  // ko max _maxRowsPerChunk rows mein sub-chunk karta hai taaki "data too
  // large" error kabhi na aaye.
  static const int _chunkWindowMs = 15 * 60 * 1000;
  static const int _maxRowsPerChunk = 500;

  List<Map<String, dynamic>> _split15MinChunks(Map<String, dynamic> payload) {
    final healthList = (payload['health_metrics'] as List? ?? [])
        .cast<Map<dynamic, dynamic>>();
    final sleepList = (payload['sleep_metrics'] as List? ?? [])
        .cast<Map<dynamic, dynamic>>();
    final rrList = (payload['rr_interval'] as List? ?? [])
        .cast<Map<dynamic, dynamic>>();

    // bucket key = (stampMs ~/ 15min) * 15min
    int bucketKey(int ms) => (ms ~/ _chunkWindowMs) * _chunkWindowMs;

    final buckets = <int, Map<String, List<dynamic>>>{};

    void addTo(int key, String field, dynamic item) {
      buckets.putIfAbsent(key, () => {});
      buckets[key]!.putIfAbsent(field, () => []);
      buckets[key]![field]!.add(item);
    }

    for (final m in healthList) {
      final t = (m['timestamp'] as num?)?.toInt() ?? 0;
      if (t > 0) addTo(bucketKey(t), 'health_metrics', m);
    }
    for (final m in sleepList) {
      // utc is in seconds — convert to ms for bucketing
      final t = ((m['utc'] as num?)?.toInt() ?? 0) * 1000;
      if (t > 0) addTo(bucketKey(t), 'sleep_metrics', m);
    }
    for (final r in rrList) {
      final t = (r['sessionStamp'] as num?)?.toInt() ?? 0;
      if (t > 0) addTo(bucketKey(t), 'rr_interval', r);
    }

    final sortedKeys = buckets.keys.toList()..sort();
    final result = <Map<String, dynamic>>[];

    for (final k in sortedKeys) {
      final b = buckets[k]!;
      final hr = b['health_metrics'] ?? [];
      final sleep = b['sleep_metrics'] ?? [];
      final rr = b['rr_interval'] ?? [];

      // Sub-chunk health_metrics by _maxRowsPerChunk rows.
      // Sleep & RR are small — attach to first sub-chunk only.
      if (hr.isEmpty) {
        // No HR — just send sleep/rr if present
        if (sleep.isNotEmpty || rr.isNotEmpty) {
          result.add(<String, dynamic>{
            if (sleep.isNotEmpty) 'sleep_metrics': sleep,
            if (rr.isNotEmpty) 'rr_interval': rr,
          });
        }
      } else {
        for (int i = 0; i < hr.length; i += _maxRowsPerChunk) {
          final end = (i + _maxRowsPerChunk).clamp(0, hr.length);
          final subChunk = <String, dynamic>{
            'health_metrics': hr.sublist(i, end),
          };
          // Attach sleep & rr to first sub-chunk of this window
          if (i == 0) {
            if (sleep.isNotEmpty) subChunk['sleep_metrics'] = sleep;
            if (rr.isNotEmpty) subChunk['rr_interval'] = rr;
          }
          result.add(subChunk);
        }
      }
    }

    return result;
  }

  String? _extractServerMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data['msg']?.toString();
    }
    return null;
  }

  Future<void> _commitChunkWatermark(
    HistoryWatermarkStore wm,
    Map<String, dynamic> ack,
    Map<String, dynamic> chunk,
  ) async {
    try {
      final data = ack['data'] as Map<String, dynamic>? ?? {};
      final hrCount = (data['health_count'] as num?)?.toInt() ?? 0;
      final sleepCount = (data['sleep_count'] as num?)?.toInt() ?? 0;
      final rrCount = (data['rr_count'] as num?)?.toInt() ?? 0;

      if (hrCount > 0) {
        final latest = data['latestHealthReading'] as Map<String, dynamic>?;
        final serverStamp = (latest?['recorded_at'] as num?)?.toInt();
        if (serverStamp != null && serverStamp > 0) {
          await wm.commitHr(serverStamp);
        }
      }

      if (rrCount > 0) {
        final rrList = chunk['rr_interval'] as List?;
        if (rrList != null && rrList.isNotEmpty) {
          final maxRrStamp = rrList
              .whereType<Map>()
              .map((r) => (r['sessionStamp'] as num?)?.toInt() ?? 0)
              .fold(0, (a, b) => a > b ? a : b);
          if (maxRrStamp > 0) await wm.commitRr(maxRrStamp);
        }
      }

      if (sleepCount > 0) {
        final sleepList = chunk['sleep_metrics'] as List?;
        if (sleepList != null && sleepList.isNotEmpty) {
          final maxUtc = sleepList
              .whereType<Map>()
              .map((r) => (r['utc'] as num?)?.toInt() ?? 0)
              .fold(0, (a, b) => a > b ? a : b);
          if (maxUtc > 0) await wm.commitSleep(maxUtc);
        }
      }
    } catch (_) {}
  }

  void _cleanupPush() {
    _pendingPayload = null;
    _pushingHistory = false;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  // Device history data ko console pe dump karta hai. Android logcat ki
  // per-line ~1000 char limit hoti hai — isliye 800 char chunks me todte hain.
  void _dumpHistory(String tag, List<dynamic> data) {
    //debugPrint('[BLE-HISTORY] $tag — count=${data.length}');
    if (data.isEmpty) return;
    final str = data.toString();
    const chunkSize = 800;
    if (str.length <= chunkSize) {
      //debugPrint('[BLE-HISTORY] $tag → $str');
      return;
    }
    final total = (str.length / chunkSize).ceil();
    for (var i = 0; i < total; i++) {
      final start = i * chunkSize;
      final end = (start + chunkSize) < str.length ? start + chunkSize : str.length;
     // debugPrint('[BLE-HISTORY] $tag [${i + 1}/$total] ${str.substring(start, end)}');
    }
  }

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
      v is List ? v.whereType<Map<dynamic, dynamic>>().toList() : const [];

  @override
  Future<void> close() {
    _scanTimeout?.cancel();
    _syncDoneTimer?.cancel();
    _autoPushTimer?.cancel();
    _dataSubscription?.cancel();
    _pushEvents.close();
    return super.close();
  }
}
