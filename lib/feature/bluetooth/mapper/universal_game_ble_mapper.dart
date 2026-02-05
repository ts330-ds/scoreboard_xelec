import 'package:flutter/foundation.dart';

class UniversalGameBleMapper {
  String _log(String command) {
    debugPrint('🎮 BLE Command: $command');
    return command;
  }

  // ============== TOTAL SETS ==============
  String setTotalSets(int totalSets) => _log("UGTS$totalSets");

  // ============== PLAYER NAMES ==============
  String setPlayer1Name(String name) => _log("UGN1$name");
  String setPlayer2Name(String name) => _log("UGN2$name");

  // ============== CURRENT SCORES ==============
  String setPlayer1Score(int score) => _log("UGS1$score");
  String setPlayer2Score(int score) => _log("UGS2$score");

  // ============== SET SCORES (Helper methods used by cubit) ==============
  String setPlayer1SetScore(int set, int score) {
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

  String setPlayer2SetScore(int set, int score) {
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

  // ============== SET WINNER (Helper method used by cubit) ==============
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

  // ============== RAW SET SCORE COMMANDS ==============
  // Player 1 Set Scores (Sets 1-5)
  String setPlayer1Set1Score(int score) => _log("UG1A$score");
  String setPlayer1Set2Score(int score) => _log("UG1B$score");
  String setPlayer1Set3Score(int score) => _log("UG1C$score");
  String setPlayer1Set4Score(int score) => _log("UG1D$score");
  String setPlayer1Set5Score(int score) => _log("UG1E$score");

  // Player 2 Set Scores (Sets 1-5)
  String setPlayer2Set1Score(int score) => _log("UG2A$score");
  String setPlayer2Set2Score(int score) => _log("UG2B$score");
  String setPlayer2Set3Score(int score) => _log("UG2C$score");
  String setPlayer2Set4Score(int score) => _log("UG2D$score");
  String setPlayer2Set5Score(int score) => _log("UG2E$score");

  // ============== RAW SET WINNER COMMANDS ==============
  // (0=none, 1=player1, 2=player2)
  String setSet1Winner(int winner) => _log("UGW1$winner");
  String setSet2Winner(int winner) => _log("UGW2$winner");
  String setSet3Winner(int winner) => _log("UGW3$winner");
  String setSet4Winner(int winner) => _log("UGW4$winner");
  String setSet5Winner(int winner) => _log("UGW5$winner");

  // ============== BUZZER ==============
  String triggerBuzzer() => _log("UGBZ");

  // ============== RESET ==============
  String resetScreen() => _log("UGRS");
}