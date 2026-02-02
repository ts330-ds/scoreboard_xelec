import 'package:flutter/material.dart';

enum PlayerType {
  player1,
  player2,
}

enum TotalSets {
  three,
  five;

  int get count => this == TotalSets.three ? 3 : 5;
}

class UniversalGameControllerState {
  final TotalSets totalSets;     // three or five
  final int selectedSet;         // 1..totalSets.count
  final PlayerType activePlayer; // player1 / player2

  // Team info
  final String team1Name;
  final String team2Name;
  final Color team1Color;
  final Color team2Color;

  // Always keep length = 5
  final List<int> p1Scores;
  final List<int> p2Scores;
  final List<PlayerType?> setWinners;

  const UniversalGameControllerState({
    required this.totalSets,
    required this.selectedSet,
    required this.activePlayer,
    required this.team1Name,
    required this.team2Name,
    required this.team1Color,
    required this.team2Color,
    required this.p1Scores,
    required this.p2Scores,
    this.setWinners = const [],
  });

  factory UniversalGameControllerState.initial() {
    return const UniversalGameControllerState(
      totalSets: TotalSets.three,
      selectedSet: 1,
      activePlayer: PlayerType.player1,
      team1Name: 'Player 1',
      team2Name: 'Player 2',
      team1Color: Colors.green,
      team2Color: Colors.red,
      p1Scores: [0, 0, 0, 0, 0],
      p2Scores: [0, 0, 0, 0, 0],
      setWinners: [null, null, null, null, null],
    );
  }

  UniversalGameControllerState copyWith({
    TotalSets? totalSets,
    int? selectedSet,
    PlayerType? activePlayer,
    String? team1Name,
    String? team2Name,
    Color? team1Color,
    Color? team2Color,
    List<int>? p1Scores,
    List<int>? p2Scores,
    List<PlayerType?>? setWinners,
  }) {
    return UniversalGameControllerState(
      totalSets: totalSets ?? this.totalSets,
      selectedSet: selectedSet ?? this.selectedSet,
      activePlayer: activePlayer ?? this.activePlayer,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Color: team1Color ?? this.team1Color,
      team2Color: team2Color ?? this.team2Color,
      p1Scores: p1Scores ?? this.p1Scores,
      p2Scores: p2Scores ?? this.p2Scores,
      setWinners: setWinners ?? this.setWinners,
    );
  }

  // ---- UI helpers ----
  int get maxSets => totalSets.count;

  int getScore(PlayerType player, int setNo) {
    final i = setNo - 1;
    return player == PlayerType.player1 ? p1Scores[i] : p2Scores[i];
  }

}
