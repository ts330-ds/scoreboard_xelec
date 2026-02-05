import 'package:flutter/foundation.dart';

class HandBallBleMapper {
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

  // Quarter (1-4)
  String setQuarter(int quarter) => _log("HBQ$quarter");

  // Timer
  String setTimerMinutes(int minutes) => _log("HBTN$minutes");
  String startTimer() => _log("HBTS");
  String pauseTimer() => _log("HBTP");
  String resetTimer() => _log("HBTR");

  // Timeouts (1-3)
  String setTeam1Timeout(int count) => _log("HBO$count");
  String setTeam2Timeout(int count) => _log("HBo$count");

  // 7-Meter
  String setTeam1SevenMeter(int count) => _log("HBSM$count");
  String setTeam2SevenMeter(int count) => _log("HBSm$count");

  // Suspension (1=red, 2=green)
  String setTeam1Suspension(int state) => _log("HBU1$state");
  String setTeam2Suspension(int state) => _log("HBU2$state");

  // Reset
  String resetScreen() => _log("HBRT");
}