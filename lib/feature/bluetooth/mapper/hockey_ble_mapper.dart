import 'package:flutter/foundation.dart';

class HockeyBleMapper {
  // Helper method to log and return the command
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

  // Quarters (1-4)
  String setQuarter1() => _log("HOQ1");
  String setQuarter2() => _log("HOQ2");
  String setQuarter3() => _log("HOQ3");
  String setQuarter4() => _log("HOQ4");
  String setQuarter(int q) => _log("HOQ$q");

  // Timer
  String setTimerMinutes(int minutes) => _log("HOTN$minutes");
  String startTimer() => _log("HOTS");
  String pauseTimer() => _log("HOTP");
  String resetTimer() => _log("HOTR");

  // Penalty Corner
  String setTeam1PenaltyCorner(int value) => _log("HOP1$value");
  String setTeam2PenaltyCorner(int value) => _log("HOP2$value");

  // Shoot Out
  String setTeam1ShootOut(int value) => _log("HOO1$value");
  String setTeam2ShootOut(int value) => _log("HOO2$value");

  // Team Colors (RGB565 HEX)
  String setTeam1Color(String hex565) => _log("HOC1$hex565");
  String setTeam2Color(String hex565) => _log("HOC2$hex565");

  // Reset
  String resetScreen() => _log("HORT");

  // NOTE: Brightness & Buzzer NOT supported in Hockey firmware
}
