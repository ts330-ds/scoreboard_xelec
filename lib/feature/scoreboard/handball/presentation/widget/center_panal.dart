import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../common_widget/quarter_dot_widget.dart';
import '../../../../../utility/universal_method.dart';
import '../cubit/timer/hand_ball_timer_cubit.dart';
import '../cubit/timer/hand_ball_timer_state.dart';
class HandBallCenterPanel extends StatelessWidget {
  const HandBallCenterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive size (safe range)
    final gridSize = screenWidth * 0.15;
    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:  [
          SizedBox(
            width: gridSize,
            child: QuarterGridDots<HandBallTimerCubit,HandBallTimerState>(quarterSelector: (state) => state.quarter,
              totalQuarter: 4,
              isTimerFinishedSelector: (state) => state.status == TimerStatus.finished,
            ),
          ),
          SizedBox(height: 8),
          BlocBuilder<HandBallTimerCubit, HandBallTimerState>(
            builder: (context,state) {
              return Text(
                formatTime(state.seconds),
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
