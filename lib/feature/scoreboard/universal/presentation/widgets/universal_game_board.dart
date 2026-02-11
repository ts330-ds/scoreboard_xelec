import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/cubit/controller/universal_game_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/widgets/player_row.dart';

import '../cubit/controller/universal_game_controller_state.dart';

class UniversalGameBoard extends StatelessWidget {
  const UniversalGameBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UniversalGameControllerCubit, UniversalGameControllerState, int>(
      selector: (state) => state.maxSets,
      builder: (context, totalSets) {
        return Container(
          padding: const EdgeInsets.all(4),
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// PLAYER 1 ROW
              PlayerRow(
                playerType: PlayerType.player1,
                totalSets: totalSets,
              ),

              const Divider(
                color: Colors.orange,
                thickness: 2,
                height: 2,
              ),

              /// PLAYER 2 ROW
              PlayerRow(
                playerType: PlayerType.player2,
                totalSets: totalSets,
              ),
            ],
          ),
        );
      },
    );
  }
}
