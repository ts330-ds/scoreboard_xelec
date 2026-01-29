import 'package:flutter/material.dart';
enum MatchHalf { first, second, extra }

class HandballControlState {
  final String team1Name;
  final String team2Name;

  final int team1Score;
  final int team2Score;

  final Color team1Color;
  final Color team2Color;

  final int team1Timeout;
  final int team2Timeout;

  final int team1_7m;
  final int team2_7m;

  final int team1Suspension;
  final int team2Suspension;
  final MatchHalf matchHalf;
  final int brightness; // 0 - 255
  final int tempBrightness;
  final bool buzzerOn;

  const HandballControlState({
    required this.team1Name,
    required this.team2Name,
    required this.team1Score,
    required this.team2Score,
    required this.team1Timeout,
    required this.team2Timeout,
    required this.team1_7m,
    required this.team2_7m,
    required this.team1Color,
    required this.team2Color,
    required this.team1Suspension,
    required this.team2Suspension,
    required this.matchHalf,
    required this.brightness,
    required this.tempBrightness,
    required this.buzzerOn,
  });

  factory HandballControlState.initial() {
    return const HandballControlState(
      team1Name: 'TEAM 1',
      team2Name: 'TEAM 2',
      team1Score: 0,
      team2Score: 0,
      team1Timeout: 3,
      team2Timeout: 3,
      team1_7m: 0,
      team2_7m: 0,
      team1Suspension: 0,
      team2Suspension: 0,
      matchHalf: MatchHalf.first,
      team1Color: Colors.blue, team2Color: Colors.red,
      brightness: 255,
      tempBrightness: 255,
      buzzerOn: false,
    );
  }

  HandballControlState copyWith({
    String? team1Name,
    String? team2Name,
    int? team1Score,
    int? team2Score,
    int? team1Timeout,
    int? team2Timeout,
    int? team1_7m,
    int? team2_7m,
    int? team1Suspension,
    int? team2Suspension,
    Color? team1Color,
    Color? team2Color,
    MatchHalf? matchHalf,
    int? brightness,
    int? tempBrightness,
    bool? buzzerOn,
  }) {
    return HandballControlState(
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      team1Timeout: team1Timeout ?? this.team1Timeout,
      team2Timeout: team2Timeout ?? this.team2Timeout,
      team1_7m: team1_7m ?? this.team1_7m,
      team2_7m: team2_7m ?? this.team2_7m,
      team1Suspension: team1Suspension ?? this.team1Suspension,
      team2Suspension: team2Suspension ?? this.team2Suspension,
      matchHalf: matchHalf ?? this.matchHalf,
      team1Color: team1Color ?? this.team1Color,
      team2Color: team2Color ?? this.team2Color,
      brightness: brightness ?? this.brightness,
      tempBrightness: tempBrightness ?? this.tempBrightness,
      buzzerOn: buzzerOn ?? this.buzzerOn,

    );
  }

  Map<String, dynamic> toJson() {
    return {
      "team1": {
        "name": team1Name,
        "score": team1Score,
        "timeout": team1Timeout,
        "7m": team1_7m,
        "suspension": team1Suspension,
      },
      "team2": {
        "name": team2Name,
        "score": team2Score,
        "timeout": team2Timeout,
        "7m": team2_7m,
        "suspension": team2Suspension,
      },
    };
  }
}
