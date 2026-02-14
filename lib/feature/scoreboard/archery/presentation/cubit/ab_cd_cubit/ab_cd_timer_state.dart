import 'package:equatable/equatable.dart';

enum AbCdTimerStatus { initial, running, paused, finished }

enum AbCdTimerPhase { prestart, main }

enum AbCdRoundPhase { sighter, scoring }

enum AbCdTeam { ab, cd }

class AbCdTimerState extends Equatable {
  final int seconds;
  final int initialSeconds;
  final int totalSighterRounds;
  final int totalScoringRounds;
  final int currentSighterRound;
  final int currentScoringRound;
  final AbCdRoundPhase roundPhase;
  final AbCdTimerStatus status;
  final AbCdTimerPhase phase;
  final bool isComplete;
  final int brightness;
  final int tempBrightness;

  // AB-CD specific fields
  final AbCdTeam currentTeam;
  final int currentTurnInRound; // 1 or 2 (first team or second team)

  const AbCdTimerState({
    required this.seconds,
    required this.initialSeconds,
    required this.totalSighterRounds,
    required this.totalScoringRounds,
    required this.currentSighterRound,
    required this.currentScoringRound,
    required this.roundPhase,
    required this.status,
    required this.phase,
    required this.isComplete,
    required this.brightness,
    required this.tempBrightness,
    required this.currentTeam,
    required this.currentTurnInRound,
  });

  factory AbCdTimerState.initial({
    required int totalSeconds,
    int sighterRounds = 0,
    int scoringRounds = 6,
  }) {
    final startPhase = sighterRounds > 0
        ? AbCdRoundPhase.sighter
        : AbCdRoundPhase.scoring;

    return AbCdTimerState(
      seconds: totalSeconds,
      initialSeconds: totalSeconds,
      totalSighterRounds: sighterRounds,
      totalScoringRounds: scoringRounds,
      currentSighterRound: 1,
      currentScoringRound: 1,
      roundPhase: startPhase,
      status: AbCdTimerStatus.initial,
      phase: AbCdTimerPhase.main,
      isComplete: false,
      brightness: 220,
      tempBrightness: 220,
      currentTeam: AbCdTeam.ab, // Round 1 always starts with AB
      currentTurnInRound: 1,
    );
  }

  AbCdTimerState copyWith({
    int? seconds,
    int? initialSeconds,
    int? totalSighterRounds,
    int? totalScoringRounds,
    int? currentSighterRound,
    int? currentScoringRound,
    AbCdRoundPhase? roundPhase,
    AbCdTimerStatus? status,
    AbCdTimerPhase? phase,
    bool? isComplete,
    int? brightness,
    int? tempBrightness,
    AbCdTeam? currentTeam,
    int? currentTurnInRound,
  }) {
    return AbCdTimerState(
      seconds: seconds ?? this.seconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      totalSighterRounds: totalSighterRounds ?? this.totalSighterRounds,
      totalScoringRounds: totalScoringRounds ?? this.totalScoringRounds,
      currentSighterRound: currentSighterRound ?? this.currentSighterRound,
      currentScoringRound: currentScoringRound ?? this.currentScoringRound,
      roundPhase: roundPhase ?? this.roundPhase,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      isComplete: isComplete ?? this.isComplete,
      brightness: brightness ?? this.brightness,
      tempBrightness: tempBrightness ?? this.tempBrightness,
      currentTeam: currentTeam ?? this.currentTeam,
      currentTurnInRound: currentTurnInRound ?? this.currentTurnInRound,
    );
  }

  /// Get which team starts first for a given round number
  /// Odd rounds (1, 3, 5...): AB starts first
  /// Even rounds (2, 4, 6...): CD starts first
  AbCdTeam getFirstTeamForRound(int roundNumber) {
    return roundNumber.isOdd ? AbCdTeam.ab : AbCdTeam.cd;
  }

  /// Get which team goes second for a given round number
  AbCdTeam getSecondTeamForRound(int roundNumber) {
    return roundNumber.isOdd ? AbCdTeam.cd : AbCdTeam.ab;
  }

  /// Get current round number based on phase
  int get currentRoundNumber {
    return roundPhase == AbCdRoundPhase.sighter
        ? currentSighterRound
        : currentScoringRound;
  }

  @override
  List<Object?> get props => [
    seconds,
    initialSeconds,
    totalSighterRounds,
    totalScoringRounds,
    currentSighterRound,
    currentScoringRound,
    roundPhase,
    status,
    phase,
    isComplete,
    brightness,
    tempBrightness,
    currentTeam,
    currentTurnInRound,
  ];
}
