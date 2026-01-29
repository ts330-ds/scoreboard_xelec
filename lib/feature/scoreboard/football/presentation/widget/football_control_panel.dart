import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/common_widget/controller_heading.dart';
import 'package:xelex_esp/feature/scoreboard/football/presentation/cubit/controller/football_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/football/presentation/cubit/controller/football_controller_state.dart';
import 'package:xelex_esp/feature/scoreboard/football/presentation/cubit/timer/football_timer_cubit.dart';
import 'package:xelex_esp/utility/appColor.dart';
import 'package:xelex_esp/utility/universal_method.dart';

class FootballControlPanel extends StatelessWidget {
  const FootballControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controlCubit = context.read<FootballControllerCubit>();
    final timerCubit = context.read<FootballTimerCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ControllerHeading(text: "Timer"),
          const SizedBox(height: 6),
          BlocBuilder<FootballTimerCubit, FootballTimerState>(
            builder: (context, state) {
              return Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: state.status == FootballTimerStatus.inProgress ? "Pause" : (state.status == FootballTimerStatus.paused ? "Resume" : "Start"),
                      backgroundColor: state.status == FootballTimerStatus.inProgress ? Colors.orange : Colors.green,
                      onPressed: () {
                        if (state.status == FootballTimerStatus.inProgress) {
                          timerCubit.pauseTimer();
                        } else {
                          timerCubit.startTimer();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      label: "Reset",
                      backgroundColor: Colors.blueGrey,
                      onPressed: () => timerCubit.resetTimer(),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          const ControllerHeading(text: "Score"),
          const SizedBox(height: 6),
          Row(
            children: [
              BlocSelector<FootballControllerCubit, FootballControllerState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "$name +",
                      onPressed: () => controlCubit.incrementTeam1Score(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              BlocSelector<FootballControllerCubit, FootballControllerState, String>(
                selector: (state) => state.team1Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "$name -",
                      onPressed: () => controlCubit.decrementTeam1Score(),
                      height: 36,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              BlocSelector<FootballControllerCubit, FootballControllerState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "$name +",
                      onPressed: () => controlCubit.incrementTeam2Score(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              BlocSelector<FootballControllerCubit, FootballControllerState, String>(
                selector: (state) => state.team2Name,
                builder: (context, name) {
                  return Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "$name -",
                      onPressed: () => controlCubit.decrementTeam2Score(),
                      height: 36,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
          const ControllerHeading(text: "Extra Time"),
          const SizedBox(height: 6),
          BlocBuilder<FootballControllerCubit, FootballControllerState>(
            builder: (context, state) {
              return Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.lakersGreen,
                      label: "Extra Time +",
                      onPressed: () => controlCubit.incrementExtraTime(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      backgroundColor: AppColors.scoreOrange,
                      label: "Extra Time -",
                      onPressed: () => controlCubit.decrementExtraTime(),
                      height: 36,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          const ControllerHeading(text: "Match Half"),
          const SizedBox(height: 6),
          BlocBuilder<FootballControllerCubit, FootballControllerState>(
            builder: (context, state) {
              return Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("1st Half")),
                      selected: state.currentHalf == 1,
                      onSelected: (val) => controlCubit.setHalf(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("2nd Half")),
                      selected: state.currentHalf == 2,
                      onSelected: (val) => controlCubit.setHalf(2),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          const ControllerHeading(text: "Display Settings"),


          BlocSelector<FootballControllerCubit, FootballControllerState, int>(
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
                            .read<FootballControllerCubit>()
                            .setBrightness((value * 255).toInt());
                      }, onChanged: (value) {
                      context
                          .read<FootballControllerCubit>()
                          .setTempBrightness((value * 255).toInt());
                    },
                    ),
                  ),
                ],
              );
            },
          ),


          BlocSelector<FootballControllerCubit, FootballControllerState, bool>(
              selector: (state) => state.buzzerOn,
              builder: (context,buzzer) {
                return SwitchListTile(title: const ControllerHeading(text: "Buzzer"), value: buzzer, onChanged: (value) {
                  context.read<FootballControllerCubit>().toggleBuzzer();
                });
              }
          ),


        ],
      ),
    );
  }
}
