import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/common_widget/controller_heading.dart';
import 'package:xelex_esp/utility/appColor.dart';

import '../../../../../utility/universal_method.dart';
import '../cubit/controller/badminton_controller_cubit.dart';
import '../cubit/controller/badminton_controller_state.dart';


class BadmintonControlPanelUI extends StatelessWidget {
  const BadmintonControlPanelUI({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // =========================
          // SET SELECTOR
          // =========================
          const ControllerHeading(text: "Set"),
          const SizedBox(height: 6),

          BlocSelector<BadmintonControllerCubit,
              BadmintonControllerState, int>(
            selector: (state) => state.selectedSet,
            builder: (context, selectedSet) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _SetButton(set: 1, selectedSet: selectedSet)),
                  Expanded(child: _SetButton(set: 2, selectedSet: selectedSet)),
                  Expanded(child: _SetButton(set: 3, selectedSet: selectedSet)),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // =========================
          // TEAM 1 SCORE
          // =========================
          BlocSelector<BadmintonControllerCubit,
              BadmintonControllerState, Color>(
            selector: (state) => state.team1Color,
            builder: (context, color) {
              return ControllerHeading(
                text: "Team 1 Score",
              );
            },
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: "+",
                  height: 36,
                  backgroundColor: AppColors.lakersGreen,
                  onPressed: () {
                    context
                        .read<BadmintonControllerCubit>()
                        .incrementTeam1();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: "-",
                  height: 36,
                  backgroundColor: AppColors.scoreOrange,
                  onPressed: () {
                    context
                        .read<BadmintonControllerCubit>()
                        .decrementTeam1();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // =========================
          // TEAM 2 SCORE
          // =========================
          BlocSelector<BadmintonControllerCubit,
              BadmintonControllerState, Color>(
            selector: (state) => state.team2Color,
            builder: (context, color) {
              return ControllerHeading(
                text: "Team 2 Score",
              );
            },
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: "+",
                  height: 36,
                  backgroundColor: AppColors.lakersGreen,
                  onPressed: () {
                    context
                        .read<BadmintonControllerCubit>()
                        .incrementTeam2();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: "-",
                  height: 36,
                  backgroundColor: AppColors.scoreOrange,
                  onPressed: () {
                    context
                        .read<BadmintonControllerCubit>()
                        .decrementTeam2();
                  },
                ),
              ),
            ],
          ),

          widgetGap(),
          BlocSelector<BadmintonControllerCubit,
              BadmintonControllerState, ServeTeam>(
            selector: (state) => state.serveTeam,
            builder: (context, serveTeam) {
              final isTeam1 = serveTeam == ServeTeam.team1;

              return GestureDetector(
                onTap: () {
                  context.read<BadmintonControllerCubit>().toggleServe();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isTeam1 ? Colors.blue : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sports_tennis,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isTeam1 ? 'Team 1 Serve' : 'Team 2 Serve',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          widgetGap(),
          // =========================
          // DISPLAY SETTINGS
          // =========================
          const ControllerHeading(text: "Display Settings"),
          const SizedBox(height: 6),

          BlocSelector<BadmintonControllerCubit, BadmintonControllerState, int>(
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
                            .read<BadmintonControllerCubit>()
                            .setBrightness((value * 255).toInt());
                      }, onChanged: (value) {
                      context
                          .read<BadmintonControllerCubit>()
                          .setTempBrightness((value * 255).toInt());
                    },
                    ),
                  ),
                ],
              );
            },
          ),


          BlocSelector<BadmintonControllerCubit, BadmintonControllerState, bool>(
              selector: (state) => state.buzzerOn,
              builder: (context,buzzer) {
                return SwitchListTile(title: const ControllerHeading(text: "Buzzer"), value: buzzer, onChanged: (value) {
                  context.read<BadmintonControllerCubit>().toggleBuzzer();
                });
              }
          ),

      ],
      ),
    );
  }
}

class _SetButton extends StatelessWidget {
  final int set;
  final int selectedSet;

  const _SetButton({
    required this.set,
    required this.selectedSet,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selectedSet == set;
    return GestureDetector(
      onTap: () {
        context.read<BadmintonControllerCubit>().selectSet(set);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.scoreOrange : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "S$set",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

