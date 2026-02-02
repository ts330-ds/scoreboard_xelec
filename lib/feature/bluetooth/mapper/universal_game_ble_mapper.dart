class UniversalGameBleMapper {
  /* =======================
   * Total Sets (3 or 5)
   * ======================= */
  String setTotalSets(int sets) {
    assert(sets == 3 || sets == 5);
    return "UGTS$sets";
  }

  /* =======================
   * Player Names
   * ======================= */
  String setPlayer1Name(String name) => "UGN1$name";
  String setPlayer2Name(String name) => "UGN2$name";

  /* =======================
   * Current Scores
   * ======================= */
  String setPlayer1Score(int score) => "UGS1$score";
  String setPlayer2Score(int score) => "UGS2$score";

  /* =======================
   * Player 1 Set Scores
   * Set 1 = A, Set 2 = B, Set 3 = C, Set 4 = D, Set 5 = E
   * ======================= */
  String setPlayer1Set1Score(int score) => "UG1A$score";
  String setPlayer1Set2Score(int score) => "UG1B$score";
  String setPlayer1Set3Score(int score) => "UG1C$score";
  String setPlayer1Set4Score(int score) => "UG1D$score";
  String setPlayer1Set5Score(int score) => "UG1E$score";

  /// Set Player 1 score for a specific set (1-5)
  String setPlayer1SetScore(int setNumber, int score) {
    assert(setNumber >= 1 && setNumber <= 5);
    final suffixes = ['A', 'B', 'C', 'D', 'E'];
    return "UG1${suffixes[setNumber - 1]}$score";
  }

  /* =======================
   * Player 2 Set Scores
   * Set 1 = A, Set 2 = B, Set 3 = C, Set 4 = D, Set 5 = E
   * ======================= */
  String setPlayer2Set1Score(int score) => "UG2A$score";
  String setPlayer2Set2Score(int score) => "UG2B$score";
  String setPlayer2Set3Score(int score) => "UG2C$score";
  String setPlayer2Set4Score(int score) => "UG2D$score";
  String setPlayer2Set5Score(int score) => "UG2E$score";

  /// Set Player 2 score for a specific set (1-5)
  String setPlayer2SetScore(int setNumber, int score) {
    assert(setNumber >= 1 && setNumber <= 5);
    final suffixes = ['A', 'B', 'C', 'D', 'E'];
    return "UG2${suffixes[setNumber - 1]}$score";
  }

  /* =======================
   * Set Winners
   * winner: 0 = none, 1 = Player1, 2 = Player2
   * ======================= */
  String setSet1Winner(int winner) => "UGW1$winner";
  String setSet2Winner(int winner) => "UGW2$winner";
  String setSet3Winner(int winner) => "UGW3$winner";
  String setSet4Winner(int winner) => "UGW4$winner";
  String setSet5Winner(int winner) => "UGW5$winner";

  /// Set winner for a specific set (1-5)
  /// winner: 0 = none, 1 = Player1, 2 = Player2
  String setSetWinner(int setNumber, int winner) {
    assert(setNumber >= 1 && setNumber <= 5);
    assert(winner >= 0 && winner <= 2);
    return "UGW$setNumber$winner";
  }

  /* =======================
   * Buzzer
   * ======================= */
  String triggerBuzzer() => "UGBZ";

  /* =======================
   * Reset Screen
   * ======================= */
  String resetScreen() => "UGRS";

  /* =======================
   * Brightness (0-255)
   * ======================= */
  String setBrightness(int value) {
    assert(value >= 0 && value <= 255);
    return "UGBR$value";
  }
}
