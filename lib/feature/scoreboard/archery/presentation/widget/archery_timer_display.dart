import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/timer/archery_timer_state.dart';

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
            fontSize: 60.sp,
            fontWeight: FontWeight.bold,
            color: state.phaseColor,
          ),
        );
      },
    );
  }
}
