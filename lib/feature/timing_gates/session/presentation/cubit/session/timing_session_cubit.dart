import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:xelex_esp/error/cubit/error_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/data/ble_result_parser.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/data/timing_gate_ble_service.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/test_session_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/trial_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/repository/session_repository.dart';
import 'timing_session_state.dart';

class TimingSessionCubit extends Cubit<TimingSessionState> {
  final GlobalErrorCubit errorCubit;
  final SessionRepository sessionRepository;
  final TimingGateBleService bleService;

  final _parser = BleResultParser();
  static const _uuid = Uuid();
  StreamSubscription<String>? _bleSub;


  TimingSessionCubit({
    required this.errorCubit,
    required this.sessionRepository,
    required this.bleService,
  }) : super(const TimingSessionState()) {
    _parser.onResult = _onParsedResult;
    _parser.onEvent = _onBleEvent;
    _bleSub = bleService.lineStream.listen(feedBleData);
  }

  // ── Wizard navigation ──────────────────────────────────────────────────────

  void nextStep() {
    if (state.currentStep == 0) {
      if (state.mode.isEmpty) {
        errorCubit.showWarning('Select a test mode to continue.');
        return;
      }
      if (state.mode == 'linear') {
        if (state.subMode.isEmpty) {
          errorCubit.showWarning('Select a test type (Sprint, 505, or T-Test).');
          return;
        }
        if (state.subMode == 'sprint') {
          if (state.protocol.isEmpty) {
            errorCubit.showWarning('Select a distance.');
            return;
          }
          if (state.protocol == 'custom' &&
              (state.customDistance == null || state.customDistance! <= 0)) {
            errorCubit.showWarning('Enter a valid custom distance.');
            return;
          }
        }
      }
    }

    // Athletes required only for non-YOYO modes
    if (state.currentStep == 2 && state.mode != 'yoyo' && state.athletes.isEmpty) {
      errorCubit.showWarning('Add at least one athlete before continuing.');
      return;
    }

    // YOYO: skip step 3 (trial config — not applicable)
    if (state.currentStep == 2 && state.mode == 'yoyo') {
      emit(state.copyWith(currentStep: 4));
      return;
    }

    if (state.currentStep < 6) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void prevStep() {
    // YOYO: skip step 3 going backwards
    if (state.currentStep == 4 && state.mode == 'yoyo') {
      emit(state.copyWith(currentStep: 2));
      return;
    }
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void goToStep(int step) => emit(state.copyWith(currentStep: step));

  // ── Step 0: Mode selection ─────────────────────────────────────────────────

  void selectMode(String mode) {
    if (mode == 'yoyo') {
      emit(state.copyWith(
        mode: 'yoyo',
        subMode: '',
        protocol: '',
        trialsCount: 1,
        yoyoNumLanes: 1,
        yoyoLaneStatuses: [const YoYoLaneStatus(laneNumber: 1)],
      ));
      return;
    }
    if (mode == 'shuttle') {
      emit(state.copyWith(mode: 'shuttle', subMode: '', protocol: '', trialsCount: 1));
      return;
    }
    emit(state.copyWith(mode: mode, subMode: '', protocol: ''));
  }

  void selectSubMode(String subMode) => emit(state.copyWith(subMode: subMode, protocol: ''));
  void selectProtocol(String protocol) => emit(state.copyWith(protocol: protocol));

  void updateCustomDistance(double? distance) {
    if (distance == null) {
      emit(state.copyWith(clearCustomDistance: true));
    } else {
      emit(state.copyWith(customDistance: distance));
    }
  }

  /// YOYO: update lane count and reinitialize lane statuses
  void selectYoyoLanes(int lanes) {
    emit(state.copyWith(
      yoyoNumLanes: lanes,
      yoyoLaneStatuses: List.generate(lanes, (i) => YoYoLaneStatus(laneNumber: i + 1)),
    ));
  }

  /// Shuttle: update lane count (max 3)
  void selectShuttleLanes(int lanes) {
    emit(state.copyWith(shuttleNumLanes: lanes.clamp(1, 3)));
  }

  // ── Step 1: Test info ──────────────────────────────────────────────────────

  void updateTestName(String v) => emit(state.copyWith(testName: v));
  void updateLocation(String v) => emit(state.copyWith(location: v));
  void updateNotes(String v) => emit(state.copyWith(notes: v));
  void updateDate(DateTime? d) {
    if (d == null) {
      emit(state.copyWith(clearDate: true));
    } else {
      emit(state.copyWith(testDate: d));
    }
  }

  // ── Step 2: Athletes ───────────────────────────────────────────────────────

  void addAthlete(AthleteModel athlete) {
    emit(state.copyWith(athletes: [...state.athletes, athlete]));
  }

  void removeAthlete(String id) {
    emit(state.copyWith(athletes: state.athletes.where((a) => a.id != id).toList()));
  }

  void importAthletes(List<AthleteModel> incoming, {bool replaceAll = false}) {
    if (replaceAll) {
      emit(state.copyWith(athletes: incoming));
      return;
    }
    final existing = state.athletes;
    final existingKeys = existing.map(_dedupeKey).toSet();
    final newOnes = incoming.where((a) => !existingKeys.contains(_dedupeKey(a))).toList();
    emit(state.copyWith(athletes: [...existing, ...newOnes]));
  }

  static String _dedupeKey(AthleteModel a) =>
      a.athleteId.isNotEmpty ? a.athleteId.toLowerCase() : a.fullName.toLowerCase();

  void selectTrialMode(String mode) => emit(state.copyWith(trialMode: mode));
  void updateTrialsCount(int count) => emit(state.copyWith(trialsCount: count.clamp(1, 10)));

  void changeTrials(String athleteId, int delta) {
    final updated = state.athletes.map((a) {
      if (a.id != athleteId) return a;
      return a.copyWith(trials: (a.trials + delta).clamp(1, 10));
    }).toList();
    emit(state.copyWith(athletes: updated));
  }

  void updateSearch(String q) => emit(state.copyWith(searchQuery: q));
  void updateTeamFilter(String t) => emit(state.copyWith(teamFilter: t));

  // ── Step 3: Gate setup ─────────────────────────────────────────────────────

  void beginGateSetup() {
    // Reset lane statuses for fresh setup
    final laneStatuses = state.mode == 'yoyo'
        ? List.generate(state.yoyoNumLanes, (i) => YoYoLaneStatus(laneNumber: i + 1))
        : state.yoyoLaneStatuses;

    // Sprint mode: start with Master = 0.0 (fixed start point).
    // Each gate that registers appends one more entry.
    // Final layout: [Master=0, G1, G2, ..., Gn=totalDist]
    List<double> initialDistances = const [];
    if (state.mode == 'linear' && state.subMode == 'sprint') {
      initialDistances = [0.0]; // Master position (always 0, locked)
    }

    emit(state.copyWith(
      registeredGatesCount: 0,
      allGatesReady: false,
      gateSetupLog: const [],
      yoyoLaneStatuses: laneStatuses,
      gateDistances: initialDistances,
    ));
    final expectedGates = state.expectedGatesCount;
    bleService.send('RESET');
    bleService.send(state.firmwareModeCommand);
    bleService.send('SETUP');
    _addSetupLog('Sent: ${state.firmwareModeCommand}');
    if (state.mode == 'yoyo') {
      _addSetupLog('Sent: SETUP — Trigger FINISH gate first, then TURN gate per lane.');
    } else {
      _addSetupLog('Sent: SETUP — Walk through $expectedGates gate(s) in order.');
    }
  }

  /// Sprint: update distance for one gate (coach manual input).
  /// index 0 = Master (locked), index last = finish (locked by startTest).
  /// index 1 = G1 (editable, can be 0 if athlete starts at G1).
  void setGateDistance(int index, double distance) {
    if (index <= 0 || index >= state.gateDistances.length) return;
    final updated = List<double>.from(state.gateDistances);
    updated[index] = distance;
    emit(state.copyWith(gateDistances: updated));
  }

  double _sprintTotalDistance() {
    if (state.protocol == 'custom') return state.customDistance ?? 0.0;
    final data = TimingSessionState.protocolData[state.protocol];
    if (data != null) return (data['distance'] as int).toDouble();
    return 0.0;
  }

  void _addSetupLog(String msg) {
    emit(state.copyWith(gateSetupLog: [...state.gateSetupLog, msg]));
  }

  void markGatesReady() {
    if (state.registeredGatesCount == 0) {
      errorCubit.showWarning('No gates registered yet. Walk through each gate first.');
      return;
    }
    emit(state.copyWith(allGatesReady: true));
    _addSetupLog('✓ Setup confirmed — ${state.registeredGatesCount} gate(s) ready.');
  }



  /// DEV ONLY — injects fake results for all lanes in the current shuttle batch.
  Future<void> simulateShuttleResult() async {
    if (state.mode != 'shuttle') return;
    if (state.phase != RunTestPhase.waitingForResult) return;
    final rng = Random();
    final batch = state.currentShuttleBatch;
    for (final item in batch) {
      final totalTime = 20.0 + rng.nextDouble() * 10.0;
      final parsed = ParsedResult(
        mode: 'shuttle',
        totalTime: double.parse(totalTime.toStringAsFixed(3)),
        splits: [],
        lane: item.shuttleLane,
      );
      await _onShuttleLaneResult(parsed);
    }
  }

  /// DEV ONLY — injects a fake result for non-YOYO modes.
  Future<void> simulateTrialResult() async {
    final item = state.currentQueueItem;
    if (item == null) return;
    if (state.phase != RunTestPhase.waitingForResult) return;

    final rng = Random();
    final gateCount = state.registeredGatesCount.clamp(2, 6);

    // Firmware sends interval time per gate crossing (gate-to-gate segment time).
    // splits[i] = time taken for segment i (NOT cumulative from start).
    final splits = List.generate(gateCount, (_) {
      final seg = 1.0 + rng.nextDouble() * 1.2;
      return double.parse(seg.toStringAsFixed(3));
    });
    final totalTime = splits.fold(0.0, (a, b) => a + b); // sum of all segments

    final trial = _enrichWithSpeedAccel(TrialResultModel(
      trialNumber: item.trialNumber,
      totalTime: totalTime,
      splits: splits,
      status: 'completed',
      timestamp: DateTime.now(),
    ));
    await _saveTrialAndAdvance(item, trial);
  }

  // ── Step 4: Run test ───────────────────────────────────────────────────────

  Future<void> startTest() async {
    // Shuttle: firmware may fire ALL_LANES_CONFIGURED without per-gate events,
    // so allGatesReady alone is sufficient. All other modes require at least
    // one gate physically registered to ensure distances/data are available.
    final gatesOk = state.mode == 'shuttle'
        ? (state.allGatesReady || state.registeredGatesCount > 0)
        : state.registeredGatesCount > 0;
    if (!gatesOk) {
      errorCubit.showWarning('No gates registered yet. Walk through each gate first.');
      return;
    }

    // Sprint: auto-set gate distances before starting.
    // gateDistances stores RELATIVE (segment) distances:
    //   [0, M→G1, G1→G2, ..., G(n-1)→Gn]
    if (state.mode == 'linear' && state.subMode == 'sprint' &&
        state.gateDistances.length >= 2) {
      final totalDist = _sprintTotalDistance();
      final locked = List<double>.from(state.gateDistances);
      final numSegments = locked.length - 1; // excludes Master (index 0)

      // M→G1 segment (locked[1]): respect the user's explicit entry.
      // 0 means the athlete starts at G1 — do NOT overwrite with auto-fill.
      final mToG1 = locked.length > 1 ? locked[1] : 0.0;
      final mToG1IsZero = mToG1 <= 0; // athlete starts at G1
      // First index that needs auto-filling (skip M→G1 when it's 0).
      final autoFillStart = mToG1IsZero ? 2 : 1;

      // If user skipped distance entry for all fillable segments (all are 0),
      // distribute the remaining distance equally starting from autoFillStart.
      final fillableMiddle = locked.length > autoFillStart
          ? locked.sublist(autoFillStart, locked.length - 1)
          : <double>[];
      final allEmpty = fillableMiddle.every((d) => d <= 0);
      if (allEmpty && totalDist > 0 && locked.length > autoFillStart) {
        final remainingDist = totalDist - mToG1;
        final numSegsToFill = locked.length - autoFillStart; // includes last seg
        final equalDist = double.parse(
          (remainingDist / numSegsToFill).toStringAsFixed(2),
        );
        for (int i = autoFillStart; i < locked.length; i++) {
          locked[i] = equalDist;
        }
      } else {
        // Partial entry: auto-fill only the last segment = remaining distance.
        double entered = 0;
        for (int i = 1; i < locked.length - 1; i++) {
          entered += locked[i];
        }
        locked[locked.length - 1] = (totalDist - entered).clamp(0, double.infinity);
      }

      emit(state.copyWith(gateDistances: locked));
    }
    if (state.mode != 'yoyo' && state.athletes.isEmpty) {
      errorCubit.showWarning('No athletes in session.');
      return;
    }

    // Already started (false start case) — just go back to step 5
    if (state.sessionId != null) {
      emit(state.copyWith(
        currentStep: 5,
        phase: RunTestPhase.ready,
        yoyoPhase: state.mode == 'yoyo' ? YoYoPhase.idle : state.yoyoPhase,
      ));
      return;
    }

    // ── YOYO start ────────────────────────────────────────────────────────
    if (state.mode == 'yoyo') {
      final sessionId = _uuid.v4();
      final results = _buildYoyoInitialResults();
      final session = TestSessionModel(
        id: sessionId,
        sessionName: state.testName.isNotEmpty ? state.testName : _autoSessionName(),
        date: state.testDate ?? DateTime.now(),
        mode: state.mode,
        subMode: '',
        protocol: '',
        customDistance: null,
        trialMode: 'yoyo',
        trialsCount: 0,
        status: 'in_progress',
        athletes: state.athletes,
        results: results,
        location: state.location,
        notes: state.notes,
        gateDistances: state.gateDistances,
      );
      try {
        await sessionRepository.save(session);
      } catch (e) {
        errorCubit.showError('Failed to save session: $e');
        return;
      }
      emit(state.copyWith(
        currentStep: 5,
        results: results,
        sessionId: sessionId,
        yoyoPhase: YoYoPhase.idle,
      ));
      return;
    }

    // ── Non-YOYO start ────────────────────────────────────────────────────
    final queue = _buildQueue();
    final results = _buildInitialResults();
    final sessionId = _uuid.v4();

    final session = TestSessionModel(
      id: sessionId,
      sessionName: state.testName.isNotEmpty ? state.testName : _autoSessionName(),
      date: state.testDate ?? DateTime.now(),
      mode: state.mode,
      subMode: state.subMode,
      protocol: state.protocol,
      customDistance: state.customDistance,
      trialMode: state.trialMode,
      trialsCount: state.trialsCount,
      status: 'in_progress',
      athletes: state.athletes,
      results: results,
      location: state.location,
      notes: state.notes,
      gateDistances: state.gateDistances,
    );
    try {
      await sessionRepository.save(session);
    } catch (e) {
      errorCubit.showError('Failed to save session: $e');
      return;
    }

    emit(state.copyWith(
      currentStep: 5,
      trialQueue: queue,
      queueIndex: 0,
      results: results,
      phase: RunTestPhase.ready,
      sessionId: sessionId,
      shuttleBatchResults: const {},
    ));
  }

  void sendStart() {
    // YOYO: just send START — firmware handles countdown + test
    if (state.mode == 'yoyo') {
      emit(state.copyWith(yoyoPhase: YoYoPhase.countdown));
      bleService.send('START');
      return;
    }
    if (state.phase != RunTestPhase.ready) return;
    if (state.mode == 'shuttle') {
      final batch = state.currentShuttleBatch;
      debugPrint(
        '[SHUTTLE] ▶ START sent'
        ' | trial=${batch.isEmpty ? "?" : batch.first.trialNumber}/${state.trialsCount}'
        ' | batch size=${batch.length}'
        ' | lanes: ${batch.map((b) => 'L${b.shuttleLane}→${b.athleteName}').join(', ')}'
        ' | queueIndex=${state.queueIndex}/${state.trialQueue.length}',
      );
    }
    emit(state.copyWith(phase: RunTestPhase.waitingForResult));
    bleService.send('START');
  }

  void feedBleData(String line) {
    debugPrint('[SESSION] 📥 BLE raw: "$line"');
    _parser.feed(line);
  }

  // ── BLE callbacks ──────────────────────────────────────────────────────────

  Future<void> _onParsedResult(ParsedResult parsed) async {
    if (state.mode == 'shuttle' && parsed.lane != null) {
      await _onShuttleLaneResult(parsed);
      return;
    }
    final item = state.currentQueueItem;
    if (item == null) return;
    final trial = _enrichWithSpeedAccel(parsed.toTrialResult(item.trialNumber));
    await _saveTrialAndAdvance(item, trial);
  }

  /// Calculate speed & acceleration for sprint trials using gate distances.
  ///
  /// gateDistances stores RELATIVE (segment) distances:
  ///   [0 (Master), M→G1, G1→G2, G2→G3, ..., G(n-1)→Gn]
  ///
  /// rawSplits = INTERVAL times from firmware (gate-to-gate, NOT cumulative):
  ///   [t_MG1, t_G1G2, t_G2G3, ..., t_G(n-1)Gn]
  ///
  /// segDist = gateDistances[i+1]  (segment distance)
  /// segTime = rawSplits[i]        (interval time for this segment, used directly)
  ///
  /// accels[i] maps directly to speeds[i]:
  ///   accels[0] = speeds[0] / segTime[0]             (v_initial = 0, from rest)
  ///   accels[i] = (speeds[i] - speeds[i-1]) / segTime[i]  for i > 0
  ///
  /// Skip segment if segDist == 0 (e.g. M→G1 when athlete starts at G1).
  TrialResultModel _enrichWithSpeedAccel(TrialResultModel trial) {
    if (state.mode != 'linear' || state.subMode != 'sprint') return trial;
    final segDists  = state.gateDistances; // relative distances
    final rawSplits = trial.splits;        // interval gate times (gate-to-gate)
    if (segDists.length < 2 || rawSplits.isEmpty) return trial;

    final speeds   = <double>[];
    final segTimes = <double>[];
    final int segs = segDists.length - 1; // number of segments

    for (int i = 0; i < segs && i < rawSplits.length; i++) {
      final segDist = segDists[i + 1]; // relative: G[i] → G[i+1]
      final segTime = rawSplits[i];    // interval time for this segment

      if (segDist == 0) continue; // skip zero-distance segment (M==G1)
      if (segTime <= 0) continue;

      speeds.add(segDist / segTime);
      segTimes.add(segTime);
    }

    // Accelerations: one per segment (accels[i] maps directly to speeds[i]).
    // First segment: athlete starts from rest → v_initial = 0.
    //   a[0] = (speed[0] - 0) / segTime[0]
    // Subsequent segments: rate of change between consecutive speeds.
    //   a[i] = (speed[i] - speed[i-1]) / segTime[i]
    final accels = <double>[];
    for (int i = 0; i < speeds.length; i++) {
      final vPrev = i == 0 ? 0.0 : speeds[i - 1];
      accels.add((speeds[i] - vPrev) / segTimes[i]);
    }

    return trial.copyWith(speeds: speeds, accelerations: accels);
  }

  Future<void> _onShuttleLaneResult(ParsedResult parsed) async {
    final lane = parsed.lane!;
    debugPrint(
      '[SHUTTLE] 📥 Lane $lane result received'
      ' | time=${parsed.totalTime}s'
      ' | splits=${parsed.splits.length}'
      ' | currentBatch=${state.currentShuttleBatch.map((i) => 'L${i.shuttleLane}').toList()}',
    );
    TrialQueueItem? item;
    try {
      item = state.currentShuttleBatch.firstWhere((i) => i.shuttleLane == lane);
    } catch (_) {
      debugPrint(
        '[SHUTTLE] ⚠ Lane $lane NOT in current batch'
        ' — expected lanes: ${state.currentShuttleBatch.map((i) => i.shuttleLane).toList()}'
        ' | result discarded',
      );
      return;
    }
    debugPrint('[SHUTTLE] ✓ Lane $lane matched → ${item.athleteName} (trial ${item.trialNumber})');
    final trial = parsed.toTrialResult(item.trialNumber);
    final updatedResults = _upsertTrial(item.athleteId, trial);
    final updatedBatch = Map<int, TrialResultModel>.from(state.shuttleBatchResults)..[lane] = trial;

    if (state.sessionId != null) {
      try {
        await sessionRepository.saveTrial(
          sessionId: state.sessionId!,
          athleteId: item.athleteId,
          trial: trial,
        );
      } catch (e) {
        errorCubit.showError('Failed to save trial: $e');
      }
    }

    final batch = state.currentShuttleBatch;
    final allDone = batch.every((i) => updatedBatch.containsKey(i.shuttleLane));
    debugPrint(
      '[SHUTTLE] 📊 Batch progress: ${updatedBatch.length}/${batch.length} lanes done'
      ' | allDone=$allDone'
      ' | doneLanes=${updatedBatch.keys.toList()}'
      ' | pendingLanes=${batch.where((i) => !updatedBatch.containsKey(i.shuttleLane)).map((i) => i.shuttleLane).toList()}',
    );

    if (allDone && state.sessionId != null) {
      final isLastBatch = state.queueIndex + batch.length >= state.trialQueue.length;
      debugPrint('[SHUTTLE] 🏁 Batch complete | queueIndex=${state.queueIndex} | isLastBatch=$isLastBatch');
      if (isLastBatch) {
        debugPrint('[SHUTTLE] 🎉 Last batch — finalizing session');
        try {
          // Merge with Hive's copy in case another lane's saveTrial() ran
          // concurrently and the in-memory updatedResults is behind.
          final hiveSession = sessionRepository.getById(state.sessionId!);
          final mergedResults = hiveSession != null
              ? hiveSession.results
              : updatedResults;
          await sessionRepository.finalizeSession(
            sessionId: state.sessionId!,
            results: mergedResults,
            status: 'completed',
          );
        } catch (e) {
          errorCubit.showError('Failed to finalize session: $e');
        }
      }
    }

    emit(state.copyWith(
      results: updatedResults,
      shuttleBatchResults: updatedBatch,
      phase: allDone ? RunTestPhase.result : RunTestPhase.waitingForResult,
    ));
  }

  void _onBleEvent(BleEvent event) {
    debugPrint('[SESSION] 🔔 BLE event: ${event.type} | raw: ${event.raw}');
    switch (event.type) {
      // ── Standard events ────────────────────────────────────────────────────
      case BleEventType.gateRegistered:
        final newCount = state.registeredGatesCount + 1;
        // Sprint: dynamically grow gateDistances as each gate registers
        // First gate = 0.0 (start, auto), rest = 0.0 (coach fills middle)
        List<double>? updatedDistances;
        if (state.mode == 'linear' && state.subMode == 'sprint') {
          updatedDistances = [...state.gateDistances, 0.0];
          // gateDistances.length always == registeredGatesCount
        }
        emit(state.copyWith(
          registeredGatesCount: newCount,
          gateDistances: updatedDistances,
        ));
        _addSetupLog('✓ Gate $newCount registered');
        break;

      case BleEventType.allGatesReady:
        _addSetupLog('✓ All lanes configured — tap Start to begin.');
        emit(state.copyWith(allGatesReady: true));
        break;

      case BleEventType.setupActive:
        _addSetupLog('⚙ Setup active — walk through each gate.');
        break;

      case BleEventType.modeConfirmed:
        _addSetupLog('✓ Mode confirmed: ${event.message}');
        break;

      case BleEventType.raceStarted:
        emit(state.copyWith(phase: RunTestPhase.waitingForResult));
        break;

      case BleEventType.laneStarted:
        _addSetupLog('🏃 Lane ${event.lane} started');
        break;

      case BleEventType.stateIdle:
        break;

      case BleEventType.systemReset:
        // Do NOT clear gateSetupLog here — beginGateSetup() already cleared it
        // before sending RESET. Clearing it again on RESET_SUCCESS causes the
        // "Setup Gates" button to re-enable briefly (flicker bug).
        emit(state.copyWith(
          registeredGatesCount: 0,
          allGatesReady: false,
        ));
        break;

      case BleEventType.systemReady:
        _addSetupLog('✓ Firmware ready');
        break;

      case BleEventType.error:
        errorCubit.showError(event.message ?? 'Firmware error');
        break;

      // ── YOYO events ────────────────────────────────────────────────────────
      case BleEventType.yoyoGateRegistered:
        _handleYoyoGateRegistered(event);
        break;

      case BleEventType.yoyoSetupComplete:
        _addSetupLog('✓ All YOYO gates registered — tap Start to begin.');
        emit(state.copyWith(allGatesReady: true));
        break;

      case BleEventType.yoyoCountdown:
        emit(state.copyWith(yoyoPhase: YoYoPhase.countdown));
        break;

      case BleEventType.yoyoRepStart:
        _handleYoyoRepStart(event);
        break;

      case BleEventType.yoyoTurnHit:
        _handleYoyoTurnHit(event);
        break;

      case BleEventType.yoyoFinishHit:
        _handleYoyoFinishHit(event);
        break;

      case BleEventType.yoyoRepEnd:
        // laneResult events follow — no UI action needed here
        break;

      case BleEventType.yoyoLaneResult:
        _handleYoyoLaneResult(event);
        break;

      case BleEventType.yoyoStandings:
        _handleYoyoStandings(event);
        break;

      case BleEventType.yoyoRecovery:
        emit(state.copyWith(
          yoyoPhase: YoYoPhase.recovery,
          yoyoCurrentLevel: event.level ?? state.yoyoCurrentLevel,
          yoyoCurrentRep: event.rep ?? state.yoyoCurrentRep,
        ));
        break;

      case BleEventType.yoyoTestOver:
        _handleYoyoTestOver(event.yoyoResult ?? 'all_eliminated');
        break;
    }
  }

  // ── YOYO event helpers ─────────────────────────────────────────────────────

  void _handleYoyoGateRegistered(BleEvent event) {
    final laneIdx = (event.lane ?? 1) - 1;
    final newCount = state.registeredGatesCount + 1;
    if (laneIdx >= 0 && laneIdx < state.yoyoLaneStatuses.length) {
      final updated = List<YoYoLaneStatus>.from(state.yoyoLaneStatuses);
      final status = updated[laneIdx];
      updated[laneIdx] = event.isFinishGate == true
          ? status.copyWith(finishGateOk: true)
          : status.copyWith(turnGateOk: true);
      final gateRole = event.isFinishGate == true ? 'Finish' : 'Turn';
      _addSetupLog('✓ Lane ${event.lane} $gateRole gate registered (ID ${event.gateId})');
      emit(state.copyWith(yoyoLaneStatuses: updated, registeredGatesCount: newCount));
    } else {
      emit(state.copyWith(registeredGatesCount: newCount));
    }
  }

  void _handleYoyoRepStart(BleEvent event) {
    // Reset per-rep hit flags for all lanes
    final updated = state.yoyoLaneStatuses
        .map((l) => l.copyWith(turnHit: false, finishHit: false, clearLastFinishTime: true))
        .toList();
    emit(state.copyWith(
      yoyoPhase: YoYoPhase.running,
      yoyoCurrentLevel: event.level ?? state.yoyoCurrentLevel,
      yoyoCurrentRep: event.rep ?? state.yoyoCurrentRep,
      yoyoWindowSecs: event.windowSecs ?? state.yoyoWindowSecs,
      yoyoLaneStatuses: updated,
    ));
  }

  void _handleYoyoTurnHit(BleEvent event) {
    final laneIdx = (event.lane ?? 1) - 1;
    if (laneIdx < 0 || laneIdx >= state.yoyoLaneStatuses.length) return;
    final updated = List<YoYoLaneStatus>.from(state.yoyoLaneStatuses);
    updated[laneIdx] = updated[laneIdx].copyWith(turnHit: true);
    emit(state.copyWith(yoyoLaneStatuses: updated));
  }

  void _handleYoyoFinishHit(BleEvent event) {
    final laneIdx = (event.lane ?? 1) - 1;
    if (laneIdx < 0 || laneIdx >= state.yoyoLaneStatuses.length) return;
    final updated = List<YoYoLaneStatus>.from(state.yoyoLaneStatuses);
    updated[laneIdx] = updated[laneIdx].copyWith(
      finishHit: true,
      lastFinishTime: event.finishTime,
    );
    emit(state.copyWith(yoyoLaneStatuses: updated));
  }

  void _handleYoyoLaneResult(BleEvent event) {
    final laneIdx = (event.lane ?? 1) - 1;
    if (laneIdx < 0 || laneIdx >= state.yoyoLaneStatuses.length) return;
    final updated = List<YoYoLaneStatus>.from(state.yoyoLaneStatuses);
    final status = updated[laneIdx];
    final currentLevel = event.level ?? state.yoyoCurrentLevel;
    switch (event.yoyoResult) {
      case 'eliminated':
        // 2nd strike = elimination level
        updated[laneIdx] = status.copyWith(
          eliminated: true,
          strikes: 2,
          eliminatedAtLevel: currentLevel,
          eliminatedAtRep: event.rep ?? state.yoyoCurrentRep,
          secondStrikeLevel: currentLevel,
          // If first strike was never recorded yet, fill it too (edge case)
          firstStrikeLevel: status.firstStrikeLevel ?? currentLevel,
        );
        break;
      case 'miss':
        final newStrikes = event.strikes ?? (status.strikes + 1);
        updated[laneIdx] = status.copyWith(
          strikes: newStrikes,
          // 1st miss → record firstStrikeLevel
          firstStrikeLevel: (newStrikes == 1 && status.firstStrikeLevel == null)
              ? currentLevel
              : status.firstStrikeLevel,
          // 2nd miss → record secondStrikeLevel (in case firmware sends miss instead of eliminated)
          secondStrikeLevel: (newStrikes >= 2 && status.secondStrikeLevel == null)
              ? currentLevel
              : status.secondStrikeLevel,
        );
        break;
      case 'pass':
        updated[laneIdx] = status.copyWith(strikes: event.strikes ?? status.strikes);
        break;
      default:
        break;
    }
    emit(state.copyWith(yoyoLaneStatuses: updated));
  }

  void _handleYoyoStandings(BleEvent event) {
    final laneIdx = (event.lane ?? 1) - 1;
    if (laneIdx < 0 || laneIdx >= state.yoyoLaneStatuses.length) return;
    final updated = List<YoYoLaneStatus>.from(state.yoyoLaneStatuses);
    final status = updated[laneIdx];
    if (event.yoyoResult == 'eliminated') {
      updated[laneIdx] = status.copyWith(eliminated: true);
    } else {
      updated[laneIdx] = status.copyWith(strikes: event.strikes ?? status.strikes);
    }
    emit(state.copyWith(yoyoLaneStatuses: updated));
  }

  Future<void> _handleYoyoTestOver(String reason) async {
    final finalResults = _buildYoyoFinalResults();
    if (state.sessionId != null) {
      try {
        await sessionRepository.finalizeSession(
          sessionId: state.sessionId!,
          results: finalResults,
          status: 'completed',
        );
      } catch (e) {
        errorCubit.showError('Failed to save YOYO results: $e');
      }
    }
    emit(state.copyWith(
      yoyoPhase: YoYoPhase.done,
      yoyoTestOverReason: reason,
      results: finalResults,
    ));
  }

  // ── Trial result handling (non-YOYO) ──────────────────────────────────────

  Future<void> _saveTrialAndAdvance(TrialQueueItem item, TrialResultModel trial) async {
    final updatedResults = _upsertTrial(item.athleteId, trial);
    if (state.sessionId != null) {
      try {
        await sessionRepository.saveTrial(
          sessionId: state.sessionId!,
          athleteId: item.athleteId,
          trial: trial,
        );
        await sessionRepository.updateQueueIndex(state.sessionId!, state.queueIndex + 1);
      } catch (e) {
        errorCubit.showError('Failed to save trial: $e');
      }
    }
    final isLast = state.isLastQueueItem;
    if (isLast && state.sessionId != null) {
      try {
        await sessionRepository.finalizeSession(
          sessionId: state.sessionId!,
          results: updatedResults,
          status: 'completed',
        );
      } catch (e) {
        errorCubit.showError('Failed to save session results: $e');
      }
    }
    emit(state.copyWith(
      results: updatedResults,
      lastTrialResult: trial,
      phase: isLast ? RunTestPhase.done : RunTestPhase.result,
    ));
  }

  void acceptResult() {
    if (state.phase != RunTestPhase.result) return;
    if (state.mode == 'shuttle') {
      final batchSize = state.currentShuttleBatch.length;
      final newIndex = state.queueIndex + batchSize;
      debugPrint(
        '[SHUTTLE] ➡ Accepted — advancing queueIndex ${state.queueIndex} → $newIndex'
        ' | ${newIndex >= state.trialQueue.length ? "SESSION DONE" : "next batch ready"}',
      );
      if (newIndex >= state.trialQueue.length) {
        emit(state.copyWith(phase: RunTestPhase.done, currentStep: 6));
      } else {
        emit(state.copyWith(
          queueIndex: newIndex,
          phase: RunTestPhase.ready,
          clearLastTrialResult: true,
          shuttleBatchResults: const {},
        ));
      }
      return;
    }
    if (state.isLastQueueItem) {
      emit(state.copyWith(phase: RunTestPhase.done, currentStep: 6));
      return;
    }
    emit(state.copyWith(
      queueIndex: state.queueIndex + 1,
      phase: RunTestPhase.ready,
      clearLastTrialResult: true,
    ));
  }

  Future<void> skipTrial() async {
    if (state.mode == 'shuttle') {
      final batch = state.currentShuttleBatch;
      debugPrint(
        '[SHUTTLE] ⏭ Skip batch | ${batch.length} athletes'
        ' | lanes: ${batch.map((b) => 'L${b.shuttleLane}→${b.athleteName}').join(', ')}'
        ' | trial=${batch.isEmpty ? "?" : batch.first.trialNumber}',
      );
      for (final item in batch) {
        final skipped = TrialResultModel(
          trialNumber: item.trialNumber,
          status: 'skipped',
          timestamp: DateTime.now(),
        );
        if (state.sessionId != null) {
          try {
            await sessionRepository.saveTrial(
              sessionId: state.sessionId!,
              athleteId: item.athleteId,
              trial: skipped,
            );
          } catch (_) {}
        }
      }
      final newIndex = state.queueIndex + batch.length;
      if (newIndex >= state.trialQueue.length) {
        emit(state.copyWith(phase: RunTestPhase.done, currentStep: 6));
      } else {
        emit(state.copyWith(
          queueIndex: newIndex,
          phase: RunTestPhase.ready,
          clearLastTrialResult: true,
          shuttleBatchResults: const {},
        ));
      }
      return;
    }
    final item = state.currentQueueItem;
    if (item == null) return;
    final skipped = TrialResultModel(
      trialNumber: item.trialNumber,
      status: 'skipped',
      timestamp: DateTime.now(),
    );
    await _saveTrialAndAdvance(item, skipped);
    if (state.phase == RunTestPhase.result) acceptResult();
  }

  Future<void> falseStart() async {
    if (state.mode == 'shuttle') {
      final batch = state.currentShuttleBatch;
      debugPrint(
        '[SHUTTLE] 🔴 False start | ${batch.length} athletes cancelled'
        ' | lanes: ${batch.map((b) => 'L${b.shuttleLane}→${b.athleteName}').join(', ')}'
        ' | will retry same batch',
      );
      for (final item in batch) {
        final fs = TrialResultModel(
          trialNumber: item.trialNumber,
          status: 'false_start',
          timestamp: DateTime.now(),
        );
        if (state.sessionId != null) {
          try {
            await sessionRepository.saveTrial(
              sessionId: state.sessionId!,
              athleteId: item.athleteId,
              trial: fs,
            );
          } catch (_) {}
        }
      }
      // False start: cancel the race, keep gates armed — no re-setup needed.
      emit(state.copyWith(
        phase: RunTestPhase.ready,
        clearLastTrialResult: true,
        shuttleBatchResults: const {},
      ));
      return;
    }
    final item = state.currentQueueItem;
    if (item == null) return;
    final fs = TrialResultModel(
      trialNumber: item.trialNumber,
      status: 'false_start',
      timestamp: DateTime.now(),
    );
    if (state.sessionId != null) {
      await sessionRepository.saveTrial(
        sessionId: state.sessionId!,
        athleteId: item.athleteId,
        trial: fs,
      );
    }
    // False start: cancel the race only. Sending RESET would de-register the
    // gates, so we stay ready and let the coach tap Start when ready again.
    emit(state.copyWith(
      phase: RunTestPhase.ready,
      clearLastTrialResult: true,
    ));
  }

  // ── Queue builders ─────────────────────────────────────────────────────────

  List<TrialQueueItem> _buildQueue() {
    final athletes = state.athletes;
    final trials = state.trialsCount;
    final queue = <TrialQueueItem>[];

    if (state.mode == 'shuttle') {
      // Shuttle lanes always run in parallel — queue must group all athletes
      // by trial so currentShuttleBatch can collect one athlete per lane.
      // athlete_complete ordering (athlete × trial) would place the same lane
      // on consecutive items, causing currentShuttleBatch to return a batch of
      // 1 and silently skip all other athletes. Always use trial × athlete order.
      final numLanes = state.shuttleNumLanes;
      for (int t = 1; t <= trials; t++) {
        for (int i = 0; i < athletes.length; i++) {
          queue.add(TrialQueueItem(
            athleteId: athletes[i].id,
            athleteName: athletes[i].fullName,
            trialNumber: t,
            shuttleLane: (i % numLanes) + 1,
          ));
        }
      }
    } else {
      if (state.trialMode == 'round_robin') {
        for (int t = 1; t <= trials; t++) {
          for (final a in athletes) {
            queue.add(TrialQueueItem(athleteId: a.id, athleteName: a.fullName, trialNumber: t));
          }
        }
      } else {
        for (final a in athletes) {
          for (int t = 1; t <= trials; t++) {
            queue.add(TrialQueueItem(athleteId: a.id, athleteName: a.fullName, trialNumber: t));
          }
        }
      }
    }
    if (state.mode == 'shuttle') {
      final numLanes = state.shuttleNumLanes;
      final laneMap = <int, List<String>>{};
      for (final item in queue) {
        laneMap.putIfAbsent(item.shuttleLane ?? 1, () => []);
        if (!laneMap[item.shuttleLane ?? 1]!.contains(item.athleteName)) {
          laneMap[item.shuttleLane ?? 1]!.add(item.athleteName);
        }
      }
      debugPrint(
        '[SHUTTLE] 📋 Queue built'
        ' | ${queue.length} items total'
        ' | ${athletes.length} athletes × ${state.trialsCount} trials × $numLanes lanes'
        ' | lane assignments: ${laneMap.entries.map((e) => 'L${e.key}→[${e.value.join(', ')}]').join(', ')}',
      );
    }
    return queue;
  }

  List<AthleteResultModel> _buildInitialResults() {
    final numLanes = state.shuttleNumLanes;
    return state.athletes.asMap().entries.map((entry) {
      final i = entry.key;
      final a = entry.value;
      return AthleteResultModel(
        athleteId: a.id,
        fullName: a.fullName,
        bib: a.bib,
        team: a.team,
        discipline: a.discipline,
        trials: const [],
        // Shuttle: persist lane assignment so results screen can show it.
        // Uses same modulo formula as _buildQueue().
        shuttleLane: state.mode == 'shuttle' ? (i % numLanes) + 1 : null,
      );
    }).toList();
  }

  List<AthleteResultModel> _buildYoyoInitialResults() {
    return List.generate(state.yoyoNumLanes, (i) {
      final athlete = i < state.athletes.length ? state.athletes[i] : null;
      return AthleteResultModel(
        athleteId: athlete?.id ?? 'yoyo_lane_${i + 1}',
        fullName: athlete?.fullName ?? 'Lane ${i + 1}',
        bib: athlete?.bib ?? '',
        team: athlete?.team ?? '',
        discipline: athlete?.discipline ?? '',
        trials: const [],
        shuttleLane: i + 1,
      );
    });
  }

  List<AthleteResultModel> _buildYoyoFinalResults() {
    final globalLevel = double.tryParse(state.yoyoCurrentLevel) ?? 0.0;
    return state.results.map((r) {
      final laneIdx = (r.shuttleLane ?? 1) - 1;
      final laneStatus = laneIdx < state.yoyoLaneStatuses.length
          ? state.yoyoLaneStatuses[laneIdx]
          : null;

      // Per-lane level: eliminated athletes show THEIR elimination level,
      // surviving athletes show the global (last) level.
      final double laneLevel;
      if (laneStatus?.eliminated == true && laneStatus?.eliminatedAtLevel != null) {
        laneLevel = double.tryParse(laneStatus!.eliminatedAtLevel!) ?? globalLevel;
      } else {
        laneLevel = globalLevel;
      }

      final trial = TrialResultModel(
        trialNumber: 1,
        totalTime: laneLevel,
        splits: [],
        status: laneStatus?.eliminated == true ? 'eliminated' : 'completed',
        timestamp: DateTime.now(),
        firstStrikeLevel: laneStatus?.firstStrikeLevel,
        secondStrikeLevel: laneStatus?.secondStrikeLevel,
      );
      return r.copyWith(trials: [trial]);
    }).toList();
  }

  List<AthleteResultModel> _upsertTrial(String athleteId, TrialResultModel trial) {
    return state.results.map((r) {
      if (r.athleteId != athleteId) return r;
      final updatedTrials = List<TrialResultModel>.from(r.trials);
      final idx = updatedTrials.indexWhere((t) => t.trialNumber == trial.trialNumber);
      if (idx >= 0) {
        updatedTrials[idx] = trial;
      } else {
        updatedTrials.add(trial);
      }
      return r.copyWith(trials: updatedTrials);
    }).toList();
  }

  String _autoSessionName() {
    final label = state.modeLabel;
    final date = DateTime.now();
    return '$label — ${date.day}/${date.month}/${date.year}';
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  void resetGates() {
    bleService.send('RESET');
    _parser.reset();
    final emptyLanes = state.mode == 'yoyo'
        ? List.generate(state.yoyoNumLanes, (i) => YoYoLaneStatus(laneNumber: i + 1))
        : state.yoyoLaneStatuses;
    // Sprint: reset back to just Master = 0.0
    final resetDistances = (state.mode == 'linear' && state.subMode == 'sprint')
        ? [0.0]
        : state.gateDistances;
    emit(state.copyWith(
      registeredGatesCount: 0,
      allGatesReady: false,
      gateSetupLog: const [],
      yoyoLaneStatuses: emptyLanes,
      gateDistances: resetDistances,
    ));
  }

  /// Soft reset — starts a new session without disturbing gate registration.
  /// Preserves: mode, subMode, protocol, athletes, gate distances & counts.
  /// Clears:    results, session ID, trial queue, phase, test info fields.
  /// Returns to Step 1 (test info) so coach can name the new session.
  void resetSession() {
    _parser.reset();

    // Reset yoyo lane statuses to clean state (keep lane count)
    final freshLanes = state.mode == 'yoyo'
        ? List.generate(state.yoyoNumLanes, (i) => YoYoLaneStatus(laneNumber: i + 1))
        : state.yoyoLaneStatuses;

    emit(state.copyWith(
      // ── Go back to test-info step ─────────────────────────────────────
      currentStep: 1,

      // ── Clear session-specific data ───────────────────────────────────
      testName: '',
      location: '',
      notes: '',
      clearDate: true,
      results: const [],
      trialQueue: const [],
      queueIndex: 0,
      clearLastTrialResult: true,
      shuttleBatchResults: const {},
      phase: RunTestPhase.ready,

      // ── Clear YOYO run state ──────────────────────────────────────────
      yoyoPhase: YoYoPhase.idle,
      yoyoCurrentLevel: '',
      yoyoCurrentRep: 0,
      yoyoWindowSecs: 0,
      clearYoyoTestOverReason: true,
      yoyoLaneStatuses: freshLanes,

      // ── Clear session ID ──────────────────────────────────────────────
      clearSessionId: true,

      // mode / subMode / protocol / athletes / gateDistances /
      // registeredGatesCount / allGatesReady → all preserved automatically
    ));
  }

  @override
  Future<void> close() {
    _bleSub?.cancel();
    return super.close();
  }
}
