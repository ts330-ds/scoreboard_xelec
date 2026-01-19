import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

import '../../../../../common_widget/quarter_dot_widget.dart';
import '../../../../../utility/universal_method.dart';
import '../cubit/timer/hockey_timer_cubit.dart';
import '../cubit/timer/hockey_timer_state.dart';

class HockeyCenterPanel extends StatelessWidget {
  const HockeyCenterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive size (safe range)
    final gridSize = screenWidth * 0.15;
    return Container(
      width: size.width/3,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          SizedBox(
            width: gridSize,
            child: QuarterGridDots<HockeyTimerCubit,HockeyTimerState>(quarterSelector: (state) => state.quarter,
              totalQuarter: 4,
              isTimerFinishedSelector: (state) => state.status == TimerStatus.finished,
            ),
          ),
          // TIMER
          const SizedBox(height: 10),
           BlocBuilder<HockeyTimerCubit, HockeyTimerState>(
             builder: (context, time) {
               return Text(
                formatTime(time.seconds),
                textAlign: TextAlign.center,
                style: context.text.titleLarge!.copyWith(color: context.colors.surface),
               );
             }
           ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
