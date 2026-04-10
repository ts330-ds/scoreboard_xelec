import 'package:hive/hive.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_result_model.dart';

part 'test_session_model.g.dart';

@HiveType(typeId: 3)
class TestSessionModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sessionName;

  @HiveField(2)
  final DateTime date;

  // ── Mode ──────────────────────────────────────────────────────────────────
  /// 'linear' | 'shuttle' | '505' | 'ttest'
  @HiveField(3)
  final String mode;

  /// 'sprint' | '505' | 'ttest' | '' (empty for shuttle)
  @HiveField(4)
  final String subMode;

  /// '10m' | '20m' | '30m' | '40m' | 'flying10' | 'flying20' | 'custom' | ''
  /// Only relevant when subMode == 'sprint'
  @HiveField(5)
  final String protocol;

  /// Only used when protocol == 'custom'
  @HiveField(6)
  final double? customDistance;

  // ── Trial config ──────────────────────────────────────────────────────────
  /// 'round_robin' | 'athlete_complete'
  @HiveField(7)
  final String trialMode;

  @HiveField(8)
  final int trialsCount;

  // ── Status ────────────────────────────────────────────────────────────────
  /// 'draft' | 'in_progress' | 'completed' | 'interrupted'
  @HiveField(9)
  final String status;

  /// Position in the trial queue — used to resume an interrupted session.
  @HiveField(10)
  final int currentQueueIndex;

  // ── Athletes & Results ────────────────────────────────────────────────────
  /// Snapshot of athletes at session creation — not a live reference.
  /// Deleting an athlete from the global list will not affect this session.
  @HiveField(11)
  final List<AthleteModel> athletes;

  @HiveField(12)
  final List<AthleteResultModel> results;

  // ── Meta ──────────────────────────────────────────────────────────────────
  @HiveField(13)
  final String location;

  @HiveField(14)
  final String notes;

  @HiveField(15)
  final DateTime? completedAt;

  const TestSessionModel({
    required this.id,
    required this.sessionName,
    required this.date,
    required this.mode,
    this.subMode = '',
    this.protocol = '',
    this.customDistance,
    this.trialMode = 'round_robin',
    this.trialsCount = 3,
    this.status = 'draft',
    this.currentQueueIndex = 0,
    this.athletes = const [],
    this.results = const [],
    this.location = '',
    this.notes = '',
    this.completedAt,
  });

  // ── Computed ──────────────────────────────────────────────────────────────
  bool get isDraft => status == 'draft';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isInterrupted => status == 'interrupted';

  int get totalTrials => athletes.length * trialsCount;
  int get completedTrialsCount =>
      results.fold(0, (sum, r) => sum + r.completedTrials.length);

  double get progressPercent =>
      totalTrials == 0 ? 0 : completedTrialsCount / totalTrials;

  /// Display label e.g. "Linear · Sprint · 20m"
  bool get isYoyo => mode == 'yoyo';

  String get modeLabel {
    if (mode == 'yoyo') return 'Yo-Yo Test';
    if (mode == 'shuttle') return 'Shuttle Run';
    if (mode == '505') return '505 Agility';
    if (mode == 'ttest') return 'T-Test';
    if (subMode == 'sprint') {
      final dist = protocol == 'custom'
          ? '${customDistance?.toStringAsFixed(0) ?? '?'}m'
          : protocol;
      return 'Sprint · $dist';
    }
    if (subMode == '505') return '505 Agility';
    if (subMode == 'ttest') return 'T-Test';
    return mode;
  }

  TestSessionModel copyWith({
    String? id,
    String? sessionName,
    DateTime? date,
    String? mode,
    String? subMode,
    String? protocol,
    double? customDistance,
    String? trialMode,
    int? trialsCount,
    String? status,
    int? currentQueueIndex,
    List<AthleteModel>? athletes,
    List<AthleteResultModel>? results,
    String? location,
    String? notes,
    DateTime? completedAt,
  }) {
    return TestSessionModel(
      id: id ?? this.id,
      sessionName: sessionName ?? this.sessionName,
      date: date ?? this.date,
      mode: mode ?? this.mode,
      subMode: subMode ?? this.subMode,
      protocol: protocol ?? this.protocol,
      customDistance: customDistance ?? this.customDistance,
      trialMode: trialMode ?? this.trialMode,
      trialsCount: trialsCount ?? this.trialsCount,
      status: status ?? this.status,
      currentQueueIndex: currentQueueIndex ?? this.currentQueueIndex,
      athletes: athletes ?? this.athletes,
      results: results ?? this.results,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
