import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/Kabaddi/presentation/cubit/timer/kabaddi_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/Kabaddi/presentation/widget/kabaddi_control_panel.dart';
import 'package:xelex_esp/utility/theme_extension.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../cubit/controller/kabaddi_controller_cubit.dart';
import '../cubit/controller/kabaddi_controller_state.dart';
import '../cubit/timer/kabaddi_timer_state.dart';
import 'kabaddi_player_indicator.dart';

class HeaderBar extends StatelessWidget {
  final int timeInSeconds;
  final int raid;
  final int currentPlayer;

  const HeaderBar({Key? key, required this.timeInSeconds, required this.raid, required this.currentPlayer})
    : super(key: key);

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timercubit = context.read<KabaddiTimerCubit>();
    final controllercubit = context.read<KabaddiControllerCubit>();

    return Container(
      color: const Color(0xFF4A7BC8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          BlocSelector<KabaddiControllerCubit, KabaddiControllerState, int>(
            selector: (state) => state.currentQuarter,
            builder: (context, q) {
              return  PlayerIndicator(playerNumber: 1, selectedNumber: q) ;
            },
          ),
          const SizedBox(width: 8),
          BlocSelector<KabaddiControllerCubit, KabaddiControllerState, int>(
            selector: (state) => state.currentQuarter,
            builder: (context, q) {
              return  PlayerIndicator(playerNumber: 2, selectedNumber: q);
            },
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                'Time',
                style: context.text.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              BlocSelector<KabaddiTimerCubit, KabaddiTimerState, int>(
                selector: (state) => state.seconds,
                builder: (BuildContext context, timeInSeconds) {
                  return Text(
                    formatTime(timeInSeconds),
                    style: context.text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
               Text(
                'Raid',
                style: context.text.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              BlocSelector<KabaddiControllerCubit, KabaddiControllerState, int>(
                selector: (state) => state.raidNumber,
                builder: (BuildContext context, raid) {
                  return Text(
                    raid.toString(),
                    style: context.text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
