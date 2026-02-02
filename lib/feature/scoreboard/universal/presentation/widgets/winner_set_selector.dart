import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/controller/universal_game_controller_cubit.dart';
import '../cubit/controller/universal_game_controller_state.dart';

class SetWinnerSelector extends StatelessWidget {
  const SetWinnerSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 350;

        return BlocBuilder<UniversalGameControllerCubit, UniversalGameControllerState>(
          builder: (context, state) {
            return Column(
              children: List.generate(state.maxSets, (index) {
                final setNo = index + 1;
                final winner = state.setWinners[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: isCompact ? 40 : 60,
                        child: Text(
                          "S$setNo",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: _buildWinnerButton(
                          context: context,
                          label: isCompact ? "P1" : state.team1Name,
                          color: state.team1Color,
                          selected: winner == PlayerType.player1,
                          onTap: () => context
                              .read<UniversalGameControllerCubit>()
                              .setWinner(setNo, PlayerType.player1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildWinnerButton(
                          context: context,
                          label: isCompact ? "P2" : state.team2Name,
                          color: state.team2Color,
                          selected: winner == PlayerType.player2,
                          onTap: () => context
                              .read<UniversalGameControllerCubit>()
                              .setWinner(setNo, PlayerType.player2),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          padding: EdgeInsets.zero,
                          onPressed: () => context
                              .read<UniversalGameControllerCubit>()
                              .clearWinner(setNo),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  Widget _buildWinnerButton({
    required BuildContext context,
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
