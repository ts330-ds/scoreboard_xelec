import 'package:flutter/foundation.dart';

class UniversalGameBleMapper {
  // Helper method to log and return the command
  String _log(String command) {
    debugPrint('🎮 BLE Command: $command');
    return command;
  }

  /* =======================
   * Total Sets (3 or 5)
   * ======================= */
  String setTotalSets(int sets) {
    assert(sets == 3 || sets == 5);
    return _log("UGTS$sets");
  }

  /* =======================
   * Player Names
   * ======================= */
  String setPlayer1Name(String name) => _log("UGN1$name");
  String setPlayer2Name(String name) => _log("UGN2$name");

  /* =======================
   * Current Scores
   * ======================= */
  String setPlayer1Score(int score) => _log("UGS1$score");
  String setPlayer2Score(int score) => _log("UGS2$score");

  /* =======================
   * Player 1 Set Scores
   * Set 1 = A, Set 2 = B, Set 3 = C, Set 4 = D, Set 5 = E
   * ======================= */
  String setPlayer1Set1Score(int score) => _log("UG1A$score");
  String setPlayer1Set2Score(int score) => _log("UG1B$score");
  String setPlayer1Set3Score(int score) => _log("UG1C$score");
  String setPlayer1Set4Score(int score) => _log("UG1D$score");
  String setPlayer1Set5Score(int score) => _log("UG1E$score");

  /// Set Player 1 score for a specific set (1-5)
  String setPlayer1SetScore(int setNumber, int score) {
    assert(setNumber >= 1 && setNumber <= 5);
    final suffixes = ['A', 'B', 'C', 'D', 'E'];
    return _log("UG1${suffixes[setNumber - 1]}$score");
  }

  /* =======================
   * Player 2 Set Scores
   * Set 1 = A, Set 2 = B, Set 3 = C, Set 4 = D, Set 5 = E
   * ======================= */
  String setPlayer2Set1Score(int score) => _log("UG2A$score");
  String setPlayer2Set2Score(int score) => _log("UG2B$score");
  String setPlayer2Set3Score(int score) => _log("UG2C$score");
  String setPlayer2Set4Score(int score) => _log("UG2D$score");
  String setPlayer2Set5Score(int score) => _log("UG2E$score");

  /// Set Player 2 score for a specific set (1-5)
  String setPlayer2SetScore(int setNumber, int score) {
    assert(setNumber >= 1 && setNumber <= 5);
    final suffixes = ['A', 'B', 'C', 'D', 'E'];
    return _log("UG2${suffixes[setNumber - 1]}$score");
  }

  /* =======================
   * Set Winners
   * winner: 0 = none, 1 = Player1, 2 = Player2
   * ======================= */
  String setSet1Winner(int winner) => _log("UGW1$winner");
  String setSet2Winner(int winner) => _log("UGW2$winner");
  String setSet3Winner(int winner) => _log("UGW3$winner");
  String setSet4Winner(int winner) => _log("UGW4$winner");
  String setSet5Winner(int winner) => _log("UGW5$winner");

  /// Set winner for a specific set (1-5)
  /// winner: 0 = none, 1 = Player1, 2 = Player2
  String setSetWinner(int setNumber, int winner) {
    assert(setNumber >= 1 && setNumber <= 5);
    assert(winner >= 0 && winner <= 2);
    return _log("UGW$setNumber$winner");
  }

  /* =======================
   * Buzzer
   * ======================= */
  String triggerBuzzer() => _log("UGBZ");

  /* =======================
   * Reset Screen
   * ======================= */
  String resetScreen() => _log("UGRS");

  /* =======================
   * Brightness (0-255)
   * ======================= */
  String setBrightness(int value) {
    assert(value >= 0 && value <= 255);
    return _log("UGBR$value");
  }
}
