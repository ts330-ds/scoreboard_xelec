import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

import '../cubit/controller/table_tennis_controller_cubit.dart';
import '../cubit/controller/table_tennis_controller_state.dart';

class TimeoutSwitches extends StatelessWidget {
  const TimeoutSwitches({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TableTennisControllerCubit, TableTennisControllerState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: BlocSelector<TableTennisControllerCubit, TableTennisControllerState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Text(name,style: context.text.headlineMedium,);
                },
              ),
              value: state.team1Timeout,
              onChanged: (_) {
                context.read<TableTennisControllerCubit>().toggleTeam1Timeout();
              },
            ),

            SwitchListTile(
              title: BlocSelector<TableTennisControllerCubit, TableTennisControllerState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Text(name,style: context.text.headlineMedium,);
                },
              ),
              value: state.team2Timeout,
              onChanged: (_) {
                context.read<TableTennisControllerCubit>().toggleTeam2Timeout();
              },
            ),
          ],
        );
      },
    );
  }
}
