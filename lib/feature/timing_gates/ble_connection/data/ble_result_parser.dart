import 'package:xelex_esp/feature/timing_gates/session/data/model/trial_result_model.dart';

/// Parses tagged lines from the master firmware.
/// Supports: LINEAR | SHUTTLE | T_TEST | AGILITY_505 | YOYO
class BleResultParser {
  final _linearSplits = <double>[];
  final _shuttleSplits = <int, List<double>>{};

  void Function(ParsedResult result)? onResult;
  void Function(BleEvent event)? onEvent;

  void feed(String rawLine) {
    final line = rawLine.trim();
    if (line.isEmpty) return;
    _parseLine(line);
  }

  void reset() {
    _linearSplits.clear();
    _shuttleSplits.clear();
  }

  void _parseLine(String line) {
    // ── SPLIT lines ──────────────────────────────────────────────────────────
    if (line.startsWith('[SPLIT]:LINEAR:')) {
      final m = RegExp(r'\[SPLIT\]:LINEAR:GATE:\d+:TIME:([\d.]+)').firstMatch(line);
      if (m != null) _linearSplits.add(double.parse(m.group(1)!));
      return;
    }
    if (line.startsWith('[SPLIT]:SHUTTLE:')) {
      final m = RegExp(r'\[SPLIT\]:SHUTTLE:LANE:(\d+):SPLIT:\d+:TIME:([\d.]+)').firstMatch(line);
      if (m != null) {
        final lane = int.parse(m.group(1)!);
        _shuttleSplits.putIfAbsent(lane, () => []).add(double.parse(m.group(2)!));
      }
      return;
    }

    // ── RESULT lines ─────────────────────────────────────────────────────────
    if (line.startsWith('[RESULT]:LINEAR:')) {
      final m = RegExp(r'\[RESULT\]:LINEAR:TOTAL:([\d.]+)').firstMatch(line);
      if (m != null) {
        final splits = List<double>.from(_linearSplits);
        _linearSplits.clear();
        onResult?.call(ParsedResult(mode: 'linear', totalTime: double.parse(m.group(1)!), splits: splits));
      }
      return;
    }
    if (line.startsWith('[RESULT]:T_TEST:')) {
      final m = RegExp(r'\[RESULT\]:T_TEST:TOTAL:([\d.]+)').firstMatch(line);
      if (m != null) onResult?.call(ParsedResult(mode: 'ttest', totalTime: double.parse(m.group(1)!), splits: []));
      return;
    }
    if (line.startsWith('[RESULT]:AGILITY_505:')) {
      final m = RegExp(r'\[RESULT\]:AGILITY_505:TOTAL:([\d.]+)').firstMatch(line);
      if (m != null) onResult?.call(ParsedResult(mode: '505', totalTime: double.parse(m.group(1)!), splits: []));
      return;
    }
    if (line.startsWith('[RESULT]:SHUTTLE:')) {
      final m = RegExp(r'\[RESULT\]:SHUTTLE:LANE:(\d+):TOTAL:([\d.]+)').firstMatch(line);
      if (m != null) {
        final lane = int.parse(m.group(1)!);
        final splits = List<double>.from(_shuttleSplits[lane] ?? []);
        _shuttleSplits.remove(lane);
        onResult?.call(ParsedResult(mode: 'shuttle', totalTime: double.parse(m.group(2)!), splits: splits, lane: lane));
      }
      return;
    }

    // ── YOYO lines ───────────────────────────────────────────────────────────
    if (line.startsWith('[YOYO]:')) {
      final event = _parseYoYo(line);
      if (event != null) onEvent?.call(event);
      return;
    }

    // ── EVENT / STATE / SETUP lines ──────────────────────────────────────────
    final event = _parseEvent(line);
    if (event != null) onEvent?.call(event);
  }

  // ── YOYO parser ─────────────────────────────────────────────────────────────

