import 'package:flutter/foundation.dart';

class TableTennisBleMapper {
  String _log(String command) {
    debugPrint('🏓 BLE Command: $command');
    return command;
  }

  // Player Names
  String setPlayer1Name(String name) => _log("TTN1$name");
  String setPlayer2Name(String name) => _log("TTN2$name");

  // Scores
  String setPlayer1Score(int score) => _log("TTS1$score");
  String setPlayer2Score(int score) => _log("TTS2$score");

  // Background Colors (RGB565 HEX)
  String setPlayer1BgColor(String rgb565) => _log("TTC1$rgb565");
  String setPlayer2BgColor(String rgb565) => _log("TTC2$rgb565");

  // Games Won (1-4)
  String setPlayer1GamesWon(int count) => _log("TTW$count");
  String setPlayer2GamesWon(int count) => _log("TTw$count");

  // Timeout (1=available/blue, 2=used/green)
  String setPlayer1Timeout(int state) => _log("TTO1$state");
  String setPlayer2Timeout(int state) => _log("TTO2$state");

  // Timer
  String setTimerMinutes(int minutes) => _log("TTTN$minutes");
  String startTimer() => _log("TTTS");
  String pauseTimer() => _log("TTTP");
  String resetTimer() => _log("TTTR");

  // Serving (1=player1, 2=player2, 0=none)
  String setServing(int side) => _log("TTSV$side");

  // Match Number
  String setMatchNumber(int matchNum) => _log("TTMH$matchNum");

  // Brightness (0-255)
  String setBrightness(int value) => _log("TTBS$value");

  // Reset
  String resetScreen() => _log("TTRT");
}