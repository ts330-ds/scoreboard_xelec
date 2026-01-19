import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/controller/table_tennis_controller_cubit.dart';
import '../cubit/controller/table_tennis_controller_state.dart';
class RoundDots extends StatelessWidget {
   // 0–7

  const RoundDots({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TableTennisControllerCubit, TableTennisControllerState>(
      builder: (context,data) {
        return Row(
          children: List.generate(data.totalGameRound, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < data.roundPlayed
                    ? Colors.yellow
                    : Colors.white24,
              ),
            );
          }),
        );
      }
    );
  }
}
