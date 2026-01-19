import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/cubit/controller/table_tennis_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/cubit/controller/table_tennis_controller_state.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/widget/timeout_switch.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../../../../../common_widget/quarter_select_row.dart';
import '../../../../../utility/appColor.dart';

class TableTennisControlPanal extends StatelessWidget {
  const TableTennisControlPanal({super.key});

  @override
  Widget build(BuildContext context) {
    final controlCubit = BlocProvider.of<TableTennisControllerCubit>(context);
    return ListView(
      padding: EdgeInsets.all(5),
      children: [
        widgetGap(),
        controllerHeading(label: "Score", context: context),
        buttonGap(),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            BlocSelector<TableTennisControllerCubit, TableTennisControllerState, String>(
              selector: (state) => state.team1Name,
              builder: (context, name) {
                return Expanded(
                  child: CustomButton(
                    backgroundColor: AppColors.lakersGreen,
                    label: "${name} +",
                    onPressed: () {
                      controlCubit.incTeam1Score();
                    },
                  ),
                );
              },
            ),
            SizedBox(width: 10),
            BlocSelector<TableTennisControllerCubit, TableTennisControllerState, String>(
              selector: (state) => state.team1Name,
              builder: (context, name) {
                return Expanded(
                  child: CustomButton(
                    backgroundColor: AppColors.scoreOrange,
                    label: "${name} -",
                    onPressed: () {
                      controlCubit.decTeam1Score();
                    },
                    height: 36,
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            BlocSelector<TableTennisControllerCubit, TableTennisControllerState, String>(
              selector: (state) => state.team2Name,
              builder: (context, name) {
                return Expanded(
                  child: CustomButton(
                    backgroundColor: AppColors.lakersGreen,
                    label: "${name} +",
                    onPressed: () {
                      controlCubit.incTeam2Score();
                    },
                  ),
                );
              },
            ),
            SizedBox(width: 10),
            BlocSelector<TableTennisControllerCubit, TableTennisControllerState, String>(
              selector: (state) => state.team2Name,
              builder: (context, name) {
                return Expanded(
                  child: CustomButton(
                    backgroundColor: AppColors.scoreOrange,
                    label: "${name} -",
                    onPressed: () {
                      controlCubit.decTeam2Score();
                    },
                    height: 36,
                  ),
                );
              },
            ),
          ],
        ),

        widgetGap(),
        controllerHeading(label: "Team Won", context: context),
        buttonGap(),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            BlocSelector<TableTennisControllerCubit, TableTennisControllerState, ({String name, bool disabled})>(
              selector: (state) => (name: state.team1Name, disabled: state.roundPlayed >= state.totalGameRound),
              builder: (context, data) {
                return Expanded(
                  child: CustomButton(
                    backgroundColor: data.disabled ? Colors.grey : AppColors.lakersGreen,
                    label: "${data.name} +",
                    onPressed: data.disabled
                        ? null // 👈 disables button
                        : () {
                            controlCubit.incTeam1GamesWon();
                          },
                  ),
                );
              },
            ),
            SizedBox(width: 10),
            BlocSelector<TableTennisControllerCubit, TableTennisControllerState, String>(
              selector: (state) => state.team1Name,
              builder: (context, name) {
                return Expanded(
                  child: CustomButton(
                    backgroundColor: AppColors.scoreOrange,
                    label: "${name} -",
                    onPressed: () {
                      controlCubit.decTeam1GamesWon();
                    },
                    height: 36,
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            BlocSelector<TableTennisControllerCubit, TableTennisControllerState, ({String name, bool disabled})>(
              selector: (state) => (name: state.team2Name, disabled: state.roundPlayed >= state.totalGameRound),
              builder: (context, data) {
                return Expanded(
                  child: CustomButton(
                    backgroundColor: data.disabled ? Colors.grey : AppColors.lakersGreen,
                    label: "${data.name} +",
                    onPressed: data.disabled
                        ? null // 👈 disables button
                        : () {
                      controlCubit.incTeam2GamesWon();
                    },
                  ),
                );
              },
            ),
            SizedBox(width: 10),
            BlocSelector<TableTennisControllerCubit, TableTennisControllerState, String>(
              selector: (state) => state.team2Name,
              builder: (context, name) {
                return Expanded(
                  child: CustomButton(
                    backgroundColor: AppColors.scoreOrange,
                    label: "${name} -",
                    onPressed: () {
                      controlCubit.decTeam2GamesWon();
                    },
                    height: 36,
                  ),
                );
              },
            ),
          ],
        ),

        widgetGap(),
        controllerHeading(label: "Timeout", context: context),
        TimeoutSwitches(),

        widgetGap(),
        controllerHeading(label: "Total Round Counter", context: context),
        buttonGap(),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: CustomButton(
                backgroundColor: AppColors.lakersGreen,
                label: "+",
                onPressed: () {
                  controlCubit.incrementRoundPlayed();
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: CustomButton(
                backgroundColor: AppColors.scoreOrange,
                label: "-",
                onPressed: () {
                  controlCubit.decrementRoundPlayed();
                },
                height: 36,
              ),
            ),
          ],
        ),

        widgetGap(),
      ],
    );
  }
}
