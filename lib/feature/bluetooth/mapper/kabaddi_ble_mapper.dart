import 'package:flutter/foundation.dart';

class KabaddiBleMapper {
  // Helper method to log and return the command
  String _log(String command) {
    debugPrint('🤼 BLE Command: $command');
    return command;
  }

  // Team Names
  String setTeam1Name(String name) => _log("KAN1$name");
  String setTeam2Name(String name) => _log("KAN2$name");

  // Scores
  String setTeam1Score(int score) => _log("KAS1$score");
  String setTeam2Score(int score) => _log("KAS2$score");

  // Team Colors (RGB565 HEX)
  String setTeam1Color(String rgb565) => _log("KAC1$rgb565");
  String setTeam2Color(String rgb565) =>
      _log("KAC2$rgb565");

  // Quarter (1 or 2)
  String setQuarter(int quarter) => _log(quarter == 1 ? "KAQ1" : "KAQ2");

  // Timer
  String setTimerMinutes(int minutes) => _log("KATN$minutes");
  String startTimer() => _log("KATS");
  String pauseTimer() => _log("KATP");
  String resetTimer() => _log("KATR");

  // Raider Icon
  String showRaiderOnTeam1() => _log("KAR1");
  String showRaiderOnTeam2() => _log("KAR2");
  String hideRaider() => _log("KAR0");

  // Touch
  String setTeam1Touch(int value) => _log("KAT1$value");
  String setTeam2Touch(int value) => _log("KAT2$value");

  // Bonus
  String setTeam1Bonus(int value) => _log("KAB1$value");
  String setTeam2Bonus(int value) => _log("KAB2$value");

  // All Out
  String setTeam1AllOut(int value) => _log("KAA1$value");
  String setTeam2AllOut(int value) => _log("KAA2$value");

  // Raid Number
  String setRaidNumber(int raid) => _log("KARD$raid");

  // Brightness (0-255)
  String setBrightness(int value) => _log("KABS$value");

  // Reset
  String resetScreen() => _log("KART");
}
