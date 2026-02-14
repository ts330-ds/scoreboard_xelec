import 'package:flutter/foundation.dart';

class BadmintonBleMapper {
  String _log(String command) {
    debugPrint('🏸 BLE Command: $command');
    return command;
  }

  // ============== PLAYER NAMES ==============
  String setPlayer1Name(String name) => _log("BDN1$name");
  String setPlayer2Name(String name) => _log("BDN2$name");

  // ============== SERVER SIDE ==============
  // (1=player1, 2=player2)
  String setServerSide(int side) => _log("BDSR$side");

  // ============== CURRENT SCORES (used by cubit) ==============
  // These are the helper methods your cubit calls
  String setTeam1Score(int set, int score) {
    switch (set) {
      case 1:
        return setPlayer1Set1Score(score);
      case 2:
        return setPlayer1Set2Score(score);
      case 3:
        return setPlayer1Set3Score(score);
      case 4:
        return setPlayer1Set4Score(score);
      case 5:
        return setPlayer1Set5Score(score);
      default:
        return setPlayer1Set1Score(score);
    }
  }

  String setTeam2Score(int set, int score) {
    switch (set) {
      case 1:
        return setPlayer2Set1Score(score);
      case 2:
        return setPlayer2Set2Score(score);
      case 3:
        return setPlayer2Set3Score(score);
      case 4:
        return setPlayer2Set4Score(score);
      case 5:
        return setPlayer2Set5Score(score);
      default:
        return setPlayer2Set1Score(score);
    }
  }

  // ============== SET WINNERS (used by cubit) ==============
  String setSetWinner(int set, int winner) {
    switch (set) {
      case 1:
        return setSet1Winner(winner);
      case 2:
        return setSet2Winner(winner);
      case 3:
        return setSet3Winner(winner);
      case 4:
        return setSet4Winner(winner);
      case 5:
        return setSet5Winner(winner);
      default:
        return setSet1Winner(winner);
    }
  }

  // ============== SET SELECTION (used by cubit) ==============
  // Note: You need to define what BLE command selects a set
  // I'm assuming "BDSS" prefix for Set Select
  String selectSet1() => _log("BDSS1");
  String selectSet2() => _log("BDSS2");
  String selectSet3() => _log("BDSS3");


// for main score large number

String setMainScoreTeam1(int score) => _log("BDS1$score");
String setMainScoreTeam2(int score) => _log("BDS2$score");

  // ============== TOTAL SETS ==============
  String setTotalSets(int totalSets) => _log("BDTS$totalSets");

  // ============== RAW SCORE COMMANDS ==============
  // Player 1 Set Scores (Sets 1-5)
  String setPlayer1Set1Score(int score) => _log("BD1A$score");
  String setPlayer1Set2Score(int score) => _log("BD1B$score");
  String setPlayer1Set3Score(int score) => _log("BD1C$score");
  String setPlayer1Set4Score(int score) => _log("BD1D$score");
  String setPlayer1Set5Score(int score) => _log("BD1E$score");

  // Player 2 Set Scores (Sets 1-5)
  String setPlayer2Set1Score(int score) => _log("BD2A$score");
  String setPlayer2Set2Score(int score) => _log("BD2B$score");
  String setPlayer2Set3Score(int score) => _log("BD2C$score");
  String setPlayer2Set4Score(int score) => _log("BD2D$score");
  String setPlayer2Set5Score(int score) => _log("BD2E$score");

  // ============== RAW WINNER COMMANDS ==============
  // (0=none, 1=player1, 2=player2)
  String setSet1Winner(int winner) => _log("BDW1$winner");
  String setSet2Winner(int winner) => _log("BDW2$winner");
  String setSet3Winner(int winner) => _log("BDW3$winner");
  String setSet4Winner(int winner) => _log("BDW4$winner");
  String setSet5Winner(int winner) => _log("BDW5$winner");

  // ============== BUZZER ==============
  String triggerBuzzer() => _log("BDBZ");

  // ============== RESET ==============
  String resetScreen() => _log("BDRS");

  // ============== TEAM COLORS (if needed) ==============
  // Uncomment when ready to use
  // String setTeam1Color(String hexColor) => _log("BDC1$hexColor");
  // String setTeam2Color(String hexColor) => _log("BDC2$hexColor");
}