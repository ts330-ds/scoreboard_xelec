import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/trial_result_model.dart';

enum RunTestPhase {
  reArming,
  ready,
  waitingForResult,
  result,
  done,
}

enum YoYoPhase { idle, countdown, running, recovery, done }

// ── YoYo per-lane live status ─────────────────────────────────────────────────

class YoYoLaneStatus extends Equatable {
  final int laneNumber;
  final bool finishGateOk;   // setup: finish gate registered
  final bool turnGateOk;     // setup: turn gate registered
  final bool eliminated;
  final int strikes;
  final bool turnHit;        // current rep
  final bool finishHit;      // current rep
  final double? lastFinishTime;

  /// Per-lane: level & rep at which this athlete was eliminated
  final String? eliminatedAtLevel;
  final int? eliminatedAtRep;

  const YoYoLaneStatus({
    required this.laneNumber,
    this.finishGateOk = false,
    this.turnGateOk = false,
    this.eliminated = false,
    this.strikes = 0,
    this.turnHit = false,
    this.finishHit = false,
    this.lastFinishTime,
    this.eliminatedAtLevel,
    this.eliminatedAtRep,
  });

  bool get setupComplete => finishGateOk && turnGateOk;
  bool get isActive => !eliminated;

  YoYoLaneStatus copyWith({
    bool? finishGateOk,
    bool? turnGateOk,
    bool? eliminated,
    int? strikes,
    bool? turnHit,
    bool? finishHit,
    double? lastFinishTime,
    bool clearLastFinishTime = false,
    String? eliminatedAtLevel,
    int? eliminatedAtRep,
  }) {
    return YoYoLaneStatus(
      laneNumber: laneNumber,
      finishGateOk: finishGateOk ?? this.finishGateOk,
      turnGateOk: turnGateOk ?? this.turnGateOk,
      eliminated: eliminated ?? this.eliminated,
      strikes: strikes ?? this.strikes,
      turnHit: turnHit ?? this.turnHit,
      finishHit: finishHit ?? this.finishHit,
      lastFinishTime: clearLastFinishTime ? null : (lastFinishTime ?? this.lastFinishTime),
      eliminatedAtLevel: eliminatedAtLevel ?? this.eliminatedAtLevel,
      eliminatedAtRep: eliminatedAtRep ?? this.eliminatedAtRep,
    );
  }

  @override
  List<Object?> get props => [
    laneNumber, finishGateOk, turnGateOk, eliminated, strikes, turnHit, finishHit,
    lastFinishTime, eliminatedAtLevel, eliminatedAtRep,
  ];
}

// ── Trial queue item ──────────────────────────────────────────────────────────

class TrialQueueItem extends Equatable {
  final String athleteId;
  final String athleteName;
  final int trialNumber;
  final int? shuttleLane;

  const TrialQueueItem({
    required this.athleteId,
    required this.athleteName,
    required this.trialNumber,
    this.shuttleLane,
  });

  @override
  List<Object?> get props => [athleteId, trialNumber, shuttleLane];
}

// ── Main state ────────────────────────────────────────────────────────────────

class TimingSessionState extends Equatable {
  // ── Wizard step (0-6) ─────────────────────────────────────────────────────
  final int currentStep;

  // ── Step 0: Mode selection ─────────────────────────────────────────────────
  /// 'linear' | 'shuttle' | '505' | 'ttest' | 'yoyo' | ''
  final String mode;
  final String subMode;
  final String protocol;
  final double? customDistance;

  // ── YOYO config ───────────────────────────────────────────────────────────
  final int yoyoNumLanes;

  // ── Step 1: Test info ──────────────────────────────────────────────────────
  final String testName;
  final String location;
  final String notes;
  final DateTime? testDate;

  // ── Step 2: Athletes ───────────────────────────────────────────────────────
  final List<AthleteModel> athletes;
  final String trialMode;
  final int trialsCount;
  final String searchQuery;
  final String teamFilter;

  // ── Step 3: Gate setup ─────────────────────────────────────────────────────
  final int registeredGatesCount;
  final bool allGatesReady;
  final List<String> gateSetupLog;

  // ── YOYO gate setup ────────────────────────────────────────────────────────
  final List<YoYoLaneStatus> yoyoLaneStatuses;

  // ── Step 4: Run test (non-YOYO) ───────────────────────────────────────────
  final RunTestPhase phase;
  final List<TrialQueueItem> trialQueue;
  final int queueIndex;
  final List<AthleteResultModel> results;
  final TrialResultModel? lastTrialResult;
  final Map<int, TrialResultModel> shuttleBatchResults;

  // ── Step 4: Run test (YOYO) ───────────────────────────────────────────────
  final YoYoPhase yoyoPhase;
  final String yoyoCurrentLevel;
  final int yoyoCurrentRep;
  final double yoyoWindowSecs;
  final String? yoyoTestOverReason; // 'all_eliminated' | 'all_stages_cleared'

  // ── Session ID ────────────────────────────────────────────────────────────
  final String? sessionId;

