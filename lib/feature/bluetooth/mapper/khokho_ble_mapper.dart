import 'package:flutter/foundation.dart';

class KhoKhoBleMapper {
  // Helper method to log and return the command
  String _log(String command) {
    debugPrint('🏃 BLE Command: $command');
    return command;
  }

  // Team Names
  String setTeam1Name(String name) => _log("KKN1$name");
  String setTeam2Name(String name) => _log("KKN2$name");

  // Scores
  String setTeam1Score(int score) => _log("KKS1$score");
  String setTeam2Score(int score) => _log("KKS2$score");

  // Team Colors (RGB565 HEX)
  String setTeam1Color(int rgb565) =>
      _log("KKC1${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}");
  String setTeam2Color(int rgb565) =>
      _log("KKC2${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}");

  // Chase / Defence (1 = Team1 chase, 2 = Team2 chase)
  String setChaseTeam(int team) => _log("KKCD$team");

  // Inning (1 or 2)
  String setInning(int inning) => _log("KKIN$inning");

  // Turn (1-4)
  String setTurn(int turn) => _log("KKTU$turn");

  // Turn Timer
  String setTurnMinutes(int minutes) => _log("KKTT$minutes");
  String startTurnTimer() => _log("KKTS");
  String pauseTurnTimer() => _log("KKTP");
  String resetTurnTimer() => _log("KKTR");

  // Match Timer
  String setMatchMinutes(int minutes) => _log("KKMT$minutes");
  String startMatchTimer() => _log("KKMS");
  String pauseMatchTimer() => _log("KKMP");
  String resetMatchTimer() => _log("KKMR");

  // Brightness (0-255)
  String setBrightness(int value) => _log("KKBS$value");

  // Reset
  String resetScreen() => _log("KKRT");
}
