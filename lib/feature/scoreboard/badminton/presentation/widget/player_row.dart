import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/cubit/controller/badminton_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/player_info_section.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/setUiModel.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/set_column.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/widget/vertical_divider.dart';

import '../cubit/controller/badminton_controller_state.dart';

class PlayerRow extends StatelessWidget {
  final PlayerType playerType;

  const PlayerRow({
    super.key,
    required this.playerType,
  });

  PlayerType? _mapWinnerToPlayer(int winner) {
    if (winner == 1) return PlayerType.player1;
    if (winner == 2) return PlayerType.player2;
    return null; // no winner yet
  }

  int getTeamScore(
      BadmintonControllerState state,
      bool isTeam1,
      ) {
    switch (state.selectedSet) {
      case 1:
        return isTeam1 ? state.t1s1 : state.t2s1;
      case 2:
        return isTeam1 ? state.t1s2 : state.t2s2;
      case 3:
        return isTeam1 ? state.t1s3 : state.t2s3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      child: Row(
        children: [
          BlocBuilder<BadmintonControllerCubit, BadmintonControllerState>(
            builder: (context,data) {

              return PlayerInfoSection(
                playerName: playerType == PlayerType.player1
                    ? data.team1Name: data.team2Name,
                scoreColor: playerType == PlayerType.player1
                    ? data.team1Color: data.team2Color,
                isServe: playerType == PlayerType.player1
                    ? data.isTeam1Serve: data.isTeam2Serve,
                score:getTeamScore(data, playerType == PlayerType.player1?true:false)

              );
            }
          ),
        BlocSelector<BadmintonControllerCubit,
            BadmintonControllerState, ({int score, Color color, bool showTrick})>(
          selector: (state) {
            final winner =
            _mapWinnerToPlayer(state.set1Winner);
            return (
            score: playerType == PlayerType.player1
                ? state.t1s1
                : state.t2s1,
            color: playerType == PlayerType.player1
                ? state.team1Color
                : state.team2Color,
            showTrick: winner == playerType,
            );
          },
          builder: (context, data) {
            return SetColumn(
              title: "S1",
              score: data.score,
              color: data.color,
              showTick: data.showTrick
            );
          },
        ),

          BlocSelector<BadmintonControllerCubit,
              BadmintonControllerState, ({int score, Color color, bool showTrick})>(
            selector: (state) {
              final winner =
              _mapWinnerToPlayer(state.set2Winner);
              return (
              score: playerType == PlayerType.player1
                  ? state.t1s2
                  : state.t2s2,
              color: playerType == PlayerType.player1
                  ? state.team1Color
                  : state.team2Color,
              showTrick: winner == playerType,
              );
            },
            builder: (context, data) {
              return SetColumn(
                  title: "S2",
                  score: data.score,
                  color: data.color,
                  showTick: data.showTrick
              );
            },
          ),

          BlocSelector<BadmintonControllerCubit,
              BadmintonControllerState, ({int score, Color color, bool showTrick})>(
            selector: (state) {
              final winner =
              _mapWinnerToPlayer(state.set3Winner);
              return (
              score: playerType == PlayerType.player1
                  ? state.t1s3
                  : state.t2s3,
              color: playerType == PlayerType.player1
                  ? state.team1Color
                  : state.team2Color,
              showTrick: winner == playerType,
              );
            },
            builder: (context, data) {
              return SetColumn(
                  title: "S3",
                  score: data.score,
                  color: data.color,
                  showTick: data.showTrick
              );
            },
          ),


        ],
      ),
    );
  }
}
