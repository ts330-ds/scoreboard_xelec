import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/widgets/player_main_score.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/widgets/set_cell.dart';

import '../cubit/controller/universal_game_controller_cubit.dart';
import '../cubit/controller/universal_game_controller_state.dart';

class PlayerRow extends StatelessWidget {
  final PlayerType playerType;
  final int totalSets;

  const PlayerRow({super.key, required this.playerType, required this.totalSets});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UniversalGameControllerCubit, UniversalGameControllerState, ({String name, Color color})>(
      selector: (state) => (
        name: playerType == PlayerType.player1 ? state.team1Name : state.team2Name,
        color: playerType == PlayerType.player1 ? state.team1Color : state.team2Color,
      ),
      builder: (context, playerData) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            /// LEFT : MAIN SCORE
            Expanded(
              flex: 4,
              child: BlocSelector<UniversalGameControllerCubit, UniversalGameControllerState, int>(
                selector: (state) => state.getScore(playerType, state.selectedSet),
                builder: (context, mainScore) {
                  return PlayerMainScore(
                    name: playerData.name,
                    color: playerData.color,
                    score: mainScore,
                    // future: score: mainScore
                  );
                },
              ),
            ),

            /// RIGHT : SET COLUMNS
            Expanded(
              flex: totalSets,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(totalSets, (index) {
                  final setNo = index + 1;

                  return Expanded(
                    child:
                        BlocSelector<
                          UniversalGameControllerCubit,
                          UniversalGameControllerState,
                          ({int score, bool isSelected, PlayerType? winner})
                        >(
                          selector: (state) => (
                            score: state.getScore(playerType, setNo),
                            isSelected: state.selectedSet == setNo,
                            winner: state.setWinners[setNo - 1],
                          ),
                          builder: (context, data) {
                            return SetCell(
                              setNo: setNo,
                              score: data.score.toString(),
                              color: playerData.color,
                              showTick: data.winner != null &&
                                  data.winner == playerType,
                            );
                          },
                        ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}
