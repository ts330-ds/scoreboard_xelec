
import 'package:flutter/material.dart';

class KabaddiControllerState {
  final String team1Name;
  final String team2Name;

  final Color team1Color;
  final Color team2Color;

  final int team1Score;
  final int team2Score;

  final int team1Touch;
  final int team2Touch;

  final int team1Bonus;
  final int team2Bonus;

  final int team1AllOut;
  final int team2AllOut;

  final int raidNumber;
  final int currentQuarter;

  final bool isRaiderOnTeam1;
  final int brightness; // 0 - 255
  final int tempBrightness;
  final bool buzzerOn;

  const KabaddiControllerState({
    required this.team1Name,
    required this.team2Name,
    required this.team1Score,
    required this.team2Score,
    required this.team1Touch,
    required this.team2Touch,
    required this.team1Bonus,
    required this.team2Bonus,
    required this.team1AllOut,
    required this.team2AllOut,
    required this.raidNumber,
    required this.currentQuarter,
    required this.isRaiderOnTeam1,
    required this.team1Color,
    required this.team2Color,
    required this.brightness,
    required this.tempBrightness,
    required this.buzzerOn,
  });

  factory KabaddiControllerState.initial() {
    return  KabaddiControllerState(
      team1Name: "HOME",
      team2Name: "AWAY",
      team1Score: 0,
      team2Score: 0,
      team1Touch: 0,
      team2Touch: 0,
      team1Bonus: 0,
      team2Bonus: 0,
      team1AllOut: 0,
      team2AllOut: 0,
      raidNumber: 1,
      currentQuarter: 1,
      isRaiderOnTeam1: true,
      team1Color: Colors.blue,
      team2Color: Colors.red,
      brightness: 220,
      tempBrightness: 220,
      buzzerOn: false,
    );
  }

  KabaddiControllerState copyWith({
    String? team1Name,
    String? team2Name,
    int? team1Score,
    int? team2Score,
    int? team1Touch,
    int? team2Touch,
    int? team1Bonus,
    int? team2Bonus,
    int? team1AllOut,
    int? team2AllOut,
    int? raidNumber,
    int? currentQuarter,
    bool? isRaiderOnTeam1,
    Color? team1Color,
    Color? team2Color,
    int? brightness,
    int? tempBrightness,
    bool? buzzerOn,
  }) {
    return KabaddiControllerState(
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      team1Touch: team1Touch ?? this.team1Touch,
      team2Touch: team2Touch ?? this.team2Touch,
      team1Bonus: team1Bonus ?? this.team1Bonus,
      team2Bonus: team2Bonus ?? this.team2Bonus,
      team1AllOut: team1AllOut ?? this.team1AllOut,
      team2AllOut: team2AllOut ?? this.team2AllOut,
      raidNumber: raidNumber ?? this.raidNumber,
      currentQuarter: currentQuarter ?? this.currentQuarter,
      isRaiderOnTeam1: isRaiderOnTeam1 ?? this.isRaiderOnTeam1,
      team1Color: team1Color ?? this.team1Color,
      team2Color: team2Color ?? this.team2Color,
      brightness: brightness ?? this.brightness,
      tempBrightness: tempBrightness ?? this.tempBrightness,
      buzzerOn: buzzerOn ?? this.buzzerOn,
    );
  }
}
