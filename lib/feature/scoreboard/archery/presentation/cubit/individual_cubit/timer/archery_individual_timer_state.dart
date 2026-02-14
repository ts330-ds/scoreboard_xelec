enum ArcheryIndividualSide { left, right }

enum ArcheryIndividualTimerStatus { initial, running, paused, finished }

enum ArcheryIndividualTimerPhase { prestart, main }

class ArcheryIndividualTimerState {
  final int seconds;
  final int initialSeconds;
  final int totalRounds;
  final int currentRound;
  final ArcheryIndividualSide startSide;
  final ArcheryIndividualSide activeSide;
  final ArcheryIndividualTimerStatus status;
  final ArcheryIndividualTimerPhase phase;
  final bool isComplete;
  final int brightness;
  final int tempBrightness;

  const ArcheryIndividualTimerState({
    required this.seconds,
    required this.initialSeconds,
    required this.totalRounds,
    required this.currentRound,
    required this.startSide,
    required this.activeSide,
    required this.status,
    required this.phase,
    required this.isComplete,
    required this.brightness,
    required this.tempBrightness,
  });

  factory ArcheryIndividualTimerState.initial({
    required int totalSeconds,
    int totalRounds = 1,
    ArcheryIndividualSide side = ArcheryIndividualSide.left,
    int brightness = 100,
  }) {
    return ArcheryIndividualTimerState(
      seconds: totalSeconds,
      initialSeconds: totalSeconds,
      totalRounds: totalRounds,
      currentRound: 1,
      startSide: side,
      activeSide: side,
      status: ArcheryIndividualTimerStatus.initial,
      phase: ArcheryIndividualTimerPhase.main,
      isComplete: false,
      brightness: brightness,
      tempBrightness: brightness,
    );
  }

  ArcheryIndividualTimerState copyWith({
    int? seconds,
    int? initialSeconds,
    int? totalRounds,
    int? currentRound,
    ArcheryIndividualSide? startSide,
    ArcheryIndividualSide? activeSide,
    ArcheryIndividualTimerStatus? status,
    ArcheryIndividualTimerPhase? phase,
    bool? isComplete,
    int? brightness,
    int? tempBrightness,
  }) {
    return ArcheryIndividualTimerState(
      seconds: seconds ?? this.seconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      totalRounds: totalRounds ?? this.totalRounds,
      currentRound: currentRound ?? this.currentRound,
      startSide: startSide ?? this.startSide,
      activeSide: activeSide ?? this.activeSide,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      isComplete: isComplete ?? this.isComplete,
      brightness: brightness ?? this.brightness,
      tempBrightness: tempBrightness ?? this.tempBrightness,
    );
  }
}
