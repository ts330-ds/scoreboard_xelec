import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/widget/round_dot_widget.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

import '../cubit/controller/table_tennis_controller_cubit.dart';
import '../cubit/controller/table_tennis_controller_state.dart';
class TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: const Color(0xFF0A2A66),
      child: Row(
        children: [
          BlocSelector<TableTennisControllerCubit, TableTennisControllerState, int>(
            selector: (state) => state.roundPlayed,
              builder: (context,data) {
              return Text(
                "MATCH ${data}",
                style: context.text.headlineMedium!.copyWith(color: context.colors.surface),
              );
            }
          ),
          const Spacer(),
          RoundDots(),
          const Spacer(),
        
        ],
      ),
    );
  }
}
