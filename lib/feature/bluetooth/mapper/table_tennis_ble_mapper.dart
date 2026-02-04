import 'package:flutter/foundation.dart';

class TableTennisBleMapper {
  // Helper method to log and return the command
  String _log(String command) {
    debugPrint('🏓 BLE Command: $command');
    return command;
  }

  // Team Names
  String setTeam1Name(String name) => _log("TTN1$name");
  String setTeam2Name(String name) => _log("TTN2$name");

  // Scores
  String setTeam1Score(int score) => _log("TTS1$score");
  String setTeam2Score(int score) => _log("TTS2$score");

  // Team Colors (RGB565 HEX)
  String setTeam1Color(int rgb565Hex) =>
      _log("TTC1${rgb565Hex.toRadixString(16).toUpperCase().padLeft(4, '0')}");
  String setTeam2Color(int rgb565Hex) =>
      _log("TTC2${rgb565Hex.toRadixString(16).toUpperCase().padLeft(4, '0')}");

  // Won (1-4)
  String setTeam1Won(int count) => _log("TTW$count");
  String setTeam2Won(int count) => _log("TTw$count"); // lowercase 'w'

  // Timeout (1 = Blue, 2 = Green)
  String setTeam1Timeout(int value) => _log("TTO1$value");
  String setTeam2Timeout(int value) => _log("TTO2$value");

  // Timer
  String setTimerMinutes(int minutes) => _log("TTTN$minutes");
  String startTimer() => _log("TTTS");
  String pauseTimer() => _log("TTTP");
  String resetTimer() => _log("TTTR");

  // Serve (1 = Team1, 2 = Team2)
  String setServe(int team) => _log("TTSV$team");

  // Match (1-7)
  String setMatch(int match) => _log("TTMH$match");

  // Brightness (0-255)
  String setBrightness(int value) => _log("TTBS$value");

  // Reset
  String resetScreen() => _log("TTRT");
}
