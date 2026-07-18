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
import 'package:xelex_esp/core/logging/file_logger.dart';
import 'package:xelex_esp/core/util/compression.dart';
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
  // App-open pe last device se bounded auto-reconnect (idle case — koi session
  // active nahi). Session-recovery ka apna aggressive loop alag hai.
  Timer? _launchReconnectTimer;
  int _launchReconnectAttempt = 0;
  static const _maxLaunchReconnectAttempts = 3;
  static const _launchReconnectInterval = Duration(seconds: 20);
  // App-launch auto-reconnect chal raha hai kya. Native link-loss reconnect aur
  // launch reconnect dono "Reconnecting..." bhejte hain — ye flag unhe alag
  // karta hai taaki launch-reconnect pe auto-sync chale par link-loss flap pe
  // nahi. Connect hone ya attempts khatam hone par clear ho jaata hai.
  bool _launchReconnectActive = false;

  bool _pushingHistory = false;
  Map<String, dynamic>? _pendingPayload;
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
    _hydrateLastDevice();
    _listenToDeviceData();
    _resumePollingIfNeeded();
  }

  /// Cold launch pe last-connected device prefs se wapas lao. Native ka
  /// `lastConnectedDevice` in-memory hai aur `LAST_DEVICE_ADDRESS` event sirf
  /// connect hone par (ya already-connected replay pe) aata hai — app kill ke
  /// baad dono khali hote hain, to `reconnectLastDevice()` ke paas address hi
  /// nahi hota. Ye hydration us gap ko bharta hai.
  Future<void> _hydrateLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    if (isClosed) return;
    final address = prefs.getString(PrefKeys.lastBleDeviceAddress) ?? '';
    final name = prefs.getString(PrefKeys.lastBleDeviceName) ?? '';
    if (address.isEmpty || state.lastDeviceAddress.isNotEmpty) return;
    emit(state.copyWith(
      lastDeviceAddress: address,
      lastDevice: name.isNotEmpty ? name : null,
    ));
  }

  /// Single choke-point for the server's last-reading watermark.
  ///
  /// Calls the `/last_timestamp` API (30s in-memory cache) and ALWAYS mirrors
  /// the result into local storage — so every API call persists, and no caller
  /// has to remember to save. Server is the single source of truth.
  ///
  /// Persists: `serverLastStampMs` (what the UI shows) + `serverCheckedAtMs`,
  /// and advances the push/sync delta cursor (`lastHrStamp`).
  ///
  /// Returns the server stamp (0 if no data or unreachable).
  Future<int> refreshServerWatermark() async {
    final res = await _fetchServerWatermark();
    if (!res.reached) return res.stamp; // offline/auth — leave local untouched

    final wm = await HistoryWatermarkStore.create();
    if (wm.isAnonymous) return res.stamp; // don't write under 'anon'

    if (res.stamp > 0) {
      final serverMs = res.stamp > 9999999999 ? res.stamp : res.stamp * 1000;
      await wm.commitServerWatermark(serverMs);
      // Server already has everything up to stamp → advance delta cursor.
      // NOTE: ms normalized stamp commit karo (raw seconds nahi) — push filter
      // aur baaki commit sites (_commitV3Watermark) watermark ko ms maante hain.
      await wm.commitHr(serverMs);
    } else {
      // Reached, but server has no data yet (new user) — record the reach so
      // the UI shows "No data on server yet" rather than "Never synced".
      await wm.commitServerReachedNow();
    }
    return res.stamp;
  }

  /// Exposes DB-backed sync metadata for the UI (last sync time, data range,
  /// total count) — used by the SyncStatusBanner.
  Future<HistorySyncMeta> get historyMeta => _historyRepo.getMeta();

  /// Clears all persisted history — the SQLite store and the in-memory lists.
  /// Called on logout so the next user (or the same device, logged out) never
  /// sees a previous account's health data.
  Future<void> clearPersistedHistory() async {
    await _historyRepo.clearAll();
    emit(state.copyWith(
      historyHrData: const [],
      historyRrData: const [],
      historySleep: const [],
    ));
  }

  /// Loads persisted history from SQLite so the UI shows last-known data
  /// before any live sync arrives.
  Future<void> _hydrateFromDb() async {
    final h = await _historyRepo.hydrate();
    if (isClosed || (h.hr.isEmpty && h.rr.isEmpty && h.sleep.isEmpty)) return;
    emit(state.copyWith(
      historyHrData: h.hr,
      historyRrData: h.rr,
      historySleep: h.sleep,
    ));
  }

  // ─── EventChannel listener ──────────────────────────────────────────────────
  void _listenToDeviceData() {
    _dataSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) async {
        if (event is! Map<dynamic, dynamic>) return;
        final map = event;
        final type = map['type'] as String?;
        if (type == null) return;
        final value = map['value'];

        // NOTE: Real-time device events (HR/PPG/RSSI har few ms) ko JAAN-BUJH KE
        // log/file me NAHI likhte — per-second flood app_log file ko bloat karta
        // tha aur perf hit deta tha. Sirf low-freq history dumps (_dumpHistory)
        // file me jaate hain.

        switch (type) {
          case "HEART_RATE":
            emit(state.copyWith(heartRate: _toInt(value)));
            break;

          case "BATTERY":
            emit(state.copyWith(battery: _toInt(value)));
            break;

          // PPG (optical) waveform samples — high-freq real-time data.
          // Per-event logging JAAN-BUJH KE band hai (per-second flood). Koi
          // state change nahi.
          case "PPG_DATA":
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
            _persistLastDevice(address: value);
            break;

          // Device name replayed by native on connect/reconnect AND on Dart
          // (re)subscribe — keeps state.lastDevice populated even when the
          // connection wasn't established via connectToDevice() this session
          // (auto-reconnect, app relaunch while already connected).
          case "LAST_DEVICE_NAME":
            emit(state.copyWith(lastDevice: value as String));
            _persistLastDevice(name: value);
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
            _resetSyncSafetyTimerIfSyncing();
            final hrRec = _toList(value);
            _dumpHistory('HISTORY_HR_RECORD', hrRec);
            emit(state.copyWith(historyHrRecord: hrRec));
            break;
          case "HISTORY_HR_RECORD_PREVIEW":
            // Read-only records preview — koi persist/timer/auto-push NAHI.
            final preview = _toList(value);
            _dumpHistory('HISTORY_HR_RECORD_PREVIEW', preview);
            emit(state.copyWith(previewHrRecords: preview));
            break;
          case "HISTORY_HR_DATA_PREVIEW":
            // Read-only single-record data preview — persist/push kuch NAHI.
            final previewData = _toList(value);
            _dumpHistory('HISTORY_HR_DATA_PREVIEW', previewData);
            emit(state.copyWith(previewHrRecordData: previewData));
            break;
          case "HEART_RATE_STATUS":
            // DIAGNOSTIC: band ki current auto-HR-monitoring config. debugPrint se
            // FileLogger/console dono me dikhega + state me store (UI pe dikhane ke liye).
            final m = value as Map<dynamic, dynamic>;
            final st = (m['status'] as num?)?.toInt() ?? -1;
            final iv = (m['interval'] as num?)?.toInt() ?? -1;
            final du = (m['duration'] as num?)?.toInt() ?? -1;
            debugPrint('[HR-STATUS] status=$st interval=$iv duration=$du '
                '(0=OFF/1=ON — OFF matlab band standalone HR log nahi karta)');
            emit(state.copyWith(
              hrMonitorStatus: st,
              hrMonitorInterval: iv,
              hrMonitorDuration: du,
            ));
            break;
          case "HISTORY_HR_DATA_CHUNK":
            _resetSyncSafetyTimerIfSyncing();
            final chunk = _toList(value);
            _dumpHistory('HR_CHUNK_DATA', chunk);
            await _historyRepo.persistHrChunk(chunk);
            if (isClosed) return;
            emit(state.copyWith(
              historyHrData: [...state.historyHrData, ...chunk],
            ));
            break;
          case "HISTORY_HR_DATA_DONE":
            _resetSyncSafetyTimerIfSyncing();
            _dumpHistory('HR_FULL_DATA', state.historyHrData);
            emit(state.copyWith(status: "HR sync complete"));
            break;
          case "HISTORY_RR_RECORD":
            _resetSyncSafetyTimerIfSyncing();
            final rrRec = _toList(value);
            _dumpHistory('HISTORY_RR_RECORD', rrRec);
            emit(state.copyWith(historyRrRecord: rrRec));
            break;
          case "HISTORY_RR_DATA":
            _resetSyncSafetyTimerIfSyncing();
            final rrData = _toList(value);
            _dumpHistory('HISTORY_RR_DATA', rrData);
            emit(state.copyWith(historyRrData: rrData));
            break;
          case "HISTORY_RR_DATA_CHUNK":
            _resetSyncSafetyTimerIfSyncing();
            final chunk = _toList(value);
            _dumpHistory('RR_CHUNK_DATA', chunk);
            await _historyRepo.persistRrChunk(chunk);
            if (isClosed) return;
            emit(state.copyWith(
              historyRrData: [...state.historyRrData, ...chunk],
            ));
            break;
          case "HISTORY_RR_DATA_DONE":
            _resetSyncSafetyTimerIfSyncing();
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
            _resetSyncSafetyTimerIfSyncing();
            final sleepList = _toList(value);
            _dumpHistory('HISTORY_SLEEP', sleepList);
            await _historyRepo.persistSleep(sleepList);
            if (isClosed) return;
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
            _historySyncing = true;
            emit(state.copyWith(
              status: "Syncing history…",
              historyHrData: const [],
              historyRrData: const [],
              historySleep: const [],
            ));
            // Safety timer arm karo. Ye ab fixed nahi — har naye data chunk pe
            // reset hota hai (neeche _resetSyncSafetyTimerIfSyncing dekho), isliye
            // bada transfer beech me nahi katega. Sirf tab fire hoga jab device
            // 60s tak kuch na bheje (stall/disconnect).
            _armSyncSafetyTimer();
            break;

          case "SYNC_COMPLETE":
            _syncDoneTimer?.cancel();
            _historySyncing = false;
            final hiveData = await _historyRepo.hydrate();
            if (isClosed) return;
            emit(state.copyWith(
              status: "Sync complete",
              historyHrData: hiveData.hr,
              historyRrData: hiveData.rr,
              historySleep: hiveData.sleep,
            ));
            await _historyRepo.updateAllMeta();
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
    // Ye "Connected" ek reconnect ka hissa hai kya? (pichhla state
    // "Reconnecting..." / "Link Lost" tha) — agar haan to auto-sync skip karenge…
    final wasReconnecting = state.isReconnecting;
    // …siwaay iske ki ye app-launch auto-reconnect ho (tab sync chalne do).
    final launchReconnect = _launchReconnectActive;
    final isDisconnected = s == "Disconnected";

    // Band jud gaya — app-open wala bounded reconnect ab band karo.
    if (s == "Connected") {
      _launchReconnectTimer?.cancel();
      _launchReconnectTimer = null;
      _launchReconnectActive = false; // launch reconnect resolve ho gaya
    }
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

    // Auto-sync tab chale jab: FRESH connect ho (!wasReconnecting) YA app-launch
    // auto-reconnect ho (launchReconnect). In-session link-loss/flap reconnect pe
    // NAHI — warna reconnect flap se baar-baar sync + /last_timestamp hammering.
    // Manual "Sync" button hamesha available hai.
    if (s == "Connected" &&
        !wasConnected &&
        (!wasReconnecting || launchReconnect)) {
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

  // ─── Reconnect by saved address ─────────────────────────────────────────────
  /// Attempts to reconnect to the last connected device using its saved
  /// MAC address (Android) or a quick scan (iOS). No prior scan needed.
  /// Returns true if attempt was initiated, false if already connected or
  /// no saved address available.
  /// Pure decision: reconnect tab hi karo jab pehle se connected na ho AUR
  /// koi saved device address mojood ho. Side-effects se alag rakha hai taaki
  /// bina device/Hive ke unit-test ho sake.
  @visibleForTesting
  static bool shouldReconnect({
    required bool isConnected,
    required String lastDeviceAddress,
  }) {
    if (isConnected) return false;
    if (lastDeviceAddress.isEmpty) return false;
    return true;
  }

  /// App open hone par last-connected band se bounded auto-reconnect.
  ///
  /// Sirf idle case ke liye — koi activity session active nahi. (Session
  /// recovery ka apna aggressive 30s loop athlete cubit me hai; ye usse
  /// takraana nahi chahiye.) Sirf tab chalta hai jab:
  ///   • abhi connected nahi, aur
  ///   • prefs me ek saved device hai (user ne pehle connect kiya tha aur
  ///     explicitly disconnect nahi kiya — disconnect() keys clear kar deta hai)
  ///
  /// Bounded hai (max 3 attempts × 20s) taaki band genuinely door/off hone par
  /// battery na jale. Band aa jaaye to timer turant cancel ho jaata hai
  /// (_handleStatus me, Connected pe).
  Future<void> attemptLaunchReconnect() async {
    if (isClosed || state.isConnected) return;
    // Session active hai to uska apna recovery reconnect loop chal raha hai —
    // do loops takraaein na, isliye yahan skip.
    if (_sessionActive) return;

    // Address prefs se pakka karo — cubit init ki async hydration abhi adhoori
    // ho sakti hai, is race se bachne ke liye seedha prefs padho.
    final prefs = await SharedPreferences.getInstance();
    if (isClosed || state.isConnected) return;
    final address = prefs.getString(PrefKeys.lastBleDeviceAddress) ?? '';
    if (address.isEmpty) return; // kabhi connect nahi kiya / user ne disconnect kiya

    // BT band hai to reconnect ki koshish hi mat karo — warna native andar
    // baar-baar fail hota rehta hai. Flag surface karo taaki UI "Bluetooth off"
    // dikhaye; user BT on karke dobara try kar sakta hai.
    if (!await _isBluetoothOn()) {
      if (isClosed) return;
      debugPrint('[BLE] launch auto-reconnect skipped — Bluetooth is off');
      emit(state.copyWith(
        status: 'BLUETOOTH_OFF',
        isBluetoothOff: true,
        isReconnecting: false,
      ));
      return;
    }

    if (state.lastDeviceAddress.isEmpty) {
      final name = prefs.getString(PrefKeys.lastBleDeviceName) ?? '';
      emit(state.copyWith(
        lastDeviceAddress: address,
        lastDevice: name.isNotEmpty ? name : null,
      ));
    }

    // Pehle se koi launch-reconnect chal raha ho to dobara mat chalao.
    if (_launchReconnectTimer != null) return;

    debugPrint('[BLE] launch auto-reconnect — saved device mila, connecting…');
    _launchReconnectAttempt = 0;
    _launchReconnectActive = true; // ye reconnect launch-driven hai
    emit(state.copyWith(isReconnecting: true));
    _tryLaunchReconnect();

    _launchReconnectTimer = Timer.periodic(_launchReconnectInterval, (t) {
      if (isClosed ||
          state.isConnected ||
          _launchReconnectAttempt >= _maxLaunchReconnectAttempts) {
        _cancelLaunchReconnect();
        return;
      }
      _tryLaunchReconnect();
    });
  }

  void _tryLaunchReconnect() {
    _launchReconnectAttempt++;
    debugPrint(
        '[BLE] launch auto-reconnect attempt $_launchReconnectAttempt/$_maxLaunchReconnectAttempts');
    reconnectLastDevice();
  }

  void _cancelLaunchReconnect() {
    _launchReconnectTimer?.cancel();
    _launchReconnectTimer = null;
    _launchReconnectActive = false; // launch reconnect khatam (connect nahi hua)
    // Attempts khatam par connect nahi hua — spinner stuck mat chhodo.
    if (!isClosed && !state.isConnected && state.isReconnecting) {
      emit(state.copyWith(isReconnecting: false));
    }
  }

  Future<bool> reconnectLastDevice() async {
    if (!shouldReconnect(
      isConnected: state.isConnected,
      lastDeviceAddress: state.lastDeviceAddress,
    )) {
      return false;
    }
    // BT off ho to attempt hi mat karo (session-recovery / periodic loop dono
    // yahin se gujarte hain, isliye ek hi jagah check kaafi hai).
    if (!await _isBluetoothOn()) {
      if (!isClosed) emit(state.copyWith(isBluetoothOff: true));
      return false;
    }
    final address = state.lastDeviceAddress;
    try {
      await _methodChannel.invokeMethod('reconnectByAddress', {
        'address': address,
      });
      return true;
    } on PlatformException catch (e) {
      // Native ne BT-off pakda (Flutter check aur invoke ke beech race) —
      // flag surface karo.
      if (e.code == 'BLUETOOTH_OFF' && !isClosed) {
        emit(state.copyWith(isBluetoothOff: true));
      }
      debugPrint('[BLE] reconnectLastDevice failed: ${e.message}');
      return false;
    }
  }

  /// Native se poochho BT adapter ON hai ya nahi — koi side-effect nahi
  /// (settings popup nahi). Silent auto-reconnect isse guard karta hai.
  /// Error / purana build (method missing) pe `true` (false-block se bacho —
  /// warna reconnect kabhi na chale).
  Future<bool> _isBluetoothOn() async {
    try {
      final on = await _methodChannel.invokeMethod<bool>('isBluetoothOn');
      return on ?? true;
    } catch (_) {
      return true;
    }
  }

  // Last-connected device ko prefs me likho (cold-launch reconnect ke liye).
  // Fire-and-forget — BLE event handler ko block nahi karna.
  Future<void> _persistLastDevice({String? address, String? name}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (address != null && address.isNotEmpty) {
        await prefs.setString(PrefKeys.lastBleDeviceAddress, address);
      }
      if (name != null && name.isNotEmpty) {
        await prefs.setString(PrefKeys.lastBleDeviceName, name);
      }
    } catch (_) {}
  }

  // ─── Disconnect ─────────────────────────────────────────────────────────────
  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod('disconnect');
      emit(state.copyWith(
        isReconnecting: false,
        lastDeviceAddress: "",
      ));
      // User ne explicitly disconnect kiya — saved device bhi bhool jao,
      // warna agla cold launch chupchaap wapas connect kar dega.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefKeys.lastBleDeviceAddress);
      await prefs.remove(PrefKeys.lastBleDeviceName);
    } on PlatformException catch (e) {
      emit(state.copyWith(status: "Disconnect Error: ${e.message}"));
    }
  }

  // ─── Device power / reset commands ─────────────────────────────────────────
  /// Powers OFF the connected band. The device disconnects on its own; the
  /// normal disconnect flow updates connection state. Returns true if the
  /// command was accepted by the native side.
  Future<bool> shutdownDevice() async {
    try {
      await _methodChannel.invokeMethod('shutdownDevice');
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'NOT_CONNECTED') {
        emit(state.copyWith(status: "Not connected — connect a device first"));
      } else {
        emit(state.copyWith(status: "Shutdown failed: ${e.message}"));
      }
      return false;
    }
  }

  /// Factory-resets the connected band. ERASES all settings + history on the
  /// device. Returns true if the command was accepted by the native side.
  Future<bool> restoreDevice() async {
    try {
      await _methodChannel.invokeMethod('restoreDevice');
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'NOT_CONNECTED') {
        emit(state.copyWith(status: "Not connected — connect a device first"));
      } else {
        emit(state.copyWith(status: "Factory reset failed: ${e.message}"));
      }
      return false;
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
  /// DIAGNOSTIC: band ki auto-HR-monitoring config SET karo. status 1=ON/0=OFF.
  /// Reply (agar aaye) HEART_RATE_STATUS event me → state update ho jaayega.
  Future<void> setHeartRateStatus({
    int status = 1,
    int interval = 1,
    int duration = 1,
  }) async {
    try {
      await _methodChannel.invokeMethod('setHeartRateStatus', {
        'status': status,
        'interval': interval,
        'duration': duration,
      });
    } on PlatformException catch (e) {
      debugPrint('[HR-STATUS] set failed: ${e.message}');
    }
  }

  /// DIAGNOSTIC: band se current auto-HR-monitoring config maango. Result
  /// `[HR-STATUS]` log me aata hai (native logcat + FileLogger/console). On-connect
  /// auto bhi chalta hai; ye manual re-check ke liye hai.
  Future<void> getHeartRateStatus() async {
    try {
      await _methodChannel.invokeMethod('getHeartRateStatus');
    } on PlatformException catch (e) {
      debugPrint('[HR-STATUS] request failed: ${e.message}');
    }
  }

  /// READ-ONLY records preview. Fetches ONLY the HR record headers (see
  /// [HistoryRecordsScreen]) — no per-record data, no SQLite persist, no server
  /// push. Result lands in `state.previewHrRecords`.
  Future<void> previewHrRecords() async {
    try {
      await _methodChannel.invokeMethod('previewHrRecords');
    } on PlatformException catch (e) {
      if (e.code == 'NOT_CONNECTED') {
        emit(state.copyWith(status: "Not connected — connect a device first"));
      } else {
        emit(state.copyWith(status: "Records preview failed: ${e.message}"));
      }
    }
  }

  /// READ-ONLY single-record data preview. Fetches ONE record's readings by its
  /// session-start [stamp] into `state.previewHrRecordData`. Clears the previous
  /// preview first so the detail screen never shows stale data. No persist/push.
  Future<void> previewHrRecordData(int stamp) async {
    emit(state.copyWith(previewHrRecordData: const []));
    try {
      await _methodChannel
          .invokeMethod('previewHrRecordData', {'stamp': stamp});
    } on PlatformException catch (e) {
      if (e.code == 'NOT_CONNECTED') {
        emit(state.copyWith(status: "Not connected — connect a device first"));
      } else {
        emit(state.copyWith(status: "Record data preview failed: ${e.message}"));
      }
    }
  }

  Future<void> syncNewFromDevice() async {
    if (_sessionActive) {
      debugPrint('[BLE] syncNewFromDevice skipped — activity session active');
      return;
    }
    try {
      // Server watermark refresh — UI ke "last reached" display ke liye. Fetch
      // ki range ab watermark se NAHI, balki aaj ki shुरुआत (local midnight) se
      // leke abhi tak. Isse din bhar ka poora data (late-commit / split records
      // bhi) dobara device se aata hai aur watermark-se-neeche wale gaps — jo
      // pehle permanently miss ho jaate the — bhar jaate hain. Server timestamp
      // pe dedup karta hai, isliye dobara aana safe hai.
      await refreshServerWatermark();
      final now = DateTime.now();
      final toMs = now.millisecondsSinceEpoch;
      final fromMs =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
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

  // ─── History sync safety timer ─────────────────────────────────────────────
  // Pehle ye ek fixed 30s timer tha jo HISTORY_SYNC_START pe lagta tha aur 30s
  // baad zabardasti sync ko "complete" maar deta tha — chahe data abhi aa raha
  // ho. Bade session ka transfer 30s se zyada leta tha to beech me hi kat jata
  // tha (adhura data → 0 readings). Ab ye idle timer hai: har naye history data
  // chunk pe reset hota hai, sirf tab fire karega jab device 60s tak kuch na
  // bheje (genuine stall/disconnect).
  static const _syncIdleTimeout = Duration(seconds: 60);

  void _armSyncSafetyTimer() {
    _syncDoneTimer?.cancel();
    _syncDoneTimer = Timer(_syncIdleTimeout, () async {
      if (!isClosed && _historySyncing) {
        debugPrint('[BLE-HISTORY] ⏱ sync safety timer expired — marking complete');
        _historySyncing = false;
        final h = await _historyRepo.hydrate();
        if (isClosed) return;
        emit(state.copyWith(
          status: "Sync complete",
          historyHrData: h.hr,
          historyRrData: h.rr,
          historySleep: h.sleep,
        ));
        await _historyRepo.updateAllMeta();
        _commitSyncCompleted();
        // SYNC_COMPLETE path jaisa hi — agar ye ek device-only range fetch tha
        // (session upload / syncHistoryRange ne _skipNextAutoPush set kiya),
        // to history auto-push (V3-PUSH) mat chalao. Pehle ye check yahan nahi
        // tha, isliye safety-timer se finalize hone par session upload ke saath
        // ek extra health_metrics push bhi chal jata tha.
        if (_skipNextAutoPush) {
          _skipNextAutoPush = false;
        } else {
          _scheduleAutoPush();
        }
      }
    });
  }

  /// History data aate waqt safety timer ko reset karta hai taaki active
  /// transfer beech me na kate. Sirf sync chalu hone par effect karta hai.
  void _resetSyncSafetyTimerIfSyncing() {
    if (_historySyncing) _armSyncSafetyTimer();
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
    _autoPushTimer = Timer(const Duration(milliseconds: 500), () {
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
  ///
  /// Result 30s tak cache hota hai — SUCCESS, EMPTY aur ERROR teeno outcomes ke
  /// liye. Pehle sirf success-with-data cache hota tha, isliye jab server error
  /// deta tha (ya empty tha) to koi throttle nahi tha: har trigger (auto-sync
  /// on har BLE reconnect, history tab open, etc.) `/last_timestamp` ko dobara
  /// hit karta tha — aur api_service upar se 1 retry (60s timeout) bhi lagata,
  /// jisse error par API "continuously chalti" dikhti thi. Ab kisi bhi outcome
  /// ke baad 30s tak network hit nahi hoga.
  ({int stamp, bool reached})? _watermarkCache;
  int _watermarkFetchedAtMs = 0;
  static const int _watermarkCacheTtlMs = 30 * 1000; // 30 seconds

  /// [reached] = server was successfully contacted (HTTP ok + success),
  /// regardless of whether it actually has data. Lets a new user (server
  /// reachable but empty) be told "No data on server yet" instead of the
  /// alarming "Never synced" (which means we couldn't reach the server).
  Future<({int stamp, bool reached})> _fetchServerWatermark() async {
    // Recent result (kisi bhi outcome ka) 30s tak reuse karo — error/empty pe
    // bhi. Isse repeated triggers network ko hammer nahi karte.
    final now = DateTime.now().millisecondsSinceEpoch;
    final cached = _watermarkCache;
    if (cached != null && (now - _watermarkFetchedAtMs) < _watermarkCacheTtlMs) {
      return cached;
    }

    ({int stamp, bool reached}) result;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(PrefKeys.userToken) ?? '';
      if (token.isEmpty) {
        // Token nahi — cache mat karo (login ke turant baad valid ho sakta hai).
        return (stamp: 0, reached: false);
      }
      ApiService.instance.setAuthToken(token);
      final response = await ApiService.instance.dio.get(
        '/athlete/health_metrics/last_timestamp',
      );
      final data = response.data as Map<String, dynamic>? ?? {};
      if (data['success'] == true) {
        final inner = data['data'] as Map<String, dynamic>? ?? {};
        final stamp = (inner['recorded_at'] as num?)?.toInt() ?? 0;
        result = (stamp: stamp, reached: true); // reached, even if empty
      } else {
        result = (stamp: 0, reached: false);
      }
    } on DioException {
      result = (stamp: 0, reached: false);
    } catch (_) {
      result = (stamp: 0, reached: false);
    }

    // Har mukammal attempt (success/empty/error) ko cache karo → 30s throttle.
    _watermarkCache = result;
    _watermarkFetchedAtMs = now;
    return result;
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

      int stampMs(int s) => s > 9999999999 ? s : s * 1000;
      // Day-scoped push: watermark ke bajaye aaj ki shुरुआत (local midnight) se
      // filter karo. Server timestamp pe dedup karta hai, isliye already-saved
      // readings dobara bhejna safe hai — aur watermark-se-neeche wale
      // late/backfilled gaps is baar bhar jaate hain (jo pehle permanently miss
      // ho jaate the). Watermark ab sirf UI ke "last reached" display ke liye.
      final now = DateTime.now();
      final startOfDayMs =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      final hive = await _historyRepo.hydrate();

      final hrFiltered = hive.hr.where((r) {
        final s = (r['stamp'] as num?)?.toInt() ?? 0;
        if (s <= 0) return false;
        return stampMs(s) >= startOfDayMs;
      }).toList();

      final rrFiltered = hive.rr.where((r) {
        final s = (r['stamp'] as num?)?.toInt() ?? 0;
        if (s <= 0) return false;
        return stampMs(s) >= startOfDayMs;
      }).toList();

      final sleepFiltered = hive.sleep.where((r) {
        final u = (r['utc'] as num?)?.toInt() ?? 0;
        if (u <= 0) return false;
        return stampMs(u) >= startOfDayMs;
      }).toList();

      if (hrFiltered.isEmpty &&
          rrFiltered.isEmpty &&
          sleepFiltered.isEmpty) {
        // debugPrint('[HISTORY-PUSH] nothing new to push (all under watermark)');
        _emitPushEvent(const PushNothingNew());
        _cleanupPush();
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
      // 1. JSON encode → gzip compress — background isolate me (bade history
      // payloads pe main thread block na ho).
      final compressed = await gzipPayloadInIsolate(payload);
      final gzipBytes = compressed.gzipBytes;
      final jsonLength = compressed.jsonLength;
      debugPrint('[V3-PUSH] JSON size: $jsonLength bytes → Gzip size: ${gzipBytes.length} bytes (${(gzipBytes.length * 100 / jsonLength).toStringAsFixed(1)}% ratio)');

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

      final int statusCodeRaw;
      final String reasonPhrase;
      final String responseBody;
      final HttpHeaders responseHeaders;
      try {
        final request = await httpClient.postUrl(uri);
        request.headers.set('Authorization', 'Bearer $token');
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Content-Encoding', 'gzip');
        request.headers.contentLength = gzipBytes.length;
        request.add(gzipBytes);

        final httpResponse = await request.close();
        responseBody = await httpResponse.transform(utf8.decoder).join();
        statusCodeRaw = httpResponse.statusCode;
        reasonPhrase = httpResponse.reasonPhrase;
        responseHeaders = httpResponse.headers;
      } finally {
        // Exception ho ya na ho — client hamesha close, warna socket leak.
        httpClient.close();
      }

      stopwatch.stop();

      debugPrint('[V3-PUSH] ───────────────────────────────────────────');
      debugPrint('[V3-PUSH] Status: $statusCodeRaw $reasonPhrase');
      debugPrint('[V3-PUSH] Time: ${stopwatch.elapsedMilliseconds} ms');
      debugPrint('[V3-PUSH] Response headers:');
      responseHeaders.forEach((name, values) {
        debugPrint('[V3-PUSH]   $name: ${values.join(', ')}');
      });
      debugPrint('[V3-PUSH] Body: $responseBody');
      debugPrint('[V3-PUSH] ═══════════════════════════════════════════');

      final responseData = jsonDecode(responseBody) as Map<String, dynamic>? ?? {};
      final data = responseData['data'] as Map<String, dynamic>? ?? {};
      final statusCode = statusCodeRaw;

      // Auth check
      if (statusCode == 401 || statusCode == 403) {
        // Raw HttpClient Dio interceptor bypass karta hai — global logout flow
        // manually trigger karo (token clear + re-login route).
        ApiService.instance.notifyTokenExpired();
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
      _watermarkCache = null;
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
      final pollResult = await _pollJobStatus(jobId, token);

      // 5. Clear polling state regardless of result
      await _clearPollingState();
      if (isClosed) return;
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
  Future<Map<String, dynamic>?> _pollJobStatus(String jobId, String token) async {
    const maxAttempts = 60; // 60 seconds max
    int consecutiveErrors = 0;
    const maxConsecutiveErrors = 5;

    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 1));
      try {
        // Auth header explicitly bhejo — relaunch/resume pe global Dio token set
        // na ho to poll "No token provided" (401) de deta tha.
        final response = await ApiService.instance.dio.get(
          '/athlete/ingestion/job/$jobId',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
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
    final token = prefs.getString(PrefKeys.userToken) ?? '';
    if (jobId.isEmpty || startedAt <= 0 || token.isEmpty) {
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
    if (isClosed) return;
    emit(state.copyWith(
      isPolling: true,
      pollingJobId: jobId,
      pollingMessage: 'Resuming server processing…',
    ));
    _emitPushEvent(PushPolling(jobId));

    final pollResult = await _pollJobStatus(jobId, token);
    await _clearPollingState();
    // Poll 60s tak chal sakti hai — tab tak cubit close ho sakta hai
    // (logout/screen dispose). emit-after-close StateError se bachne ke
    // liye guard. _emitPushEvent khud isClosed check karta hai.
    if (isClosed) return;
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
    _watermarkCache = null;
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
    if (data.isEmpty) return;
    // Sync se aane wala poora history data log file me (count + pretty JSON).
    FileLogger.instance.log(
      '$tag — count=${data.length}  data:\n${prettyJson(data)}',
      tag: 'BLE-HISTORY',
    );
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
    _launchReconnectTimer?.cancel();
    _dataSubscription?.cancel();
    _pushEvents.close();
    return super.close();
  }
}
