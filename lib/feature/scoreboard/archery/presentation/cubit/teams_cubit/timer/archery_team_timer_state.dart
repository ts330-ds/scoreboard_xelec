enum ArcheryTeamSide { left, right }

enum ArcheryTeamTimerStatus { initial, running, paused, finished }

enum ArcheryTeamTimerPhase { prestart, main }

class ArcheryTeamTimerState {
  final int seconds;
  final int initialSeconds;
  final int leftRemainingSeconds;
  final int rightRemainingSeconds;
  final int totalRounds;
  final int currentRound;
  final ArcheryTeamSide startSide;
  final ArcheryTeamSide activeSide;
  final ArcheryTeamTimerStatus status;
  final ArcheryTeamTimerPhase phase;
  final bool isComplete;
  final int brightness;
  final int tempBrightness;

  const ArcheryTeamTimerState({
    required this.seconds,
    required this.initialSeconds,
    required this.leftRemainingSeconds,
    required this.rightRemainingSeconds,
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

  factory ArcheryTeamTimerState.initial({
    required int totalSeconds,
    int totalRounds = 1,
    ArcheryTeamSide side = ArcheryTeamSide.left,
    int brightness = 100,
  }) {
    return ArcheryTeamTimerState(
      seconds: totalSeconds,
      initialSeconds: totalSeconds,
      leftRemainingSeconds: totalSeconds,
      rightRemainingSeconds: totalSeconds,
      totalRounds: totalRounds,
      currentRound: 1,
      startSide: side,
      activeSide: side,
      status: ArcheryTeamTimerStatus.initial,
      phase: ArcheryTeamTimerPhase.main,
      isComplete: false,
      brightness: brightness,
      tempBrightness: brightness,
    );
  }

  ArcheryTeamTimerState copyWith({
    int? seconds,
    int? initialSeconds,
    int? leftRemainingSeconds,
    int? rightRemainingSeconds,
    int? totalRounds,
    int? currentRound,
    ArcheryTeamSide? startSide,
    ArcheryTeamSide? activeSide,
    ArcheryTeamTimerStatus? status,
    ArcheryTeamTimerPhase? phase,
    bool? isComplete,
    int? brightness,
    int? tempBrightness,
  }) {
    return ArcheryTeamTimerState(
      seconds: seconds ?? this.seconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      leftRemainingSeconds: leftRemainingSeconds ?? this.leftRemainingSeconds,
      rightRemainingSeconds:
          rightRemainingSeconds ?? this.rightRemainingSeconds,
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