  const TimingSessionState({
    this.currentStep = 0,
    this.mode = '',
    this.subMode = '',
    this.protocol = '',
    this.customDistance,
    this.yoyoNumLanes = 1,
    this.testName = '',
    this.location = '',
    this.notes = '',
    this.testDate,
    this.athletes = const [],
    this.trialMode = 'round_robin',
    this.trialsCount = 3,
    this.searchQuery = '',
    this.teamFilter = '',
    this.registeredGatesCount = 0,
    this.allGatesReady = false,
    this.gateSetupLog = const [],
    this.yoyoLaneStatuses = const [],
    this.phase = RunTestPhase.ready,
    this.trialQueue = const [],
    this.queueIndex = 0,
    this.results = const [],
    this.lastTrialResult,
    this.shuttleBatchResults = const {},
    this.yoyoPhase = YoYoPhase.idle,
    this.yoyoCurrentLevel = '',
    this.yoyoCurrentRep = 0,
    this.yoyoWindowSecs = 0,
    this.yoyoTestOverReason,
    this.sessionId,
  });

  // ── Computed ──────────────────────────────────────────────────────────────

  TrialQueueItem? get currentQueueItem =>
      queueIndex < trialQueue.length ? trialQueue[queueIndex] : null;

  AthleteModel? get currentAthlete {
    final item = currentQueueItem;
    if (item == null) return null;
    try {
      return athletes.firstWhere((a) => a.id == item.athleteId);
    } catch (_) {
      return null;
    }
  }

  int get currentTrialNumber => currentQueueItem?.trialNumber ?? 0;

  List<TrialQueueItem> get currentShuttleBatch {
    if (mode != 'shuttle') return const [];
    final batch = <TrialQueueItem>[];
    final seenLanes = <int>{};
    for (int i = queueIndex; i < trialQueue.length && batch.length < 3; i++) {
      final lane = trialQueue[i].shuttleLane ?? 1;
      if (seenLanes.contains(lane)) break;
      seenLanes.add(lane);
      batch.add(trialQueue[i]);
    }
    return batch;
  }

  bool get isShuttleBatchComplete {
    final batch = currentShuttleBatch;
    if (batch.isEmpty) return false;
    return batch.every((item) => shuttleBatchResults.containsKey(item.shuttleLane));
  }

  bool get isLastQueueItem {
    if (mode == 'shuttle') {
      final batchSize = currentShuttleBatch.length;
      return queueIndex + batchSize >= trialQueue.length;
    }
    return queueIndex >= trialQueue.length - 1;
  }

  int get totalTrials => trialQueue.length;
  int get completedTrialsCount => results.fold(0, (sum, r) => sum + r.completedTrials.length);
  double get progressPercent => totalTrials == 0 ? 0 : completedTrialsCount / totalTrials;

  AthleteResultModel? resultFor(String athleteId) {
    try {
      return results.firstWhere((r) => r.athleteId == athleteId);
    } catch (_) {
      return null;
    }
  }

