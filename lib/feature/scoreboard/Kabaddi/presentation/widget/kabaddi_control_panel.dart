import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/common_widget/controller_heading.dart';
import 'package:xelex_esp/utility/appColor.dart';
import 'package:xelex_esp/utility/universal_method.dart';
import '../cubit/controller/kabaddi_controller_cubit.dart';
import '../cubit/controller/kabaddi_controller_state.dart';
import '../cubit/timer/kabaddi_timer_cubit.dart';
import '../cubit/timer/kabaddi_timer_state.dart';

class KabaddiControlPanel extends StatelessWidget {
  const KabaddiControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controlCubit = context.read<KabaddiControllerCubit>();
    final timerCubit = context.read<KabaddiTimerCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ControllerHeading(text: "Score"),
          const SizedBox(height: 6),
          Row(
            children: [
              BlocSelector<KabaddiControllerCubit, KabaddiControllerState, String>(
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
              BlocSelector<KabaddiControllerCubit, KabaddiControllerState, String>(
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
              BlocSelector<KabaddiControllerCubit, KabaddiControllerState, String>(
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
              BlocSelector<KabaddiControllerCubit, KabaddiControllerState, String>(
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
          const ControllerHeading(text: "Points Details"),
          const SizedBox(height: 6),
          _buildPointControl(
            label: "Touch",
            team1Value: context.select((KabaddiControllerCubit c) => c.state.team1Touch),
            team2Value: context.select((KabaddiControllerCubit c) => c.state.team2Touch),
            onT1Add: () => controlCubit.incrementTeam1Touch(),
            onT1Sub: () => controlCubit.decrementTeam1Touch(),
            onT2Add: () => controlCubit.incrementTeam2Touch(),
            onT2Sub: () => controlCubit.decrementTeam2Touch(),
          ),
          const SizedBox(height: 8),
          _buildPointControl(
            label: "Bonus",
            team1Value: context.select((KabaddiControllerCubit c) => c.state.team1Bonus),
            team2Value: context.select((KabaddiControllerCubit c) => c.state.team2Bonus),
            onT1Add: () => controlCubit.incrementTeam1Bonus(),
            onT1Sub: () => controlCubit.decrementTeam1Bonus(),
            onT2Add: () => controlCubit.incrementTeam2Bonus(),
            onT2Sub: () => controlCubit.decrementTeam2Bonus(),
          ),
          const SizedBox(height: 8),
          _buildPointControl(
            label: "All Out",
            team1Value: context.select((KabaddiControllerCubit c) => c.state.team1AllOut),
            team2Value: context.select((KabaddiControllerCubit c) => c.state.team2AllOut),
            onT1Add: () => controlCubit.incrementTeam1AllOut(),
            onT1Sub: () => controlCubit.decrementTeam1AllOut(),
            onT2Add: () => controlCubit.incrementTeam2AllOut(),
            onT2Sub: () => controlCubit.decrementTeam2AllOut(),
          ),

          const SizedBox(height: 12),
          const ControllerHeading(text: "Raid & Quarter"),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(child: Text("Raid No.", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                child: CustomButton(
                  backgroundColor: AppColors.lakersGreen,
                  label: "+",
                  onPressed: () => controlCubit.incrementRaidNumber(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  backgroundColor: AppColors.scoreOrange,
                  label: "-",
                  onPressed: () => controlCubit.decrementRaidNumber(),
                  height: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text("Half", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                child: BlocSelector<KabaddiControllerCubit, KabaddiControllerState, int>(
                  selector: (state) => state.currentQuarter,
                  builder: (context, q) {
                    return CustomButton(
                      backgroundColor: Colors.blueAccent,
                      label: q == 1 ? "1st" : "2nd",
                      onPressed: () => controlCubit.setQuarter(q == 1 ? 2 : 1),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const ControllerHeading(text: "Game Actions"),
          const SizedBox(height: 6),
          CustomButton(
            backgroundColor: Colors.deepPurple,
            label: " Toggle Raider Side ",
            onPressed: () {
              controlCubit.toggleRaider();
              },
            height: 44,
          ),
          const SizedBox(height: 10),
          const ControllerHeading(text: "Display Settings"),


          BlocSelector<KabaddiControllerCubit, KabaddiControllerState, int>(
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
                            .read<KabaddiControllerCubit>()
                            .setBrightness((value * 255).toInt());
                      }, onChanged: (value) {
                      context
                          .read<KabaddiControllerCubit>()
                          .setTempBrightness((value * 255).toInt());
                    },
                    ),
                  ),
                ],
              );
            },
          ),


          BlocSelector<KabaddiControllerCubit, KabaddiControllerState, bool>(
              selector: (state) => state.buzzerOn,
              builder: (context,buzzer) {
                return SwitchListTile(title: const ControllerHeading(text: "Buzzer"), value: buzzer, onChanged: (value) {
                  context.read<KabaddiControllerCubit>().toggleBuzzer();
                });
              }
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPointControl({
    required String label,
    required int team1Value,
    required int team2Value,
    required VoidCallback onT1Add,
    required VoidCallback onT1Sub,
    required VoidCallback onT2Add,
    required VoidCallback onT2Sub,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: CustomButton(label: "+", onPressed: onT1Add, backgroundColor: AppColors.lakersGreen, height: 30)),
                  const SizedBox(width: 4),
                  Expanded(child: CustomButton(label: "-", onPressed: onT1Sub, backgroundColor: AppColors.scoreOrange, height: 30)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: CustomButton(label: "+", onPressed: onT2Add, backgroundColor: AppColors.lakersGreen, height: 30)),
                  const SizedBox(width: 4),
                  Expanded(child: CustomButton(label: "-", onPressed: onT2Sub, backgroundColor: AppColors.scoreOrange, height: 30)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
