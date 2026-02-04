import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/common_widget/controller_heading.dart';
import 'package:xelex_esp/utility/appColor.dart';
import 'package:xelex_esp/utility/universal_method.dart';
import '../../../../../common_widget/brightness_slider_widget.dart';
import '../../../../../common_widget/buzzerWidget.dart';
import '../../../../../service/dependency_injection/di_service.dart';
import '../../../../bluetooth/service/ble_service.dart';
import '../cubit/controller/khokho_controller_cubit.dart';
import '../cubit/timer/khokho_timer_cubit.dart';
import '../cubit/match_timer/match_timer_cubit.dart';

class KhokhoControlPanel extends StatelessWidget {
  const KhokhoControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controlCubit = context.read<KhokhoControllerCubit>();
    final timerCubit = context.read<KhokhoTimerCubit>();
    final matchTimerCubit = context.read<MatchTimerCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ControllerHeading(text: "Game Timer"),
          const SizedBox(height: 6),
          BlocBuilder<KhokhoTimerCubit, KhokhoTimerState>(
            builder: (context, state) {
              return Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: state.status == KhokhoTimerStatus.inProgress ? "Pause" : (state.status == KhokhoTimerStatus.paused ? "Resume" : "Start"),
                      backgroundColor: state.status == KhokhoTimerStatus.inProgress ? Colors.orange : Colors.green,
                      onPressed: () {
                        if (state.status == KhokhoTimerStatus.inProgress) {
                          timerCubit.pauseTimer();
                        } else if (state.status == KhokhoTimerStatus.paused) {
                          timerCubit.resumeTimer();
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
                      onPressed: () => timerCubit.resetTimer(540),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          const ControllerHeading(text: "Match Timer"),
          const SizedBox(height: 6),
          BlocBuilder<MatchTimerCubit, MatchTimerState>(
            builder: (context, state) {
              return Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: state.status == MatchTimerStatus.inProgress ? "Pause" : (state.status == MatchTimerStatus.paused ? "Resume" : "Start"),
                      backgroundColor: state.status == MatchTimerStatus.inProgress ? Colors.orange : Colors.green,
                      onPressed: () {
                        if (state.status == MatchTimerStatus.inProgress) {
                          matchTimerCubit.stopTimer();
                        } else if (state.status == MatchTimerStatus.paused) {
                          matchTimerCubit.resumeTimer();
                        } else {
                          matchTimerCubit.startTimer();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      label: "Reset",
                      backgroundColor: Colors.blueGrey,
                      onPressed: () => matchTimerCubit.resetTimer(18),
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
              BlocSelector<KhokhoControllerCubit, KhokhoControllerState, String>(
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
              BlocSelector<KhokhoControllerCubit, KhokhoControllerState, String>(
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
              BlocSelector<KhokhoControllerCubit, KhokhoControllerState, String>(
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
              BlocSelector<KhokhoControllerCubit, KhokhoControllerState, String>(
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
          const ControllerHeading(text: "Innings & Turn"),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(child: Text("Inn.", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                child: CustomButton(
                  backgroundColor: AppColors.lakersGreen,
                  label: "+",
                  onPressed: () => controlCubit.incrementInn(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  backgroundColor: AppColors.scoreOrange,
                  label: "-",
                  onPressed: () => controlCubit.decrementInn(),
                  height: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text("Turn", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                child: CustomButton(
                  backgroundColor: AppColors.lakersGreen,
                  label: "+",
                  onPressed: () => controlCubit.incrementTurn(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  backgroundColor: AppColors.scoreOrange,
                  label: "-",
                  onPressed: () => controlCubit.decrementTurn(),
                  height: 36,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const ControllerHeading(text: "Game Actions"),
          const SizedBox(height: 6),
          CustomButton(
            backgroundColor: Colors.deepPurple,
            label: "Toggle Chase/Defend",
            onPressed: () => controlCubit.toggleChasingTeam(),
            height: 44,
          ),
          const SizedBox(height: 20),

          const ControllerHeading(text: "Display Settings"),
          widgetGap(),
          BlocSelector<KhokhoControllerCubit, KhokhoControllerState, int>(
            selector: (state) => state.tempBrightness,
            builder: (context, brightness) {
              return BrightnessSliderMinimal(
                value: brightness.toDouble(),
                onChanged: (value) {
                  context.read<KhokhoControllerCubit>().setTempBrightness(value.toInt());
                },
                onChangedEnd: (double value) {
                  context.read<KhokhoControllerCubit>().setBrightness(value.toInt());
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
