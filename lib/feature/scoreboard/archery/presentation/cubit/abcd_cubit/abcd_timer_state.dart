import 'package:equatable/equatable.dart';

enum AbcdTimerStatus { initial, running, paused, finished }

enum AbcdTimerPhase { prestart, main }

enum AbcdRoundPhase { sighter, scoring }

enum AbcdRoundView { sighter, scoring }

class AbcdTimerState extends Equatable {
  final int seconds;
  final int initialSeconds;
  final int totalSighterRounds;
  final int totalScoringRounds;
  final int currentSighterRound;
  final int currentScoringRound;
  final AbcdRoundPhase roundPhase;
  final AbcdRoundView selectedRoundView;
  final AbcdTimerStatus status;
  final AbcdTimerPhase phase;
  final bool isComplete;
  final int brightness;
  final int tempBrightness;

  const AbcdTimerState({
    required this.seconds,
    required this.initialSeconds,
    required this.totalSighterRounds,
    required this.totalScoringRounds,
    required this.currentSighterRound,
    required this.currentScoringRound,
    required this.roundPhase,
    required this.selectedRoundView,
    required this.status,
    required this.phase,
    required this.isComplete,
    required this.brightness,
    required this.tempBrightness,
  });

  factory AbcdTimerState.initial({
    required int totalSeconds,
    int sighterRounds = 0,
    int scoringRounds = 6,
  }) {
    final startPhase = sighterRounds > 0
        ? AbcdRoundPhase.sighter
        : AbcdRoundPhase.scoring;
    final startView = sighterRounds > 0
        ? AbcdRoundView.sighter
        : AbcdRoundView.scoring;
    return AbcdTimerState(
      seconds: totalSeconds,
      initialSeconds: totalSeconds,
      totalSighterRounds: sighterRounds,
      totalScoringRounds: scoringRounds,
      currentSighterRound: 1,
      currentScoringRound: 1,
      roundPhase: startPhase,
      selectedRoundView: startView,
      status: AbcdTimerStatus.initial,
      phase: AbcdTimerPhase.main,
      isComplete: false,
      brightness: 220,
      tempBrightness: 220,
    );
  }

  AbcdTimerState copyWith({
    int? seconds,
    int? initialSeconds,
    int? totalSighterRounds,
    int? totalScoringRounds,
    int? currentSighterRound,
    int? currentScoringRound,
    AbcdRoundPhase? roundPhase,
    AbcdRoundView? selectedRoundView,
    AbcdTimerStatus? status,
    AbcdTimerPhase? phase,
    bool? isComplete,
    int? brightness,
    int? tempBrightness,
  }) {
    return AbcdTimerState(
      seconds: seconds ?? this.seconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      totalSighterRounds: totalSighterRounds ?? this.totalSighterRounds,
      totalScoringRounds: totalScoringRounds ?? this.totalScoringRounds,
      currentSighterRound: currentSighterRound ?? this.currentSighterRound,
      currentScoringRound: currentScoringRound ?? this.currentScoringRound,
      roundPhase: roundPhase ?? this.roundPhase,
      selectedRoundView: selectedRoundView ?? this.selectedRoundView,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      isComplete: isComplete ?? this.isComplete,
      brightness: brightness ?? this.brightness,
      tempBrightness: tempBrightness ?? this.tempBrightness,
    );
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
    selectedRoundView,
    status,
    phase,
    isComplete,
    brightness,
    tempBrightness,
  ];
}