  BleEvent? _parseYoYo(String line) {
    // [YOYO]:SETUP:LANE:1:GATE_FINISH:ID:1:REGISTERED
    // [YOYO]:SETUP:LANE:1:GATE_TURN:ID:2:REGISTERED
    final gateReg = RegExp(
      r'\[YOYO\]:SETUP:LANE:(\d+):GATE_(FINISH|TURN):ID:(\d+):REGISTERED',
    ).firstMatch(line);
    if (gateReg != null) {
      return BleEvent(
        type: BleEventType.yoyoGateRegistered,
        lane: int.parse(gateReg.group(1)!),
        isFinishGate: gateReg.group(2) == 'FINISH',
        gateId: int.parse(gateReg.group(3)!),
        raw: line,
      );
    }

    // [YOYO]:SETUP:NEED_6_GATES:TRIGGER_FINISH_GATE_FIRST_THEN_TURN_PER_LANE
    if (line.contains('SETUP:NEED_')) {
      return BleEvent(type: BleEventType.setupActive, message: line, raw: line);
    }

    // [YOYO]:SETUP:COMPLETE:LANES:2:TOTAL_GATES:4:READY_TO_START
    if (line.contains('SETUP:COMPLETE')) {
      return BleEvent(type: BleEventType.yoyoSetupComplete, raw: line);
    }

    // [YOYO]:STARTING:LANES:2:COUNTDOWN:5s:ARM_WILL_FIRE_AT_REP_1_START
    if (line.startsWith('[YOYO]:STARTING:')) {
      return BleEvent(type: BleEventType.yoyoCountdown, raw: line);
    }

    // [YOYO]:REP_START:LEVEL:5.0:REP:1:WINDOW:14.0s:ACTIVE_LANES:2
    final repStart = RegExp(
      r'\[YOYO\]:REP_START:LEVEL:([\d.]+):REP:(\d+):WINDOW:([\d.]+)s:ACTIVE_LANES:(\d+)',
    ).firstMatch(line);
    if (repStart != null) {
      return BleEvent(
        type: BleEventType.yoyoRepStart,
        level: repStart.group(1),
        rep: int.parse(repStart.group(2)!),
        windowSecs: double.parse(repStart.group(3)!),
        activeLanes: int.parse(repStart.group(4)!),
        raw: line,
      );
    }

    // [YOYO]:LANE:1:TURN_HIT
    final turnHit = RegExp(r'\[YOYO\]:LANE:(\d+):TURN_HIT').firstMatch(line);
    if (turnHit != null) {
      return BleEvent(
        type: BleEventType.yoyoTurnHit,
        lane: int.parse(turnHit.group(1)!),
        raw: line,
      );
    }

    // [YOYO]:LANE:1:FINISH_HIT:TIME:5.23s
    final finishHit = RegExp(r'\[YOYO\]:LANE:(\d+):FINISH_HIT:TIME:([\d.]+)s').firstMatch(line);
    if (finishHit != null) {
      return BleEvent(
        type: BleEventType.yoyoFinishHit,
        lane: int.parse(finishHit.group(1)!),
        finishTime: double.parse(finishHit.group(2)!),
        raw: line,
      );
    }

    // [YOYO]:REP_END:LEVEL:5.0:REP:1
    final repEnd = RegExp(r'\[YOYO\]:REP_END:LEVEL:([\d.]+):REP:(\d+)').firstMatch(line);
    if (repEnd != null) {
      return BleEvent(
        type: BleEventType.yoyoRepEnd,
        level: repEnd.group(1),
        rep: int.parse(repEnd.group(2)!),
        raw: line,
      );
    }

    // [YOYO]:LANE:1:RESULT:PASS:TIME:5.23s:ALLOWED:14.0s:STRIKES:0
    final resultPass = RegExp(
      r'\[YOYO\]:LANE:(\d+):RESULT:PASS:TIME:([\d.]+)s:ALLOWED:([\d.]+)s:STRIKES:(\d+)',
    ).firstMatch(line);
    if (resultPass != null) {
      return BleEvent(
        type: BleEventType.yoyoLaneResult,
        lane: int.parse(resultPass.group(1)!),
        yoyoResult: 'pass',
        finishTime: double.parse(resultPass.group(2)!),
        strikes: int.parse(resultPass.group(4)!),
        raw: line,
      );
    }

    // [YOYO]:LANE:1:RESULT:ELIMINATED:LEVEL:5.0:REP:1:REASON:2_STRIKES
    final resultElim = RegExp(
      r'\[YOYO\]:LANE:(\d+):RESULT:ELIMINATED:LEVEL:([\d.]+):REP:(\d+)',
    ).firstMatch(line);
    if (resultElim != null) {
      return BleEvent(
        type: BleEventType.yoyoLaneResult,
        lane: int.parse(resultElim.group(1)!),
        yoyoResult: 'eliminated',
        level: resultElim.group(2),
        rep: int.parse(resultElim.group(3)!),
        raw: line,
      );
    }

    // [YOYO]:LANE:1:RESULT:MISS:STRIKE:1_OF_2:LEVEL:5.0:REP:1
    final resultMiss = RegExp(
      r'\[YOYO\]:LANE:(\d+):RESULT:MISS:STRIKE:(\d+)_OF_2',
    ).firstMatch(line);
    if (resultMiss != null) {
      return BleEvent(
        type: BleEventType.yoyoLaneResult,
        lane: int.parse(resultMiss.group(1)!),
        yoyoResult: 'miss',
        strikes: int.parse(resultMiss.group(2)!),
        raw: line,
      );
    }

    // [YOYO]:LANE:1:RESULT:ALREADY_ELIMINATED
    final alreadyElim = RegExp(r'\[YOYO\]:LANE:(\d+):RESULT:ALREADY_ELIMINATED').firstMatch(line);
    if (alreadyElim != null) {
      return BleEvent(
        type: BleEventType.yoyoLaneResult,
        lane: int.parse(alreadyElim.group(1)!),
        yoyoResult: 'already_eliminated',
        raw: line,
      );
    }

    // [YOYO]:STANDINGS:LANE:1:STATUS:ELIMINATED
    // [YOYO]:STANDINGS:LANE:1:STATUS:ACTIVE:STRIKES:0
    final standings = RegExp(
      r'\[YOYO\]:STANDINGS:LANE:(\d+):STATUS:(ELIMINATED|ACTIVE)(?::STRIKES:(\d+))?',
    ).firstMatch(line);
    if (standings != null) {
      return BleEvent(
        type: BleEventType.yoyoStandings,
        lane: int.parse(standings.group(1)!),
        yoyoResult: standings.group(2)!.toLowerCase(),
        strikes: standings.group(3) != null ? int.parse(standings.group(3)!) : null,
        raw: line,
      );
    }

    // [YOYO]:RECOVERY:10s:NEXT_LEVEL:5.0:NEXT_REP:2
    final recovery = RegExp(r'\[YOYO\]:RECOVERY:10s:NEXT_LEVEL:([\d.]+):NEXT_REP:(\d+)').firstMatch(line);
    if (recovery != null) {
      return BleEvent(
        type: BleEventType.yoyoRecovery,
        level: recovery.group(1),
        rep: int.parse(recovery.group(2)!),
        raw: line,
      );
    }

    // [YOYO]:TEST_OVER:ALL_ATHLETES_ELIMINATED
    if (line.contains('TEST_OVER:ALL_ATHLETES_ELIMINATED')) {
      return BleEvent(type: BleEventType.yoyoTestOver, yoyoResult: 'all_eliminated', raw: line);
    }

    // [YOYO]:TEST_OVER:ALL_STAGES_CLEARED
    if (line.contains('TEST_OVER:ALL_STAGES_CLEARED')) {
      return BleEvent(type: BleEventType.yoyoTestOver, yoyoResult: 'all_stages_cleared', raw: line);
    }

    // Unknown YOYO message — treat as log
    return BleEvent(type: BleEventType.modeConfirmed, message: line, raw: line);
  }

