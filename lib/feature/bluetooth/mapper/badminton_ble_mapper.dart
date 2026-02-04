import 'package:flutter/foundation.dart';

class BadmintonBleMapper {
  // Helper method to log and return the command
  String _log(String command) {
    debugPrint('🏸 BLE Command: $command');
    return command;
  }

  // MODE
  String enterBadmintonMode() => _log("BD");

  // TEAM NAMES
  String setTeam1Name(String name) => _log("BDN1$name");
  String setTeam2Name(String name) => _log("BDN2$name");

  // TEAM COLORS (RGB565 HEX)
  String setTeam1Color(String hex565) => _log("BDC1$hex565");
  String setTeam2Color(String hex565) => _log("BDC2$hex565");

  // SET SELECT
  String selectSet1() => _log("BDS1");
  String selectSet2() => _log("BDS2");
  String selectSet3() => _log("BDS3");

  // SET BrightNess
  String setBrightness(int value) => _log("BDBS:$value");

  // SCORES
  String setTeam1Score(int set, int score) => _log("BDS${set}A$score");
  String setTeam2Score(int set, int score) => _log("BDS${set}B$score");

  // SET WINNER (0 = clear, 1 = team1, 2 = team2)
  String setSetWinner(int set, int winner) => _log("BDW$set$winner");

  // RESET
  String resetMatch() => _log("BDRT");
}
