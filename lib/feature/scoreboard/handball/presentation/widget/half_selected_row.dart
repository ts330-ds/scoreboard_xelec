import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/cubit/timer/hand_ball_timer_cubit.dart';

import '../cubit/controller/hand_ball_controller_cubit.dart';
import '../cubit/controller/hand_ball_controller_state.dart';

class HalfSelectorRow extends StatelessWidget {
  const HalfSelectorRow({super.key});

  @override
  Widget build(BuildContext context) {
    final timerCubit = context.read<HandBallTimerCubit>();
    return BlocBuilder<HandBallControlCubit, HandballControlState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _halfButton(
              context,
              label: "1st Half",
              isSelected: state.matchHalf == MatchHalf.first,
              onPressed: () {
                context.read<HandBallControlCubit>().setHalf(MatchHalf.first);
                //timerCubit.goToFirstHalf();
              },
            ),
            _halfButton(
              context,
              label: "2nd Half",
              isSelected: state.matchHalf == MatchHalf.second,
              onPressed: () {
                context.read<HandBallControlCubit>().setHalf(MatchHalf.second);
               // timerCubit.goToSecondHalf();
              },
            ),
            _halfButton(
              context,
              label: "ET",
              isSelected: state.matchHalf == MatchHalf.extra,
              onPressed: () {
                context.read<HandBallControlCubit>().setHalf(MatchHalf.extra);
               // timerCubit.goToExtraTime();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _halfButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey.shade400,
            foregroundColor: Colors.white,
            elevation: isSelected ? 6 : 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
