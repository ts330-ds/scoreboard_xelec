import '../alternate_game_controller/archery_alternate_game_controller_state.dart';

enum AlternateTimerStatus { initial, running, paused, finished }

enum AlternateTimerPhase { prestart, main }

class ArcheryAlternateGameTimerState {
  final int seconds;
  final int initialSeconds;
  final int leftRemainingSeconds;
  final int rightRemainingSeconds;
  final ArcheryAlternateSide activeSide;
  final ArcheryGameMode gameMode;
  final AlternateTimerStatus status;
  final AlternateTimerPhase phase;

  const ArcheryAlternateGameTimerState({
    required this.seconds,
    required this.initialSeconds,
    required this.leftRemainingSeconds,
    required this.rightRemainingSeconds,
    required this.activeSide,
    required this.gameMode,
    required this.status,
    required this.phase,
  });

  factory ArcheryAlternateGameTimerState.initial(int totalSeconds) {
    return ArcheryAlternateGameTimerState(
      seconds: totalSeconds,
      initialSeconds: totalSeconds,
      leftRemainingSeconds: totalSeconds,
      rightRemainingSeconds: totalSeconds,
      activeSide: ArcheryAlternateSide.left,
      gameMode: ArcheryGameMode.simple,
      status: AlternateTimerStatus.initial,
      phase: AlternateTimerPhase.main,
    );
  }

  ArcheryAlternateGameTimerState copyWith({
    int? seconds,
    int? initialSeconds,
    int? leftRemainingSeconds,
    int? rightRemainingSeconds,
    ArcheryAlternateSide? activeSide,
    ArcheryGameMode? gameMode,
    AlternateTimerStatus? status,
    AlternateTimerPhase? phase,
  }) {
    return ArcheryAlternateGameTimerState(
      seconds: seconds ?? this.seconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      leftRemainingSeconds: leftRemainingSeconds ?? this.leftRemainingSeconds,
      rightRemainingSeconds:
          rightRemainingSeconds ?? this.rightRemainingSeconds,
      activeSide: activeSide ?? this.activeSide,
      gameMode: gameMode ?? this.gameMode,
      status: status ?? this.status,
      phase: phase ?? this.phase,
    );
  }
}
