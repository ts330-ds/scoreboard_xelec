import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/cubit/controller/hand_ball_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/cubit/timer/hand_ball_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/cubit/timer/hand_ball_timer_state.dart';

class HandBallTimerControlRow extends StatelessWidget {
  const HandBallTimerControlRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HandBallTimerCubit, HandBallTimerState>(
      builder: (context, state) {
        final cubit = context.read<HandBallTimerCubit>();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            /// Start / Resume
            ElevatedButton(
              onPressed: () {
                if (state.status == TimerStatus.paused) {
                  cubit.resume();
                } else {
                  cubit.start();
                }
              },
              child: Text(state.status == TimerStatus.paused ? 'Resume' : 'Start'),
            ),

            const SizedBox(width: 10),

            /// Pause
            ElevatedButton(
              onPressed: state.status == TimerStatus.running ? cubit.pause : null,
              child: const Text('Pause'),
            ),

            const SizedBox(width: 10),

            /// Reset
            ElevatedButton(onPressed: cubit.reset, child: const Text('Reset')),
          ],
        );
      },
    );
  }
}
