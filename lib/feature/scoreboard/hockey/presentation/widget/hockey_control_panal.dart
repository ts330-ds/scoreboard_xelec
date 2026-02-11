import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/cubit/controller/hockey_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/cubit/controller/hockey_controller_state.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../../../../../common_widget/brightness_slider_widget.dart';
import '../../../../../common_widget/buzzerWidget.dart';
import '../../../../../common_widget/quarter_select_row.dart';
import '../../../../../service/dependency_injection/di_service.dart';
import '../../../../../utility/appColor.dart';
import '../../../../bluetooth/service/ble_service.dart';
import '../cubit/timer/hockey_timer_cubit.dart';
import '../cubit/timer/hockey_timer_state.dart';

class HockeyControlPanal extends StatelessWidget {
  const HockeyControlPanal({super.key});

  @override
  Widget build(BuildContext context) {
    final controlCubit = context.read<HockeyControllerCubit>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          controllerHeading(label: "Quarter", context: context),
          buttonGap(),
          BlocBuilder<HockeyTimerCubit, HockeyTimerState>(
            builder: (context, state) {
              return QuarterButtonsRow(
                selectedQuarter: state.quarter,
                onQuarterSelected: (q) {
                  context.read<HockeyTimerCubit>().setQuarter(q);
                },
              );
            },
          ),

          widgetGap(),
          controllerHeading(label: "Score", context: context),
          buttonGap(),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
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
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
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
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
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
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
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
          controllerHeading(label: "Penalty Corner", context: context),
          buttonGap(),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "$name +",
                      onPressed: () {
                        controlCubit.incTeam1PenaltyCorner();
                      },
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "$name -",
                      onPressed: () {
                        controlCubit.decTeam1PenaltyCorner();
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
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "$name +",
                      onPressed: () {
                        controlCubit.incTeam2PenaltyCorner();
                      },
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "$name -",
                      onPressed: () {
                        controlCubit.decTeam2PenaltyCorner();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
            ],
          ),

          widgetGap(),
          controllerHeading(label: "Shoot Out", context: context),
          buttonGap(),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "$name +",
                      onPressed: () {
                        controlCubit.incTeam1Shootout();
                      },
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "$name -",
                      onPressed: () {
                        controlCubit.decTeam1Shootout();
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
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "$name +",
                      onPressed: () {
                        controlCubit.incTeam2Shootout();
                      },
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              BlocSelector<HockeyControllerCubit, HockeyControllerState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "$name -",
                      onPressed: () {
                        controlCubit.decTeam2Shootout();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
            ],
          ),

          widgetGap(),
          controllerHeading(label: "Display Settings", context: context),
          widgetGap(),
          BlocSelector<HockeyControllerCubit, HockeyControllerState, int>(
            selector: (state) => state.tempbrightness,
            builder: (context, brightness) {
              return BrightnessSliderMinimal(
                value: brightness.toDouble(),
                onChanged: (value) {
                  context.read<HockeyControllerCubit>().setTempBrightness(value.toInt());
                },
                onChangedEnd: (double value) {
                  context.read<HockeyControllerCubit>().setBrightness(value.toInt());
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
