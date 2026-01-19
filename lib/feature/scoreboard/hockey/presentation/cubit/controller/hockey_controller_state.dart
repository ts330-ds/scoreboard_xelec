import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class HockeyControllerState extends Equatable {
  final String team1Name;
  final String team2Name;
  final int team1Score;
  final int team2Score;
  final Color team1Color;
  final Color team2Color;
  final int team1PenaltyCorner;
  final int team2PenaltyCorner;
  final int team1Shootout;
  final int team2Shootout;

  const HockeyControllerState({
    required this.team1Name,
    required this.team2Name,
    required this.team1Score,
    required this.team2Score,
    required this.team1Color,
    required this.team2Color,
    required this.team1PenaltyCorner,
    required this.team2PenaltyCorner,
    required this.team1Shootout,
    required this.team2Shootout,
  });

  factory HockeyControllerState.initial() {
    return const HockeyControllerState(
      team1Name: "Team A",
      team2Name: "Team B",
      team1Score: 0,
      team2Score: 0,
      team1Color: Colors.blue,
      team2Color: Colors.red,
      team1PenaltyCorner: 0,
      team2PenaltyCorner: 0,
      team1Shootout: 0,
      team2Shootout: 0,
    );
  }

  HockeyControllerState copyWith({
    String? team1Name,
    String? team2Name,
    int? team1Score,
    int? team2Score,
    Color? team1Color,
    Color? team2Color,
    int? team1PenaltyCorner,
    int? team2PenaltyCorner,
    int? team1Shootout,
    int? team2Shootout,
  }) {
    return HockeyControllerState(
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      team1Color: team1Color ?? this.team1Color,
      team2Color: team2Color ?? this.team2Color,
      team1PenaltyCorner: team1PenaltyCorner ?? this.team1PenaltyCorner,
      team2PenaltyCorner: team2PenaltyCorner ?? this.team2PenaltyCorner,
      team1Shootout: team1Shootout ?? this.team1Shootout,
      team2Shootout: team2Shootout ?? this.team2Shootout,
    );
  }

  @override
  List<Object?> get props => [
        team1Name,
        team2Name,
        team1Score,
        team2Score,
        team1Color,
        team2Color,
        team1PenaltyCorner,
        team2PenaltyCorner,
        team1Shootout,
        team2Shootout,
      ];

  Map<String, dynamic> toJson() => {
        "sport": "hockey",
        "team1": {
          "name": team1Name,
          "score": team1Score,
          "color": team1Color.value,
          "pc": team1PenaltyCorner,
          "shootout": team1Shootout,
        },
        "team2": {
          "name": team2Name,
          "score": team2Score,
          "color": team2Color.value,
          "pc": team2PenaltyCorner,
          "shootout": team2Shootout,
        }
      };
}
