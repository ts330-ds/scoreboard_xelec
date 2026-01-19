import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../cubit/timer/basketball_timer_cubit.dart';
import '../cubit/timer/basketball_timer_state.dart';

class BasketBallTimerControlRow extends StatelessWidget {
  const BasketBallTimerControlRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: BlocBuilder<BasketBallTimerCubit, BasketBallTimerState>(
        builder: (context, state) {
          final cubit = context.read<BasketBallTimerCubit>();
          return Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: state.status == TimerStatus.running ? "Pause" : (state.status == TimerStatus.paused ? "Resume" : "Start"),
                  backgroundColor: state.status == TimerStatus.running ? Colors.orange : Colors.green,
                  onPressed: () {
                    if (state.status == TimerStatus.running) {
                      cubit.pause();
                    } else if (state.status == TimerStatus.paused) {
                      cubit.resume();
                    } else {
                      cubit.start();
                    }
                  },
                  height: 36,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  label: "Reset",
                  backgroundColor: Colors.blueGrey,
                  onPressed: () => cubit.reset(),
                  height: 36,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
