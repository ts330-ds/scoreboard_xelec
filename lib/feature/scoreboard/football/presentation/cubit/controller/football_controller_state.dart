import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class FootballControllerState extends Equatable {
  final String team1Name;
  final String team2Name;
  final int team1Score;
  final int team2Score;
  final Color team1Color;
  final Color team2Color;
  final int extraTime;
  final int currentHalf;
  final int brightness; // 0 - 255
  final int tempBrightness;
  final bool buzzerOn;

  const FootballControllerState({
    this.team1Name = "Team 1",
    this.team2Name = "Team 2",
    this.team1Score = 0,
    this.team2Score = 0,
    this.team1Color = Colors.red,
    this.team2Color = Colors.blue,
    this.extraTime = 0,
    this.currentHalf = 1,
    this.brightness = 255,
    this.tempBrightness = 255,
    this.buzzerOn = false

  });

  FootballControllerState copyWith({
    String? team1Name,
    String? team2Name,
    int? team1Score,
    int? team2Score,
    Color? team1Color,
    Color? team2Color,
    int? extraTime,
    int? currentHalf,
    int? brightness,
    int? tempBrightness,
    bool? buzzerOn
  }) {
    return FootballControllerState(
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      team1Color: team1Color ?? this.team1Color,
      team2Color: team2Color ?? this.team2Color,
      extraTime: extraTime ?? this.extraTime,
      currentHalf: currentHalf ?? this.currentHalf,
      brightness: brightness ?? this.brightness,
      tempBrightness: tempBrightness ?? this.tempBrightness,
      buzzerOn: buzzerOn ?? this.buzzerOn
    );
  }

  @override
  List<Object?> get props => [
        team1Name,
        team2Name,
        team1Score,
        team2Score,
        team1Color,
        team2Color,
        extraTime,
        currentHalf,
        brightness,
        tempBrightness,
        buzzerOn
      ];
}
