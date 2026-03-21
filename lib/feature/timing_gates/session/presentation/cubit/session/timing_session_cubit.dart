import 'dart:async';
import 'dart:math';

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

  int _falseStartExpectedGates = 0;

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
        yoyoNumLanes: 1,
        yoyoLaneStatuses: [const YoYoLaneStatus(laneNumber: 1)],
      ));
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

    emit(state.copyWith(
      registeredGatesCount: 0,
      allGatesReady: false,
      gateSetupLog: const [],
      yoyoLaneStatuses: laneStatuses,
    ));
    final expectedGates = state.expectedGatesCount;
    bleService.send(state.firmwareModeCommand);
    bleService.send('SETUP:$expectedGates');
    _addSetupLog('Sent: ${state.firmwareModeCommand}');
    if (state.mode == 'yoyo') {
      _addSetupLog('Sent: SETUP:$expectedGates — Trigger FINISH gate first, then TURN gate per lane.');
    } else {
      _addSetupLog('Sent: SETUP:$expectedGates — Walk through $expectedGates gate(s) in order.');
    }
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

  /// DEV ONLY — simulates gates registering without BLE hardware.
  void simulateGatesForTesting({int gateCount = 3}) {
    if (state.mode == 'yoyo') {
      // Simulate YOYO: 2 gates per lane
      final lanes = List.generate(state.yoyoNumLanes, (i) {
        return YoYoLaneStatus(
          laneNumber: i + 1,
          finishGateOk: true,
          turnGateOk: true,
        );
      });
      final logs = <String>[
        '[DEV] Simulating ${state.yoyoNumLanes * 2} YOYO gates...',
        for (int i = 0; i < state.yoyoNumLanes; i++) ...[
          '✓ Lane ${i + 1} Finish gate registered (ID ${i * 2 + 1})',
          '✓ Lane ${i + 1} Turn gate registered (ID ${i * 2 + 2})',
        ],
        '✓ All YOYO gates ready — tap Start to begin.',
      ];
      emit(state.copyWith(
        yoyoLaneStatuses: lanes,
        registeredGatesCount: state.yoyoNumLanes * 2,
        allGatesReady: true,
        gateSetupLog: logs,
      ));
      return;
    }

    final logs = <String>[
      '[DEV] Simulating $gateCount gates...',
      for (int i = 1; i <= gateCount; i++) '✓ Gate $i registered',
      '✓ All gates ready — tap Start to begin.',
    ];
    emit(state.copyWith(
      registeredGatesCount: gateCount,
      allGatesReady: true,
      gateSetupLog: logs,
    ));
  }

  /// DEV ONLY — injects a fake result for non-YOYO modes.
  Future<void> simulateTrialResult() async {
    final item = state.currentQueueItem;
    if (item == null) return;
    if (state.phase != RunTestPhase.waitingForResult) return;

    final rng = Random();
    final gateCount = state.registeredGatesCount.clamp(2, 6);
    final splitCount = gateCount - 1;
    final splits = List.generate(splitCount, (_) {
      final base = 1.0 + rng.nextDouble() * 1.2;
      return double.parse(base.toStringAsFixed(3));
    });
    final totalTime = double.parse(splits.fold(0.0, (a, b) => a + b).toStringAsFixed(3));

    final trial = TrialResultModel(
      trialNumber: item.trialNumber,
      totalTime: totalTime,
      splits: splits,
      status: 'completed',
      timestamp: DateTime.now(),
    );
    await _saveTrialAndAdvance(item, trial);
  }

  // ── Step 4: Run test ───────────────────────────────────────────────────────

  Future<void> startTest() async {
    if (!state.allGatesReady) {
      errorCubit.showWarning('Gates are not ready yet.');
      return;
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
    emit(state.copyWith(phase: RunTestPhase.waitingForResult));
    bleService.send('START');
  }

  void feedBleData(String line) => _parser.feed(line);

  // ── BLE callbacks ──────────────────────────────────────────────────────────

  void _onParsedResult(ParsedResult parsed) {
    if (state.mode == 'shuttle' && parsed.lane != null) {
      _onShuttleLaneResult(parsed);
      return;
    }
    final item = state.currentQueueItem;
    if (item == null) return;
    final trial = parsed.toTrialResult(item.trialNumber);
    _saveTrialAndAdvance(item, trial);
  }

  Future<void> _onShuttleLaneResult(ParsedResult parsed) async {
    final lane = parsed.lane!;
    TrialQueueItem? item;
    try {
      item = state.currentShuttleBatch.firstWhere((i) => i.shuttleLane == lane);
    } catch (_) {
      return;
    }
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

    if (allDone && state.sessionId != null) {
      final isLastBatch = state.queueIndex + batch.length >= state.trialQueue.length;
      if (isLastBatch) {
        try {
          await sessionRepository.finalizeSession(
            sessionId: state.sessionId!,
            results: updatedResults,
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
    switch (event.type) {
      // ── Standard events ────────────────────────────────────────────────────
      case BleEventType.gateRegistered:
        final newCount = state.registeredGatesCount + 1;
        emit(state.copyWith(registeredGatesCount: newCount));
        if (state.phase == RunTestPhase.reArming) {
          // False-start re-arm: confirm when all gates re-registered
          if (_falseStartExpectedGates > 0 && newCount >= _falseStartExpectedGates) {
            _falseStartExpectedGates = 0;
            emit(state.copyWith(allGatesReady: true, phase: RunTestPhase.ready));
            _addSetupLog('✓ Gates re-armed ($newCount / ${state.expectedGatesCount}) — ready to start.');
          }
        } else {
          // Normal setup: auto-confirm when expected gate count reached
          final expected = state.expectedGatesCount;
          _addSetupLog('✓ Gate $newCount / $expected registered');
          if (newCount >= expected) {
            emit(state.copyWith(allGatesReady: true));
            _addSetupLog('✓ All $expected gate(s) ready — tap Start to begin.');
          }
        }
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
        emit(state.copyWith(
          registeredGatesCount: 0,
          allGatesReady: false,
          gateSetupLog: const [],
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
    switch (event.yoyoResult) {
      case 'eliminated':
        updated[laneIdx] = status.copyWith(
          eliminated: true,
          strikes: 2,
          eliminatedAtLevel: event.level ?? state.yoyoCurrentLevel,
          eliminatedAtRep: event.rep ?? state.yoyoCurrentRep,
        );
        break;
      case 'miss':
        updated[laneIdx] = status.copyWith(strikes: event.strikes ?? status.strikes);
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
      _falseStartExpectedGates = state.expectedGatesCount;
      bleService.send('RESET');
      bleService.send(state.firmwareModeCommand);
      bleService.send('SETUP:${state.expectedGatesCount}');
      emit(state.copyWith(
        phase: RunTestPhase.reArming,
        clearLastTrialResult: true,
        registeredGatesCount: 0,
        allGatesReady: false,
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
    _falseStartExpectedGates = state.registeredGatesCount > 0 ? state.registeredGatesCount : 1;
    bleService.send('RESET');
    bleService.send(state.firmwareModeCommand);
    bleService.send('SETUP');
    emit(state.copyWith(
      phase: RunTestPhase.reArming,
      clearLastTrialResult: true,
      registeredGatesCount: 0,
      allGatesReady: false,
    ));
  }

  // ── Queue builders ─────────────────────────────────────────────────────────

  List<TrialQueueItem> _buildQueue() {
    final athletes = state.athletes;
    final trials = state.trialsCount;
    final queue = <TrialQueueItem>[];

    if (state.mode == 'shuttle') {
      if (state.trialMode == 'round_robin') {
        for (int t = 1; t <= trials; t++) {
          for (int i = 0; i < athletes.length; i++) {
            queue.add(TrialQueueItem(
              athleteId: athletes[i].id,
              athleteName: athletes[i].fullName,
              trialNumber: t,
              shuttleLane: (i % 3) + 1,
            ));
          }
        }
      } else {
        for (int i = 0; i < athletes.length; i++) {
          for (int t = 1; t <= trials; t++) {
            queue.add(TrialQueueItem(
              athleteId: athletes[i].id,
              athleteName: athletes[i].fullName,
              trialNumber: t,
              shuttleLane: (i % 3) + 1,
            ));
          }
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
    return queue;
  }

  List<AthleteResultModel> _buildInitialResults() {
    return state.athletes.map((a) {
      return AthleteResultModel(
        athleteId: a.id,
        fullName: a.fullName,
        bib: a.bib,
        team: a.team,
        discipline: a.discipline,
        trials: const [],
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
    emit(state.copyWith(
      registeredGatesCount: 0,
      allGatesReady: false,
      gateSetupLog: const [],
      yoyoLaneStatuses: emptyLanes,
    ));
  }

  void resetSession() {
    bleService.send('RESET');
    _parser.reset();
    emit(const TimingSessionState());
  }

  @override
  Future<void> close() {
    _bleSub?.cancel();
    return super.close();
  }
}
