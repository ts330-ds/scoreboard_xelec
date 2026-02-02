import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/timer/archery_timer_cubit.dart';

class ArcheryTimerDisplay extends StatelessWidget {
  const ArcheryTimerDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArcheryTimerCubit, ArcheryTimerState>(
      builder: (context, state) {
        return Text(
          state.displayTime,
          style: TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: state.phaseColor,
            fontFamily: 'monospace',
            fontStyle: FontStyle.italic,
            letterSpacing: 4,
          ),
        );
      },
    );
  }
}
