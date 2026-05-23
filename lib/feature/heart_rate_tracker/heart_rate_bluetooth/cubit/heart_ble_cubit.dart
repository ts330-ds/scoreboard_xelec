import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history/data/repository/history_repository.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/push_status_event.dart';
import 'package:xelex_esp/service/socket/athlete_health_monitor_socket_service.dart';
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
  // force:true to bypass. 2h chosen so a morning device-connect always
  // captures previous night's data.
  static const Duration _syncCooldown = Duration(hours: 2);

  // Don't hammer the server — successful pushes are throttled to once per hour.
  // Auto-push (after full sync) and the manual "Push to Server Now" button
  // both respect this gate. Use `force: true` to bypass programmatically.
  static const Duration _pushCooldown = Duration(hours: 1);

  StreamSubscription? _dataSubscription;
  Timer? _scanTimeout;
  Timer? _syncDoneTimer;
  Timer? _autoPushTimer;
  Timer? _pushTimeoutTimer;

  // History push state — ack-based watermark commit.
  // Pending maxes are precomputed at send time; on `health_metric_saved`
  // callback se SharedPreferences me commit hote hain.
  bool _pushingHistory = false;
  int? _pendingHrMax;
  int? _pendingRrMax;
  int? _pendingSleepMax;

  // On-demand socket — sirf push ke time connect, ack ke baad disconnect.
  // BG isolate / foreground service ki zaroorat nahi (24/7 health monitoring removed).
  AthleteHealthMonitorSocketService? _healthSocket;
  Map<String, dynamic>? _pendingPayload;

  final GlobalErrorCubit errorCubit;

  final HistoryRepository _historyRepo = HistoryRepository.instance;

  // Set true before a user-initiated range sync so the post-sync auto-push
  // is skipped — range fetches are exploration, not server commits.
  bool _skipNextAutoPush = false;

  HeartBleCubit({required this.errorCubit}) : super(const HeartBleState()) {
    _hydrateFromDb();
    _listenToDeviceData();
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

  // ─── EventChannel listener ──────────────────────────────────────────────────
  void _listenToDeviceData() {
    _dataSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        final map = event as Map<dynamic, dynamic>;
        final type = map['type'] as String;
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
            // Persist + dedupe via Hive (stamp key), then rebuild in-memory
            // list from the store so duplicates can never accumulate.
            _historyRepo.persistHrChunk(chunk).then((_) {
              emit(state.copyWith(
                historyHrData: _historyRepo.hydrate().hr,
              ));
            });
            break;
          case "HISTORY_HR_DATA_DONE":
            _dumpHistory('HR_FULL_DATA', state.historyHrData);
            _syncDoneTimer?.cancel();
            emit(state.copyWith(status: "Sync complete"));
            _commitSyncCompleted();
            // Skip auto-push for user-initiated range fetches — they're
            // exploration, not server commits. Push happens via auto-push
            // after `syncAllHistory` or via the "Push to Server Now" button.
            if (_skipNextAutoPush) {
              _skipNextAutoPush = false;
            } else {
              _scheduleAutoPush();
            }
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
            _historyRepo.persistRrChunk(chunk).then((_) {
              emit(state.copyWith(
                historyRrData: _historyRepo.hydrate().rr,
              ));
            });
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
            _historyRepo.persistSleep(sleepList).then((_) {
              emit(state.copyWith(
                historySleep: _historyRepo.hydrate().sleep,
              ));
            });
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
            // DB-first: persisted data stays visible. Incoming chunks merge
            // via Hive (stamp-keyed) so duplicates are impossible. We only
            // reset volatile record-headers, not the actual data lists.
            emit(state.copyWith(
              status: "Syncing history…",
              historyRrRecord: const [],
            ));
            // 40 s covers HR chain (up to 30 s) + 3 s sleep delay + buffer
            _syncDoneTimer?.cancel();
            _syncDoneTimer = Timer(const Duration(seconds: 40), () {
              if (!isClosed && state.status.contains('yncing')) {
                // debugPrint('[BLE-HISTORY] ⏱ sync timer expired — marking complete');
                emit(state.copyWith(status: "Sync complete"));
                _commitSyncCompleted();
                _scheduleAutoPush();
              }
            });
            break;

          default:
            //debugPrint('[BLE] ⚠ UNHANDLED type=$type  value=$value');
            break;
        }
      },
      onError: (dynamic error) {
        //debugPrint('[BLE] ✖ Stream error: $error');
        emit(state.copyWith(status: "Stream Error: $error"));
      },
    );
  }

  // ─── Private Handlers ──────────────────────────────────────────────────────
  void _handleStatus(String s) {
    final wasConnected = state.isConnected;
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
      rrBuffer: isDisconnected ? const [] : null,
      hrv: isDisconnected ? 0.0 : null,
    ));

    // BLE connect hote hi check karo — agar 2h+ se sync nahi hua, auto sync
    // trigger karo. Sync complete pe push automatically chal jaayega.
    if (s == "Connected" && !wasConnected) {
      _maybeAutoSyncOnConnect();
    }
  }

  Future<void> _maybeAutoSyncOnConnect() async {
    // Small delay — device info exchange + handshake settle hone do
    await Future.delayed(const Duration(seconds: 2));
    if (isClosed || !state.isConnected) return;
    // debugPrint('[BLE] auto-sync check on BLE connect');
    syncAllHistory(); // force:false → cooldown gate apply
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
  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      final permissions = [Permission.bluetoothScan, Permission.bluetoothConnect];
      if (info.version.sdkInt < 31) permissions.add(Permission.location);
      if (info.version.sdkInt >= 33) permissions.add(Permission.notification);
      await permissions.request();
    }
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
  ///
  /// [force]: bypass the 2h cooldown gate. Use `true` for manual sync button
  /// taps; auto-triggers (tab open, BLE reconnect) should leave it `false`.
  Future<void> syncAllHistory({bool force = false}) async {
    if (!force) {
      final wm = await HistoryWatermarkStore.create();
      final lastSync = wm.lastSyncAt;
      if (lastSync.millisecondsSinceEpoch > 0) {
        final elapsed = DateTime.now().difference(lastSync);
        if (elapsed < _syncCooldown) {
          // final mins = _syncCooldown.inMinutes - elapsed.inMinutes;
          // debugPrint(
              // '[BLE] sync skipped — cooldown active (${mins}m remaining). Use force:true to override');
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
    _autoPushTimer?.cancel();
    _autoPushTimer = Timer(const Duration(seconds: 2), () {
      if (!isClosed) pushHistoryBatch();
    });
  }

  /// Filter sync'd history against per-athlete watermarks and emit a
  /// batched payload via the bg health socket. Idempotent — duplicate
  /// records are filtered out before send; watermark commits on backend ack.
  ///
  /// [force]: bypass the 1-hour push cooldown gate. Auto-push (after a full
  /// sync) and the manual "Push to Server Now" button both pass `false`;
  /// they wait for the cooldown to elapse.
  Future<void> pushHistoryBatch({bool force = false}) async {
    if (_pushingHistory) {
      _emitPushEvent(const PushAlreadyInFlight());
      return;
    }
    _pushingHistory = true;
    _emitPushEvent(const PushPreparing());
    try {
      final wm = await HistoryWatermarkStore.create();
      // Guard: no logged-in user → don't attribute readings to 'anon' or
      // (worse) leak them onto whoever logs in next on this device.
      if (wm.isAnonymous) {
        _emitPushEvent(const PushAnonymous());
        _cleanupPush();
        return;
      }

      // ─── 1-hour push cooldown ─────────────────────────────────────────
      // Skip if a successful push happened within the window — backend
      // doesn't need every-sync chatter. Manual button gets the same
      // throttle (pass force: true to override).
      if (!force && wm.lastPushAtMs > 0) {
        final elapsed = DateTime.now().difference(wm.lastPushAt);
        if (elapsed < _pushCooldown) {
          final remainingMin =
              _pushCooldown.inMinutes - elapsed.inMinutes;
          _emitPushEvent(PushCooldownActive(remainingMin.clamp(1, 60)));
          _cleanupPush();
          return;
        }
      }

      final hrFiltered = state.historyHrData.where((r) {
        final s = (r['stamp'] as num?)?.toInt() ?? 0;
        return s > wm.lastHrStamp;
      }).toList();

      final rrFiltered = state.historyRrData.where((r) {
        final s = (r['stamp'] as num?)?.toInt() ?? 0;
        return s > wm.lastRrStamp;
      }).toList();

      final sleepFiltered = state.historySleep.where((r) {
        final u = (r['utc'] as num?)?.toInt() ?? 0;
        return u > wm.lastSleepUtc;
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

      // Pending maxes — commit on ack
      _pendingHrMax = hrFiltered.isEmpty
          ? null
          : hrFiltered
              .map((r) => (r['stamp'] as num?)?.toInt() ?? 0)
              .reduce((a, b) => a > b ? a : b);
      _pendingRrMax = rrFiltered.isEmpty
          ? null
          : rrFiltered
              .map((r) => (r['stamp'] as num?)?.toInt() ?? 0)
              .reduce((a, b) => a > b ? a : b);
      _pendingSleepMax = sleepFiltered.isEmpty
          ? null
          : sleepFiltered
              .map((r) => (r['utc'] as num?)?.toInt() ?? 0)
              .reduce((a, b) => a > b ? a : b);

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
      await _connectAndPush();
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

  // Token + base URL fetch karke socket connect karo. onMonitoringStarted
  // callback fire hone pe payload submit hoga.
  Future<void> _connectAndPush() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(PrefKeys.userToken) ?? '';
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    if (token.isEmpty || baseUrl.isEmpty) {
      // debugPrint('[HISTORY-PUSH] missing token/baseUrl — abort');
      _emitPushEvent(const PushMissingAuth());
      _cleanupPush();
      return;
    }

    // Naya socket instance — purane callbacks/state contamination avoid karne ke liye
    _healthSocket?.disconnect();
    final socket = AthleteHealthMonitorSocketService();
    _healthSocket = socket;

    socket.onMonitoringStarted = () {
      // Backend ne device_connected accept kar liya — ab batch bhej do
      final payload = _pendingPayload;
      if (payload == null) return;
      // debugPrint('[HISTORY-PUSH] socket ready — submitting batch');
      _emitPushEvent(PushUploading(
        hrCount: _pendingHrCount,
        rrCount: _pendingRrCount,
        sleepCount: _pendingSleepCount,
      ));
      socket.submitHistoryBatch(payload);
    };

    socket.onMetricSaved = (data) async {
      // debugPrint('[HISTORY-PUSH] ✅ ack: $data');
      _emitPushEvent(PushSucceeded(data));
      await _commitPendingWatermarks();
      _disconnectSocket();
    };

    socket.onError = (msg) {
      // debugPrint('[HISTORY-PUSH] socket error: $msg');
      _emitPushEvent(PushFailed(msg.toString()));
      _cleanupPush();
      _disconnectSocket();
    };

    socket.onSocketDisconnected = () {
      // Ack ke baad humne khud disconnect kiya — pending pehle hi clear ho gaya.
      // Agar pending abhi tak set hai → unexpected disconnect mid-flow.
      if (_pendingPayload != null) {
        // debugPrint('[HISTORY-PUSH] unexpected disconnect — discarding pending');
        _emitPushEvent(const PushDisconnected());
        _cleanupPush();
      }
    };

    socket.onAuthFailure = (msg) {
      // debugPrint('[HISTORY-PUSH] auth failure: $msg');
      _emitPushEvent(PushAuthFailed(msg.toString()));
      _cleanupPush();
      _disconnectSocket();
    };

    // 20s timeout — agar ack/error nahi aaya, cleanup
    _pushTimeoutTimer?.cancel();
    _pushTimeoutTimer = Timer(const Duration(seconds: 20), () {
      if (_pendingPayload != null) {
        // debugPrint('[HISTORY-PUSH] ⏱ timeout — disconnecting');
        _emitPushEvent(const PushTimedOut());
        _cleanupPush();
        _disconnectSocket();
      }
    });

    _emitPushEvent(const PushConnecting());
    socket.connect(baseUrl, token);
  }

  Future<void> _commitPendingWatermarks() async {
    if (_pendingHrMax == null &&
        _pendingRrMax == null &&
        _pendingSleepMax == null) {
      return;
    }
    try {
      final wm = await HistoryWatermarkStore.create();
      if (_pendingHrMax != null) await wm.commitHr(_pendingHrMax!);
      if (_pendingRrMax != null) await wm.commitRr(_pendingRrMax!);
      if (_pendingSleepMax != null) await wm.commitSleep(_pendingSleepMax!);
      // Mark "last push at now" — drives the 1h cooldown gate on next call.
      await wm.commitPushAtNow();
    } catch (e) {
      // debugPrint('[HISTORY-PUSH] watermark commit failed: $e');
    } finally {
      _pendingHrMax = null;
      _pendingRrMax = null;
      _pendingSleepMax = null;
    }
  }

  void _cleanupPush() {
    _pushTimeoutTimer?.cancel();
    _pushTimeoutTimer = null;
    _pendingPayload = null;
    _pendingHrMax = null;
    _pendingRrMax = null;
    _pendingSleepMax = null;
    _pushingHistory = false;
  }

  void _disconnectSocket() {
    final s = _healthSocket;
    _healthSocket = null;
    if (s != null && s.isConnected) {
      s.disconnect();
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  // Device history data ko console pe dump karta hai. Android logcat ki
  // per-line ~1000 char limit hoti hai — isliye 800 char chunks me todte hain.
  void _dumpHistory(String tag, List<dynamic> data) {
    // debugPrint('[BLE-HISTORY] $tag — count=${data.length}');
    if (data.isEmpty) return;
    final str = data.toString();
    const chunkSize = 800;
    if (str.length <= chunkSize) {
      // debugPrint('[BLE-HISTORY] $tag → $str');
      return;
    }
    final total = (str.length / chunkSize).ceil();
    for (var i = 0; i < total; i++) {
      // final start = i * chunkSize;
      // final end = (start + chunkSize) < str.length ? start + chunkSize : str.length;
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
      (v as List).cast<Map<dynamic, dynamic>>();

  @override
  Future<void> close() {
    _scanTimeout?.cancel();
    _syncDoneTimer?.cancel();
    _autoPushTimer?.cancel();
    _pushTimeoutTimer?.cancel();
    _dataSubscription?.cancel();
    _disconnectSocket();
    _pushEvents.close();
    return super.close();
  }
}
