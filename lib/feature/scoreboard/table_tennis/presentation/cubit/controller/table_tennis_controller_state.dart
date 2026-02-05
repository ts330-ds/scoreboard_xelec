import 'package:flutter/material.dart';

class TableTennisControllerState {
  final String team1Name;
  final String team2Name;

  final Color team1Color;
  final Color team2Color;

  final int team1Score;
  final int team2Score;

  final int team1GamesWon;
  final int team2GamesWon;

  final bool team1Timeout;
  final bool team2Timeout;

  final int totalGameRound;
  final int roundPlayed; // 👈 NEW
  final int matchNumber;

  final bool gameStart;

  /// 0 = none, 1 = team1, 2 = team2
  final int servingTeam;

  final int brightness; // 0 - 255
  final int tempBrightness;
  final bool buzzerOn;

  const TableTennisControllerState({
    required this.team1Name,
    required this.team2Name,
    required this.team1Score,
    required this.team2Score,
    required this.team1Color,
    required this.team2Color,
    required this.team1GamesWon,
    required this.team2GamesWon,
    required this.team1Timeout,
    required this.team2Timeout,
    required this.totalGameRound,
    required this.roundPlayed,
    required this.matchNumber,
    this.gameStart = false,
    this.servingTeam = 1,
    this.brightness = 220,
    this.tempBrightness = 220,
    this.buzzerOn = false,
  });

  factory TableTennisControllerState.initial() {
    return const TableTennisControllerState(
      team1Name: "TEAM A",
      team2Name: "TEAM B",
      team1Score: 0,
      team2Score: 0,
      team1GamesWon: 0,
      team2GamesWon: 0,
      team1Timeout: false,
      team2Timeout: false,
      totalGameRound: 7,
      roundPlayed: 0, // 👈 start from 0
      matchNumber: 1,
      gameStart: false,
      servingTeam: 1,
      team1Color: Colors.red,
      team2Color: Colors.blue,
      brightness: 220,
      tempBrightness: 220,
      buzzerOn: false,
    );
  }

  TableTennisControllerState copyWith({
    String? team1Name,
    String? team2Name,
    int? team1Score,
    int? team2Score,
    int? team1GamesWon,
    int? team2GamesWon,
    bool? team1Timeout,
    bool? team2Timeout,
    int? totalGameRound,
    int? roundPlayed,
    int? matchNumber,
    bool? gameStart,
    int? servingTeam,
    Color? team1Color,
    Color? team2Color,
    int? brightness,
    int? tempBrightness,
    bool? buzzerOn,
  }) {
    return TableTennisControllerState(
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      team1GamesWon: team1GamesWon ?? this.team1GamesWon,
      team2GamesWon: team2GamesWon ?? this.team2GamesWon,
      team1Timeout: team1Timeout ?? this.team1Timeout,
      team2Timeout: team2Timeout ?? this.team2Timeout,
      totalGameRound: totalGameRound ?? this.totalGameRound,
      roundPlayed: roundPlayed ?? this.roundPlayed,
      matchNumber: matchNumber ?? this.matchNumber,
      gameStart: gameStart ?? this.gameStart,
      servingTeam: servingTeam ?? this.servingTeam,
      team1Color: team1Color ?? this.team1Color,
      team2Color: team2Color ?? this.team2Color,
      brightness: brightness ?? this.brightness,
      tempBrightness: tempBrightness ?? this.tempBrightness,
      buzzerOn: buzzerOn ?? this.buzzerOn,
    );
  }
}
