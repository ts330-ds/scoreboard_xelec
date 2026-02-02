import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/timer/archery_timer_cubit.dart';

class ArcheryTrafficLight extends StatelessWidget {
  final double size;

  const ArcheryTrafficLight({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArcheryTimerCubit, ArcheryTimerState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLight(
              isActive: state.phase == TimerPhase.red,
              activeColor: Colors.red,
              size: size,
            ),
            SizedBox(height: size * 0.2),
            _buildLight(
              isActive: state.phase == TimerPhase.yellow,
              activeColor: Colors.yellow,
              size: size,
            ),
            SizedBox(height: size * 0.2),
            _buildLight(
              isActive: state.phase == TimerPhase.green || state.phase == TimerPhase.stopped,
              activeColor: Colors.green,
              size: size,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLight({
    required bool isActive,
    required Color activeColor,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? activeColor : Colors.grey[800],
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Color.fromRGBO(activeColor.red, activeColor.green, activeColor.blue, 0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
            : null,
        gradient: isActive
            ? RadialGradient(
                colors: [
                  Color.fromRGBO(activeColor.red, activeColor.green, activeColor.blue, 0.8),
                  activeColor,
                ],
                center: const Alignment(-0.3, -0.3),
              )
            : RadialGradient(
                colors: [
                  Colors.grey[700]!,
                  Colors.grey[900]!,
                ],
                center: const Alignment(-0.3, -0.3),
              ),
      ),
    );
  }
}
