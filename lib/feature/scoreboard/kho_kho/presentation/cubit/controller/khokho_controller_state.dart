part of 'khokho_controller_cubit.dart';

class KhokhoControllerState extends Equatable {
  final String team1Name;
  final String team2Name;
  final int team1Score;
  final int team2Score;
  final int inn;
  final int turn;
  final String matchTime;
  final bool isTeam1Chasing;
  final Color team1Color;
  final Color team2Color;
  final int brightness; // 0 - 255
  final int tempBrightness;
  final bool buzzerOn;


  const KhokhoControllerState({
    this.team1Name = "Team 1",
    this.team2Name = "Team 2",
    this.team1Score = 0,
    this.team2Score = 0,
    this.inn = 1,
    this.turn = 1,
    this.matchTime = "00:18",
    this.isTeam1Chasing = true,
    this.team1Color = Colors.blue,
    this.team2Color = Colors.red,
    this.brightness = 255,
    this.tempBrightness = 255,
    this.buzzerOn = false,

  });

  KhokhoControllerState copyWith({
    String? team1Name,
    String? team2Name,
    int? team1Score,
    int? team2Score,
    int? inn,
    int? turn,
    String? matchTime,
    bool? isTeam1Chasing,
    Color? team1Color,
    Color? team2Color,
    int? brightness,
    int? tempBrightness,
    bool? buzzerOn,
  }) {
    return KhokhoControllerState(
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      inn: inn ?? this.inn,
      turn: turn ?? this.turn,
      matchTime: matchTime ?? this.matchTime,
      isTeam1Chasing: isTeam1Chasing ?? this.isTeam1Chasing,
      team1Color: team1Color ?? this.team1Color,
      team2Color: team2Color ?? this.team2Color,
      brightness: brightness ?? this.brightness,
      tempBrightness: tempBrightness ?? this.tempBrightness,
      buzzerOn: buzzerOn ?? this.buzzerOn,
    );
  }

  @override
  List<Object?> get props => [
        team1Name,
        team2Name,
        team1Score,
        team2Score,
        inn,
        turn,
        matchTime,
        isTeam1Chasing,
        team1Color,
        team2Color,
        brightness,
        tempBrightness,
        buzzerOn,
      ];
}
