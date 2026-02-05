import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/widget/serve_icon.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/widget/time_out_widget.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/widget/win_row_widget.dart';
import 'package:xelex_esp/utility/theme_extension.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../cubit/controller/table_tennis_controller_cubit.dart';
import '../cubit/controller/table_tennis_controller_state.dart';

class TableTennisTeamPanel extends StatelessWidget {
  final bool isTeam1;

  const TableTennisTeamPanel({
    super.key,
    required this.isTeam1,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// ================= MAIN PANEL =================
        BlocSelector<
            TableTennisControllerCubit,
            TableTennisControllerState,
            ({String name, Color color})>(
          selector: (state) {
            return isTeam1
                ? (name: state.team1Name, color: state.team1Color)
                : (name: state.team2Name, color: state.team2Color);
          },
          builder: (context, team) {
            final (:name, :color) = team; // 👈 Dart pattern

            return Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isTeam1?Colors.blue:Colors.red, // ✅ reactive background color
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  widgetGap(),
                  /// Team name
                  Text(
                    name,
                    style: context.text.titleMedium!
                        .copyWith(color: color),
                  ),

                  buttonGap(),

                  /// Score
                  BlocSelector<TableTennisControllerCubit,
                      TableTennisControllerState, int>(
                    selector: (state) =>
                    isTeam1 ? state.team1Score : state.team2Score,
                    builder: (context, score) {
                      return Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 8),
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F2F2F),
                          borderRadius: BorderRadius.circular(16),
                          border:
                          Border.all(color: Colors.blueGrey),
                        ),
                        child: Text(
                          formatScore(score),
                          style: context.text.titleLarge!
                              .copyWith(
                              color: context.colors.surface),
                        ),
                      );
                    },
                  ),

                  widgetGap(),

                  /// Games won
                  BlocSelector<TableTennisControllerCubit,
                      TableTennisControllerState, int>(
                    selector: (state) =>
                    isTeam1
                        ? state.team1GamesWon
                        : state.team2GamesWon,
                    builder: (context, wins) {
                      return WinRowWidget(
                        label: "Won - ",
                        wins: wins,
                        color: Colors.green,
                        context: context,
                      );
                    },
                  ),

                  buttonGap(),

                  /// Timeout
                  BlocSelector<TableTennisControllerCubit,
                      TableTennisControllerState, bool>(
                    selector: (state) =>
                    isTeam1
                        ? state.team1Timeout
                        : state.team2Timeout,
                    builder: (context, isTimeout) {
                      return TimeOutWidget(
                        label: "TO - ",
                        isTimeout: isTimeout,
                        context: context,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),

        /// ================= SERVE ICON =================
        Positioned(
          top: 6,
          right: 6,
          child: BlocBuilder<TableTennisControllerCubit,
              TableTennisControllerState>(
            buildWhen: (prev, curr) =>
            prev.servingTeam != curr.servingTeam ,
            builder: (context, state) {
              final showServe =
                  ((isTeam1 && state.servingTeam == 1) ||
                      (!isTeam1 && state.servingTeam == 2));

              return showServe
                  ?  ServeIcon()
                  :  SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
