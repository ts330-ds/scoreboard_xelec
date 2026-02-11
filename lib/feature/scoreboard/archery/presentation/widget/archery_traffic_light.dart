import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/timer/archery_timer_state.dart';

import '../cubit/timer/archery_timer_cubit.dart';

class ArcheryTrafficLight extends StatelessWidget {
  final double size;

  const ArcheryTrafficLight({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArcheryTimerCubit, ArcheryTimerState>(
      builder: (context, state) {
        final color = _getColorForPhase(state.phase);
        return _buildLight(color: color, size: size);
      },
    );
  }

  Color _getColorForPhase(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.red:
        return Colors.red;
      case TimerPhase.yellow:
        return Colors.yellow;
      case TimerPhase.green:
      case TimerPhase.stopped:
        return Colors.green;
    }
  }

  Widget _buildLight({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3.w),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(color.red, color.green, color.blue, 0.6),
            blurRadius: 20.w,
            spreadRadius: 5.w,
          ),
        ],
        gradient: RadialGradient(
          colors: [
            Color.fromRGBO(color.red, color.green, color.blue, 0.8),
            color,
          ],
          center: const Alignment(-0.3, -0.3),
        ),
      ),
    );
  }
}
