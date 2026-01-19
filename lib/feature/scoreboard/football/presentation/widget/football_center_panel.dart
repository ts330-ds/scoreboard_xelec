import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/utility/theme_extension.dart';
import '../cubit/controller/football_controller_cubit.dart';
import '../cubit/controller/football_controller_state.dart';
import '../cubit/timer/football_timer_cubit.dart';

class FootballCenterPanel extends StatelessWidget {
  const FootballCenterPanel({super.key});

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade800, width: 1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main Timer
            BlocBuilder<FootballTimerCubit, FootballTimerState>(
              builder: (context, state) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatDuration(state.duration),
                    style: context.text.displayMedium?.copyWith(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                    ),
                  ),
                );
              },
            ),

            const Spacer(),

            // Extra Time
            BlocBuilder<FootballControllerCubit, FootballControllerState>(
              builder: (context, state) {
                return Text(
                  "+${state.extraTime}'",
                  style: context.text.headlineMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                );
              },
            ),

            const Spacer(),

            // Halves Indicators
            BlocBuilder<FootballControllerCubit, FootballControllerState>(
              builder: (context, state) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHalfIndicator(context, "1", state.currentHalf == 1),
                    const SizedBox(width: 16),
                    _buildHalfIndicator(context, "2", state.currentHalf == 2),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHalfIndicator(BuildContext context, String label, bool active) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? (label == "1" ? Colors.red : Colors.lightGreen) : Colors.grey.shade800,
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
