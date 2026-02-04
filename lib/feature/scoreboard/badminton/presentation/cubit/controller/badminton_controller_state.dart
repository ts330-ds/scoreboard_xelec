import 'package:flutter/material.dart';

enum ServeTeam {
  team1,
  team2,
}

class BadmintonControllerState {
  final int selectedSet;

  final int t1s1, t2s1;
  final int t1s2, t2s2;
  final int t1s3, t2s3;

  final int set1Winner;
  final int set2Winner;
  final int set3Winner;

  final String team1Name;
  final String team2Name;

  final Color team1Color;
  final Color team2Color;

  final int brightness; // 0 - 255
  final int tempBrightness;
  final bool buzzerOn;

  /// 🏸 Serve info (ENUM)
  final ServeTeam serveTeam;

  const BadmintonControllerState({
    required this.selectedSet,
    required this.team1Name,
    required this.team2Name,
    required this.t1s1,
    required this.t2s1,
    required this.t1s2,
    required this.t2s2,
    required this.t1s3,
    required this.t2s3,
    required this.set1Winner,
    required this.set2Winner,
    required this.set3Winner,
    required this.team1Color,
    required this.team2Color,
    required this.serveTeam,
    required this.brightness,
    required this.tempBrightness,
    required this.buzzerOn,
  });

  factory BadmintonControllerState.initial() {
    return BadmintonControllerState(
      selectedSet: 1,
      team1Name: "Team 1",
      team2Name: "Team 2",
      t1s1: 0,
      t2s1: 0,
      t1s2: 0,
      t2s2: 0,
      t1s3: 0,
      t2s3: 0,
      set1Winner: 0,
      set2Winner: 0,
      set3Winner: 0,
      team1Color: Colors.blue,
      team2Color: Colors.red,
      brightness: 220,
      tempBrightness: 220,
      buzzerOn: false,

      /// Team 1 starts serving
      serveTeam: ServeTeam.team1,
    );
  }

  BadmintonControllerState copyWith({
    int? selectedSet,
    String? team1Name,
    String? team2Name,
    int? t1s1,
    int? t2s1,
    int? t1s2,
    int? t2s2,
    int? t1s3,
    int? t2s3,
    int? set1Winner,
    int? set2Winner,
    int? set3Winner,
    Color? team1Color,
    Color? team2Color,
    ServeTeam? serveTeam,
    int? brightness,
    int? tempBrightness,
    bool? buzzerOn,
  }) {
    return BadmintonControllerState(
      selectedSet: selectedSet ?? this.selectedSet,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      t1s1: t1s1 ?? this.t1s1,
      t2s1: t2s1 ?? this.t2s1,
      t1s2: t1s2 ?? this.t1s2,
      t2s2: t2s2 ?? this.t2s2,
      t1s3: t1s3 ?? this.t1s3,
      t2s3: t2s3 ?? this.t2s3,
      set1Winner: set1Winner ?? this.set1Winner,
      set2Winner: set2Winner ?? this.set2Winner,
      set3Winner: set3Winner ?? this.set3Winner,
      team1Color: team1Color ?? this.team1Color,
      team2Color: team2Color ?? this.team2Color,
      serveTeam: serveTeam ?? this.serveTeam,
      brightness: brightness ?? this.brightness,
      tempBrightness: tempBrightness ?? this.tempBrightness,
      buzzerOn: buzzerOn ?? this.buzzerOn,
    );
  }

  /// 🔹 Helper getters (VERY useful for UI)
  bool get isTeam1Serve => serveTeam == ServeTeam.team1;
  bool get isTeam2Serve => serveTeam == ServeTeam.team2;
}
