import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/common_widget/brightness_slider_widget.dart';
import 'package:xelex_esp/common_widget/buzzerWidget.dart';
import 'package:xelex_esp/common_widget/controller_heading.dart';
import 'package:xelex_esp/common_widget/quarter_select_row.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/controlPanal/controlPanalCubit.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/shot_clock/shot_clock_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/timer/basketball_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/timer/basketball_timer_state.dart';
import 'package:xelex_esp/utility/appColor.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../../../../../service/dependency_injection/di_service.dart';
import '../cubit/controlPanal/controlPanalState.dart';

class BasketBallControlPanelUI extends StatelessWidget {
  const BasketBallControlPanelUI({super.key});

  @override
  Widget build(BuildContext context) {
    final timerCubit = context.read<BasketBallTimerCubit>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ControllerHeading(text: "Quarter"),
          const SizedBox(height: 6),

          BlocBuilder<BasketBallTimerCubit, BasketBallTimerState>(
            builder: (context, state) {
              return QuarterButtonsRow(
                selectedQuarter: state.quarter,
                onQuarterSelected: (e) {
                  timerCubit.setQuarter(e);
                },
              );
            },
          ),

          const SizedBox(height: 20),

          const ControllerHeading(text: "Shot Clock"),
          const SizedBox(height: 6),

          Row(
            children: [
              CustomButton(
                onPressed: () {
                  context.read<ShotClockCubit>().start();
                },
                label: " Start ",
                backgroundColor: AppColors.lakersGreen,
                height: 40,
              ),
              const SizedBox(width: 12),
              CustomButton(
                onPressed: () {
                  context.read<ShotClockCubit>().reset();
                },
                label: " Reset ",
                backgroundColor: AppColors.scoreOrange,
                height: 40,
              ),
            ],
          ),

          const SizedBox(height: 12),

          BlocSelector<BasketControlPanelCubit, ControlPanelState, String>(
            selector: (state) => state.team1Name,
            builder: (context, team1Name) {
              return ControllerHeading(text: "$team1Name Score");
            },
          ),

          const SizedBox(height: 5),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    context.read<BasketControlPanelCubit>().incrementTeam1();
                  },
                  label: '+',
                  height: 36,
                  backgroundColor: AppColors.lakersGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    context.read<BasketControlPanelCubit>().decrementTeam1();
                  },
                  label: "-",
                  backgroundColor: AppColors.scoreOrange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          BlocSelector<BasketControlPanelCubit, ControlPanelState, String>(
            selector: (state) => state.team2Name,
            builder: (context, team2Name) {
              return ControllerHeading(text: "$team2Name Score");
            },
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    context.read<BasketControlPanelCubit>().incrementTeam2();
                  },
                  label: "+",
                  backgroundColor: AppColors.lakersGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  onPressed: () {
                    context.read<BasketControlPanelCubit>().decrementTeam2();
                  },
                  label: "-",
                  backgroundColor: AppColors.scoreOrange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const ControllerHeading(text: "Display Settings"),
          widgetGap(),
          BlocSelector<BasketControlPanelCubit, ControlPanelState, int>(
            selector: (state) => state.tempBrightness,
            builder: (context, brightness) {
              return BrightnessSliderMinimal(
                value: brightness.toDouble(),
                onChanged: (value) {
                  context.read<BasketControlPanelCubit>().setTempBrightness(
                    value.toInt(),
                  );
                },
                onChangedEnd: (double value) {
                  context.read<BasketControlPanelCubit>().setBrightness(
                    value.toInt(),
                  );
                },
              );
            },
          ),
          widgetGap(),
          Align(
            alignment: Alignment.centerRight,
            child: BuzzerButton(bleService: sl<BleService>()),
          ),
          /*BlocSelector<BasketControlPanelCubit, ControlPanelState, bool>(
            selector: (state) => state.buzzerOn,
            builder: (context,buzzer) {
              return SwitchListTile(title: const ControllerHeading(text: "Buzzer"), value: buzzer, onChanged: (value) {
                context.read<BasketControlPanelCubit>().toggleBuzzer();
              });
            }
          ),*/
        ],
      ),
    );
  }
}