  List<AthleteModel> get filteredAthletes {
    var list = athletes;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((a) =>
              a.fullName.toLowerCase().contains(q) ||
              a.athleteId.toLowerCase().contains(q) ||
              a.team.toLowerCase().contains(q))
          .toList();
    }
    if (teamFilter.isNotEmpty) {
      list = list.where((a) => a.team == teamFilter).toList();
    }
    return list;
  }

  Set<String> get allTeams => athletes.map((a) => a.team).toSet();

  String get modeLabel {
    if (mode == 'yoyo') return 'Yo-Yo Test · $yoyoNumLanes ${yoyoNumLanes == 1 ? "lane" : "lanes"}';
    if (mode == 'shuttle') return 'Shuttle Run';
    if (mode == '505') return '505 Agility';
    if (mode == 'ttest') return 'T-Test';
    if (mode == 'linear') {
      if (subMode == 'sprint') {
        final dist = protocol == 'custom'
            ? '${customDistance?.toStringAsFixed(0) ?? '?'}m'
            : protocol;
        return 'Sprint · $dist';
      }
      if (subMode == '505') return '505 Agility';
      if (subMode == 'ttest') return 'T-Test';
    }
    return mode;
  }

  String get firmwareModeCommand {
    if (mode == 'yoyo') return 'MODE_YOYO_$yoyoNumLanes';
    if (mode == 'shuttle') return 'MODE_SHUTTLE';
    if (mode == '505' || subMode == '505') return 'MODE_505';
    if (mode == 'ttest' || subMode == 'ttest') return 'MODE_TTEST';
    return 'MODE_LINEAR';
  }

  /// Expected number of gates for the current mode + protocol.
  /// Sent as part of SETUP:N so firmware knows when registration is complete.
  int get expectedGatesCount {
    if (mode == 'yoyo') return yoyoNumLanes * 2;
    if (mode == 'shuttle') return 6; // 3 lanes × 2 gates
    if (mode == '505' || subMode == '505') return 1;
    if (mode == 'ttest' || subMode == 'ttest') return 1;
    if (mode == 'linear' && subMode == 'sprint') {
      switch (protocol) {
        case '10m':      return 2; // start + finish
        case '20m':      return 3; // start + 10m split + 20m finish
        case '30m':      return 4; // start + 10m + 20m + 30m
        case '40m':      return 5; // start + 10m + 20m + 30m + 40m
        case 'flying10': return 2; // run-up gate + flying-finish gate
        case 'flying20': return 2;
        case 'custom':   return 2; // minimum — coach adds more physically
        default:         return 2;
      }
    }
    return 2; // safe fallback
  }

  static const Map<String, Map<String, dynamic>> protocolData = {
    '10m':     {'distance': 10, 'label': '10m',       'desc': '10m sprint — acceleration from standing start'},
    '20m':     {'distance': 20, 'label': '20m',       'desc': '20m sprint — common acceleration test'},
    '30m':     {'distance': 30, 'label': '30m',       'desc': '30m sprint — acceleration and early velocity'},
    '40m':     {'distance': 40, 'label': '40m',       'desc': '40m sprint — NFL combine standard'},
    'flying10':{'distance': 10, 'label': 'Flying 10m','desc': 'Flying 10m — max velocity zone'},
    'flying20':{'distance': 20, 'label': 'Flying 20m','desc': 'Flying 20m — max velocity over longer zone'},
    'custom':  {'distance': 0,  'label': 'Custom',    'desc': 'Custom distance'},
  };

  TimingSessionState copyWith({
    int? currentStep,
    String? mode,
    String? subMode,
    String? protocol,
    double? customDistance,
    bool clearCustomDistance = false,
    int? yoyoNumLanes,
    String? testName,
    String? location,
    String? notes,
    DateTime? testDate,
    bool clearDate = false,
    List<AthleteModel>? athletes,
    String? trialMode,
    int? trialsCount,
    String? searchQuery,
    String? teamFilter,
    int? registeredGatesCount,
    bool? allGatesReady,
    List<String>? gateSetupLog,
    List<YoYoLaneStatus>? yoyoLaneStatuses,
    RunTestPhase? phase,
    List<TrialQueueItem>? trialQueue,
    int? queueIndex,
    List<AthleteResultModel>? results,
    TrialResultModel? lastTrialResult,
    bool clearLastTrialResult = false,
    Map<int, TrialResultModel>? shuttleBatchResults,
    YoYoPhase? yoyoPhase,
    String? yoyoCurrentLevel,
    int? yoyoCurrentRep,
    double? yoyoWindowSecs,
    String? yoyoTestOverReason,
    bool clearYoyoTestOverReason = false,
    String? sessionId,
  }) {
    return TimingSessionState(
      currentStep: currentStep ?? this.currentStep,
      mode: mode ?? this.mode,
      subMode: subMode ?? this.subMode,
      protocol: protocol ?? this.protocol,
      customDistance: clearCustomDistance ? null : (customDistance ?? this.customDistance),
      yoyoNumLanes: yoyoNumLanes ?? this.yoyoNumLanes,
      testName: testName ?? this.testName,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      testDate: clearDate ? null : (testDate ?? this.testDate),
      athletes: athletes ?? this.athletes,
      trialMode: trialMode ?? this.trialMode,
      trialsCount: trialsCount ?? this.trialsCount,
      searchQuery: searchQuery ?? this.searchQuery,
      teamFilter: teamFilter ?? this.teamFilter,
      registeredGatesCount: registeredGatesCount ?? this.registeredGatesCount,
      allGatesReady: allGatesReady ?? this.allGatesReady,
      gateSetupLog: gateSetupLog ?? this.gateSetupLog,
      yoyoLaneStatuses: yoyoLaneStatuses ?? this.yoyoLaneStatuses,
      phase: phase ?? this.phase,
      trialQueue: trialQueue ?? this.trialQueue,
      queueIndex: queueIndex ?? this.queueIndex,
      results: results ?? this.results,
      lastTrialResult: clearLastTrialResult ? null : (lastTrialResult ?? this.lastTrialResult),
      shuttleBatchResults: shuttleBatchResults ?? this.shuttleBatchResults,
      yoyoPhase: yoyoPhase ?? this.yoyoPhase,
      yoyoCurrentLevel: yoyoCurrentLevel ?? this.yoyoCurrentLevel,
      yoyoCurrentRep: yoyoCurrentRep ?? this.yoyoCurrentRep,
      yoyoWindowSecs: yoyoWindowSecs ?? this.yoyoWindowSecs,
      yoyoTestOverReason: clearYoyoTestOverReason ? null : (yoyoTestOverReason ?? this.yoyoTestOverReason),
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  List<Object?> get props => [
    currentStep, mode, subMode, protocol, customDistance, yoyoNumLanes,
    testName, location, notes, testDate,
    athletes, trialMode, trialsCount, searchQuery, teamFilter,
    registeredGatesCount, allGatesReady, gateSetupLog, yoyoLaneStatuses,
    phase, trialQueue, queueIndex, results, lastTrialResult, shuttleBatchResults,
    yoyoPhase, yoyoCurrentLevel, yoyoCurrentRep, yoyoWindowSecs, yoyoTestOverReason,
    sessionId,
  ];
}
