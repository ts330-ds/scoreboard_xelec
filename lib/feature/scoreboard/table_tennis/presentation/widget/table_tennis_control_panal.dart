import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/cubit/controller/table_tennis_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/cubit/controller/table_tennis_controller_state.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/widget/timeout_switch.dart';
import 'package:xelex_esp/utility/theme_extension.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../../../../../common_widget/brightness_slider_widget.dart';
import '../../../../../common_widget/buzzerWidget.dart';
import '../../../../../common_widget/controller_heading.dart';
import '../../../../../service/dependency_injection/di_service.dart';
import '../../../../../utility/appColor.dart';
import '../../../../bluetooth/service/ble_service.dart';

class TableTennisControlPanal extends StatelessWidget {
  const TableTennisControlPanal({super.key});

  @override
  Widget build(BuildContext context) {
    final controlCubit = BlocProvider.of<TableTennisControllerCubit>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      label: "$name +",
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
                      label: "$name -",
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
                      label: "$name +",
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
                      label: "$name -",
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
                      label: "$name -",
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
                      label: "$name -",
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
          controllerHeading(label: "Serve", context: context),
          buttonGap(),
          BlocSelector<TableTennisControllerCubit, TableTennisControllerState,
              ({int servingTeam, String team1Name, String team2Name})>(
            selector: (state) => (
              servingTeam: state.servingTeam,
              team1Name: state.team1Name,
              team2Name: state.team2Name,
            ),
            builder: (context, data) {
              return Row(
                children: [
                  Expanded(
                    child: _ServeToggleButton(
                      label: data.team1Name,
                      isSelected: data.servingTeam == 1,
                      onPressed: () => controlCubit.setInitialServe(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ServeToggleButton(
                      label: data.team2Name,
                      isSelected: data.servingTeam == 2,
                      onPressed: () => controlCubit.setInitialServe(2),
                    ),
                  ),
                ],
              );
            },
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
          const ControllerHeading(text: "Display Settings"),
          widgetGap(),
          BlocSelector<TableTennisControllerCubit, TableTennisControllerState, int>(
            selector: (state) => state.tempBrightness,
            builder: (context, brightness) {
              return BrightnessSliderMinimal(
                value: brightness.toDouble(),
                onChanged: (value) {
                  context.read<TableTennisControllerCubit>().setTempBrightness(value.toInt());
                },
                onChangedEnd: (double value) {
                  context.read<TableTennisControllerCubit>().setBrightness(value.toInt());
                },
              );
            },
          ),
          widgetGap(),
          Align(
            alignment: Alignment.centerRight,
            child: BuzzerButton(bleService: sl<BleService>()),
          ),

        ],
      ),
    );
  }
}

class _ServeToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ServeToggleButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          isSelected ? Icons.sports_tennis : Icons.sports_tennis_outlined,
          size: 20,
          color: isSelected ? Colors.yellow : Colors.white70,
        ),
        label: Text(
          label,
          style: context.text.headlineMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.lakersGreen : Colors.grey.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isSelected
                ? const BorderSide(color: Colors.yellow, width: 2)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
