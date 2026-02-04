import 'package:flutter/foundation.dart';

class FootballBleMapper {
  // Helper method to log and return the command
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

  // Team Colors (RGB565 HEX)
  String setTeam1Color(int rgb565) =>
      _log("FOC1${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}");
  String setTeam2Color(int rgb565) =>
      _log("FOC2${rgb565.toRadixString(16).toUpperCase().padLeft(4, '0')}");

  // Period / Half
  String setFirstHalf() => _log("FOQ1");
  String setSecondHalf() => _log("FOQ2");

  // Extra Time
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
