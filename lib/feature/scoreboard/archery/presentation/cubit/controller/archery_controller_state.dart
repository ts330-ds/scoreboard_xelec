part of 'archery_controller_cubit.dart';

enum ArcheryMode { abcd, abc, abCd }

enum MatchPhase { sighter, scoring, completed }

class ArcheryControllerState extends Equatable {
  final ArcheryMode mode;
  final int practiceEnds; // Sighter ends
  final int scoringEnds;
  final int greenTime;

  final MatchPhase matchPhase;
  final int currentEndNumber;
  final String currentTeam; // 'AB' or 'CD' for AB-CD mode

  final bool isMatchComplete;
  final bool isPracticeSkipped;

  final bool isIdleScreen; // Show time/date or game screen

  final int brightness;
  final int setTempBrightness;
  final bool buzzerOn;

  const ArcheryControllerState({
    this.mode = ArcheryMode.abcd,
    this.practiceEnds = 0,
    this.scoringEnds = 6,
    this.greenTime = 90,
    this.matchPhase = MatchPhase.sighter,
    this.currentEndNumber = 1,
    this.currentTeam = 'AB',
    this.isMatchComplete = false,
    this.isPracticeSkipped = false,
    this.isIdleScreen = true,
    this.brightness = 220,
    this.setTempBrightness = 220,
    this.buzzerOn = true,
  });

  int get totalEnds =>
      matchPhase == MatchPhase.sighter ? practiceEnds : scoringEnds;

  String get phaseLabel =>
      matchPhase == MatchPhase.sighter ? 'SIGHTER' : 'SCORING';

  List<String> get allPlayers {
    switch (mode) {
      case ArcheryMode.abcd:
        return ['A', 'B', 'C', 'D'];
      case ArcheryMode.abc:
        return ['A', 'B', 'C'];
      case ArcheryMode.abCd:
        return ['A', 'B', 'C', 'D'];
    }
  }

  List<String> get activePlayers {
    switch (mode) {
      case ArcheryMode.abcd:
        return ['A', 'B', 'C', 'D'];
      case ArcheryMode.abc:
        return ['A', 'B', 'C'];
      case ArcheryMode.abCd:
        return currentTeam == 'AB' ? ['A', 'B'] : ['C', 'D'];
    }
  }

  bool isPlayerActive(String player) {
    return activePlayers.contains(player);
  }

  ArcheryControllerState copyWith({
    ArcheryMode? mode,
    int? practiceEnds,
    int? scoringEnds,
    int? greenTime,
    MatchPhase? matchPhase,
    int? currentEndNumber,
    String? currentTeam,
    bool? isMatchComplete,
    bool? isPracticeSkipped,
    bool? isIdleScreen,
    int? brightness,
    int? setTempBrightness,
    bool? buzzerOn,

  }) {
    return ArcheryControllerState(
      mode: mode ?? this.mode,
      practiceEnds: practiceEnds ?? this.practiceEnds,
      scoringEnds: scoringEnds ?? this.scoringEnds,
      greenTime: greenTime ?? this.greenTime,
      matchPhase: matchPhase ?? this.matchPhase,
      currentEndNumber: currentEndNumber ?? this.currentEndNumber,
      currentTeam: currentTeam ?? this.currentTeam,
      isMatchComplete: isMatchComplete ?? this.isMatchComplete,
      isPracticeSkipped: isPracticeSkipped ?? this.isPracticeSkipped,
      isIdleScreen: isIdleScreen ?? this.isIdleScreen,
      brightness: brightness ?? this.brightness,
      buzzerOn: buzzerOn ?? this.buzzerOn,
      setTempBrightness: setTempBrightness ?? this.setTempBrightness,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        practiceEnds,
        scoringEnds,
        greenTime,
        matchPhase,
        currentEndNumber,
        currentTeam,
        isMatchComplete,
        isPracticeSkipped,
        isIdleScreen,
        brightness,
        buzzerOn,
        setTempBrightness,
      ];
}
