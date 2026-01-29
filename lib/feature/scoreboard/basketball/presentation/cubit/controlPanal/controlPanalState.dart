import 'package:flutter/material.dart';

class ControlPanelState {
  final String team1Name;
  final String team2Name;
  final int team1Score;
  final int team2Score;
  final Color team1Color;
  final Color team2Color;
  final int brightness; // 0 - 255
  final int tempBrightness;
  final bool buzzerOn;
  final int quarter;

  const ControlPanelState({
    required this.team1Name,
    required this.team2Name,
    required this.team1Score,
    required this.team2Score,
    required this.team1Color,
    required this.team2Color,
    required this.brightness,
    required this.tempBrightness,
    required this.buzzerOn,
    required this.quarter
  });

  factory ControlPanelState.initial() {
    return const ControlPanelState(
      team1Name: 'Team 1',
      team2Name: 'Team 2',
      team1Score: 0,
      team2Score: 0,
      team1Color: Colors.blue,
      team2Color: Colors.red,
      brightness: 255,
      tempBrightness: 255,
      buzzerOn: false,
      quarter: 1
    );
  }

  ControlPanelState copyWith({
    String? team1Name,
    String? team2Name,
    int? team1Score,
    int? team2Score,
    Color? team1Color,
    Color? team2Color,
    int? brightness,
    int? tempBrightness,
    bool? buzzerOn,
    int? quarter
  }) {
    return ControlPanelState(
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      team1Color: team1Color ?? this.team1Color,
      team2Color: team2Color ?? this.team2Color,
      brightness: brightness ?? this.brightness,
      tempBrightness: tempBrightness ?? this.tempBrightness,
      buzzerOn: buzzerOn ?? this.buzzerOn,
      quarter: quarter ?? this.quarter
    );
  }

  /// 🔥 THIS IS IMPORTANT
  Map<String, dynamic> toJson() {
    return {
      "team1_name": team1Name,
      "team2_name": team2Name,
      "team1_score": team1Score,
      "team2_score": team2Score,
      "team1_color": team1Color.value,
      "team2_color": team2Color.value,
      "brightness": brightness,
      "tempBrightness": tempBrightness,// always 0–255
      "buzzer": buzzerOn,
      "quarter": quarter
    };
  }
}
