import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/common_widget/controller_heading.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/cubit/controller/hand_ball_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/widget/half_selected_row.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/widget/score_control_button.dart';
import 'package:xelex_esp/utility/appColor.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../../../../../common_widget/quarter_select_row.dart';
import '../cubit/controller/hand_ball_controller_state.dart';
import '../cubit/timer/hand_ball_timer_cubit.dart';
import '../cubit/timer/hand_ball_timer_state.dart';

class HandBallControlPanal extends StatelessWidget {
  const HandBallControlPanal({super.key});

  @override
  Widget build(BuildContext context) {
    final controlCubit = context.read<HandBallControlCubit>();
    final timerCubit = context.read<HandBallTimerCubit>();
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ControllerHeading(text: "Time Phase"),
          const SizedBox(height: 6),
      
          BlocBuilder<HandBallTimerCubit, HandBallTimerState>(
            builder: (context, state) {
              return QuarterButtonsRow(
                selectedQuarter: state.quarter,
                onQuarterSelected: (e) {
                  timerCubit.setQuarter(e);
                },
              );
            },
          ),
      
          const SizedBox(height: 12),
      
          ControllerHeading(text: "Score"),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
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
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
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
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "${name} +",
                      onPressed: () {
                        controlCubit.incTeam2Score();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
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
      
          const SizedBox(height: 12),
          ControllerHeading(text: "TimeOut"),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "${name} +",
                      onPressed: () {
                        controlCubit.incrementTeam1Timeout();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "${name} -",
                      onPressed: () {
                        controlCubit.decrementTeam1Timeout();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "${name} +",
                      onPressed: () {
                        controlCubit.incrementTeam2Timeout();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "${name} -",
                      onPressed: () {
                        controlCubit.decrementTeam2Timeout();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ControllerHeading(text: "7-Meter Throws"),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "${name} +",
                      onPressed: () {
                        controlCubit.incTeam1_7m();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "${name} -",
                      onPressed: () {
                        controlCubit.decTeam1_7m();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "${name} +",
                      onPressed: () {
                        controlCubit.incTeam2_7m();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "${name} -",
                      onPressed: () {
                        controlCubit.decTeam2_7m();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
            ],
          ),
      
          const SizedBox(height: 12),
          ControllerHeading(text: "Suspension"),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "${name} +",
                      onPressed: () {
                        controlCubit.incTeam1Suspension();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "${name} -",
                      onPressed: () {
                        controlCubit.decTeam1Suspension();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "${name} +",
                      onPressed: () {
                        controlCubit.incTeam2Suspension();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              BlocSelector<HandBallControlCubit, HandballControlState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "${name} -",
                      onPressed: () {
                        controlCubit.decTeam2Suspension();
                      },
                      height: 36,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ControllerHeading(text: "Display Settings"),

          BlocSelector<HandBallControlCubit, HandballControlState, int>(
            selector: (state) => state.tempBrightness,
            builder: (context, brightness) {
              return Row(
                children: [
                  const ControllerHeading(text: "Brightness",),
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: 1,
                      value: brightness / 255,
                      onChangeEnd: (value) {
                        context
                            .read<HandBallControlCubit>()
                            .setBrightness((value * 255).toInt());
                      }, onChanged: (value) {
                      context
                          .read<HandBallControlCubit>()
                          .setTempBrightness((value * 255).toInt());
                    },
                    ),
                  ),
                ],
              );
            },
          ),
          BlocSelector<HandBallControlCubit, HandballControlState, bool>(
              selector: (state) => state.buzzerOn,
              builder: (context,buzzer) {
                return SwitchListTile(title: const ControllerHeading(text: "Buzzer"), value: buzzer, onChanged: (value) {
                  context.read<HandBallControlCubit>().toggleBuzzer();
                });
              }
          ),

        ],
      ),
    );
  }
}
