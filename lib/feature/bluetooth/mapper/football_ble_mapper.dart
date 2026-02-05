import 'package:flutter/foundation.dart';

class FootballBleMapper {
  String _log(String command) {
    debugPrint('⚽ BLE Command: $command');
    return command;
  }

  // Team Names
  String setTeam1Name(String name) => _log("FON1$name");
  String setTeam2Name(String name) => _log("FON2$name");

  // Scores
  String setTeam1Score(int score) => _log("FOS1$score");
  String setTeam2Score(int score) => _log("FOS2$score");

  // Team Name Colors (RGB565 HEX)
  String setTeam1NameColor(String rgb565) => _log("FOC1$rgb565");
  String setTeam2NameColor(String rgb565) => _log("FOC2$rgb565");

  // Period (1 or 2)
  String setPeriod(int period) => _log(period == 1 ? "FOQ1" : "FOQ2");

  // Extra Time Text (e.g., "+2'")
  String setExtraTime(String text) => _log("FOET$text");

  // Timer
  String setTimerMinutes(int minutes) => _log("FOTN$minutes");
  String startTimer() => _log("FOTS");
  String pauseTimer() => _log("FOTP");
  String resetTimer() => _log("FOTR");

  // Brightness (0-255)
  String setBrightness(int value) => _log("FOBS$value");

  // Reset
  String resetScreen() => _log("FORT");
}