  // ── Standard event parser ────────────────────────────────────────────────────

  BleEvent? _parseEvent(String line) {
    final gateMatch = RegExp(r'\[SETUP\]:GATE_(\d+)_OK').firstMatch(line);
    if (gateMatch != null) {
      return BleEvent(type: BleEventType.gateRegistered, gateId: int.parse(gateMatch.group(1)!), raw: line);
    }

    final laneStartMatch = RegExp(r'\[SETUP\]:LANE_(\d+)_START_OK').firstMatch(line);
    if (laneStartMatch != null) {
      return BleEvent(type: BleEventType.gateRegistered, lane: int.parse(laneStartMatch.group(1)!), raw: line);
    }

    final laneTurnMatch = RegExp(r'\[SETUP\]:LANE_(\d+)_TURN_OK').firstMatch(line);
    if (laneTurnMatch != null) {
      return BleEvent(type: BleEventType.gateRegistered, lane: int.parse(laneTurnMatch.group(1)!), raw: line);
    }

    if (line == '[SETUP]:ALL_LANES_CONFIGURED') return BleEvent(type: BleEventType.allGatesReady, raw: line);
    if (line == '[STATE]:SETUP_ACTIVE')          return BleEvent(type: BleEventType.setupActive, raw: line);
    if (line == '[STATE]:RACING')                return BleEvent(type: BleEventType.raceStarted, raw: line);
    if (line == '[STATE]:IDLE')                  return BleEvent(type: BleEventType.stateIdle, raw: line);
    if (line == '[SYSTEM]:RESET_SUCCESS')        return BleEvent(type: BleEventType.systemReset, raw: line);
    if (line == '[SYSTEM]:READY')                return BleEvent(type: BleEventType.systemReady, raw: line);

    if (line.startsWith('[MODE]:')) {
      return BleEvent(type: BleEventType.modeConfirmed, message: line, raw: line);
    }

    final laneStarted = RegExp(r'\[EVENT\]:LANE_(\d+)_STARTED').firstMatch(line);
    if (laneStarted != null) {
      return BleEvent(type: BleEventType.laneStarted, lane: int.parse(laneStarted.group(1)!), raw: line);
    }

    if (line.startsWith('[ERROR]:')) {
      return BleEvent(
        type: BleEventType.error,
        message: line.replaceFirst('[ERROR]:', '').replaceAll('_', ' '),
        raw: line,
      );
    }

    return null;
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class ParsedResult {
  final String mode;
  final double totalTime;
  final List<double> splits;
  final int? lane;

  const ParsedResult({
    required this.mode,
    required this.totalTime,
    required this.splits,
    this.lane,
  });

  TrialResultModel toTrialResult(int trialNumber) {
    return TrialResultModel(
      trialNumber: trialNumber,
      totalTime: totalTime,
      splits: splits,
      lane: lane,
      status: 'completed',
      timestamp: DateTime.now(),
    );
  }
}

enum BleEventType {
  // Standard
  gateRegistered,
  allGatesReady,
  setupActive,
  raceStarted,
  laneStarted,
  stateIdle,
  systemReset,
  systemReady,
  modeConfirmed,
  error,
  // YOYO
  yoyoGateRegistered,
  yoyoSetupComplete,
  yoyoCountdown,
  yoyoRepStart,
  yoyoTurnHit,
  yoyoFinishHit,
  yoyoRepEnd,
  yoyoLaneResult,
  yoyoStandings,
  yoyoRecovery,
  yoyoTestOver,
}

class BleEvent {
  final BleEventType type;
  final int? gateId;
  final int? lane;
  final String? message;
  final String raw;

  // YOYO-specific fields
  final bool? isFinishGate;
  final String? level;
  final int? rep;
  final double? windowSecs;
  final int? activeLanes;
  final double? finishTime;
  final int? strikes;
  /// 'pass' | 'miss' | 'eliminated' | 'already_eliminated' | 'active'
  /// | 'all_eliminated' | 'all_stages_cleared'
  final String? yoyoResult;

  const BleEvent({
    required this.type,
    this.gateId,
    this.lane,
    this.message,
    required this.raw,
    this.isFinishGate,
    this.level,
    this.rep,
    this.windowSecs,
    this.activeLanes,
    this.finishTime,
    this.strikes,
    this.yoyoResult,
  });
}
