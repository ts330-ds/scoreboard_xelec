import 'package:flutter/foundation.dart';

class HandBallBleMapper {
  // Helper method to log and return the command
  String _log(String command) {
    debugPrint('🤾 BLE Command: $command');
    return command;
  }

  // Team Names
  String setTeam1Name(String name) => _log("HBN1$name");
  String setTeam2Name(String name) => _log("HBN2$name");

  // Scores
  String setTeam1Score(int score) => _log("HBS1$score");
  String setTeam2Score(int score) => _log("HBS2$score");

  // Quarters (1-4)
  String setQuarter1() => _log("HBQ1");
  String setQuarter2() => _log("HBQ2");
  String setQuarter3() => _log("HBQ3");
  String setQuarter4() => _log("HBQ4");
  String setQuarter(int q) => _log("HBQ$q");

  // Timer
  String setTimerMinutes(int minutes) => _log("HBTN$minutes");
  String startTimer() => _log("HBTS");
  String pauseTimer() => _log("HBTP");
  String resetTimer() => _log("HBTR");

  // Timeout (Team 1: HBO1, HBO2, HBO3)
  String setTeam1Timeout1() => _log("HBO1");
  String setTeam1Timeout2() => _log("HBO2");
  String setTeam1Timeout3() => _log("HBO3");
  String setTeam1Timeout(int count) => _log("HBO$count");

  // Timeout (Team 2: HBo1, HBo2, HBo3) - lowercase 'o'
  String setTeam2Timeout1() => _log("HBo1");
  String setTeam2Timeout2() => _log("HBo2");
  String setTeam2Timeout3() => _log("HBo3");
  String setTeam2Timeout(int count) => _log("HBo$count");

  // 7 Meter
  String setTeam1SevenMeter(int value) => _log("HBSM$value");
  String setTeam2SevenMeter(int value) => _log("HBSm$value");

  // Suspension (1 = Red, 2 = Green)
  String setTeam1Suspension(int value) => _log("HBU1$value");
  String setTeam2Suspension(int value) => _log("HBU2$value");

  // Reset
  String resetScreen() => _log("HBRT");

  // NOTE: Brightness & Buzzer NOT supported in Handball firmware
}
