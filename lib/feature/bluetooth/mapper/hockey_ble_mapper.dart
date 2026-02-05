import 'package:flutter/foundation.dart';

class HockeyBleMapper {
  String _log(String command) {
    debugPrint('🏑 BLE Command: $command');
    return command;
  }

  // Team Names
  String setTeam1Name(String name) => _log("HON1$name");
  String setTeam2Name(String name) => _log("HON2$name");

  // Scores
  String setTeam1Score(int score) => _log("HOS1$score");
  String setTeam2Score(int score) => _log("HOS2$score");

  // Quarter (1-4)
  String setQuarter(int quarter) => _log("HOQ$quarter");

  // Timer
  String setTimerMinutes(int minutes) => _log("HOTN$minutes");
  String startTimer() => _log("HOTS");
  String pauseTimer() => _log("HOTP");
  String resetTimer() => _log("HOTR");

  // Penalty Corners
  String setTeam1PenaltyCorner(int count) => _log("HOP1$count");
  String setTeam2PenaltyCorner(int count) => _log("HOP2$count");

  // Shoot Outs
  String setTeam1ShootOut(int count) => _log("HOO1$count");
  String setTeam2ShootOut(int count) => _log("HOO2$count");

  // Team Name Colors (RGB565 HEX)
  String setTeam1NameColor(String rgb565) => _log("HOC1$rgb565");
  String setTeam2NameColor(String rgb565) => _log("HOC2$rgb565");

  // Reset
  String resetScreen() => _log("HORT");
}