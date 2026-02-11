enum ArcheryAlternateSide { left, right }

enum ArcheryGameMode { simple, alternatingFinals }

class ArcheryAlternateGameControllerState {
  final ArcheryAlternateSide activeSide;
  final int totalRounds;
  final int currentRound;
  final bool leftWonInRound;
  final bool rightWonInRound;
  final bool isComplete;
  final int brightness;
  final int setTempBrightness;
  final bool buzzerOn;
  final ArcheryGameMode gameMode;

  const ArcheryAlternateGameControllerState({
    required this.activeSide,
    required this.totalRounds,
    required this.currentRound,
    required this.leftWonInRound,
    required this.rightWonInRound,
    required this.isComplete,
    required this.gameMode,
    this.brightness = 200,
    this.setTempBrightness = 200,
    this.buzzerOn = false,
  });

  factory ArcheryAlternateGameControllerState.initial() {
    return const ArcheryAlternateGameControllerState(
      activeSide: ArcheryAlternateSide.left,
      totalRounds: 6,
      currentRound: 1,
      leftWonInRound: false,
      rightWonInRound: false,
      isComplete: false,
      gameMode: ArcheryGameMode.simple,
      brightness: 200,
      setTempBrightness: 200,
      buzzerOn: false
      );
  }

  ArcheryAlternateGameControllerState copyWith({
    ArcheryAlternateSide? activeSide,
    int? totalRounds,
    int? currentRound,
    bool? leftWonInRound,
    bool? rightWonInRound,
    bool? isComplete,
    ArcheryGameMode? gameMode,
    int? brightness,
    int? setTempBrightness,
    bool? buzzerOn,
  }) {
    return ArcheryAlternateGameControllerState(
      activeSide: activeSide ?? this.activeSide,
      totalRounds: totalRounds ?? this.totalRounds,
      currentRound: currentRound ?? this.currentRound,
      leftWonInRound: leftWonInRound ?? this.leftWonInRound,
      rightWonInRound: rightWonInRound ?? this.rightWonInRound,
      isComplete: isComplete ?? this.isComplete,
      gameMode: gameMode ?? this.gameMode,
      brightness: brightness ?? this.brightness,
      setTempBrightness: setTempBrightness ?? this.setTempBrightness,
      buzzerOn: buzzerOn ?? this.buzzerOn,
    );
  }
}
