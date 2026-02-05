import 'package:flutter/foundation.dart';

class BasketBallBleMapper {
  String _log(String command) {
    debugPrint('🏀 BLE Command: $command');
    return command;
  }

  // Team Names
  String setTeam1Name(String name) => _log("BBN1$name");
  String setTeam2Name(String name) => _log("BBN2$name");

  // Scores
  String setTeam1Score(int score) => _log("BBS1$score");
  String setTeam2Score(int score) => _log("BBS2$score");

  // Team Colors (RGB565 HEX)
  String setTeam1Color(String rgb565) => _log("BBC1$rgb565");
  String setTeam2Color(String rgb565) => _log("BBC2$rgb565");

  // Quarter (1-4)
  String setQuarter(int quarter) => _log("BBQ$quarter");

  // Timer
  String setTimerMinutes(int minutes) => _log("BBTN$minutes");
  
  String setTime(int totalSeconds) {
    final mm = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return _log("BBTT$mm");
  }
  String startTimer() => _log("BBTS");
  String pauseTimer() => _log("BBTP");
  String resetTimer() => _log("BBTR");

  // Shot Clock
  String startShotClock() => _log("BBMS");
  String resetShotClock() => _log("BBMR");

  // Reset
  String resetScreen() => _log("BBRT");
}
