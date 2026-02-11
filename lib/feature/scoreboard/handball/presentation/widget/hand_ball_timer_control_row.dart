import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/cubit/timer/hand_ball_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/cubit/timer/hand_ball_timer_state.dart';
import 'package:xelex_esp/utility/appColor.dart';

class HandBallTimerControlRow extends StatelessWidget {
  const HandBallTimerControlRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: BlocBuilder<HandBallTimerCubit, HandBallTimerState>(
        builder: (context, state) {
          final cubit = context.read<HandBallTimerCubit>();
          final status = state.status;

          // Button enable states based on timer status
          final bool isInitialOrFinished =
              status == TimerStatus.initial || status == TimerStatus.finished;
          final bool isRunning = status == TimerStatus.running;
          final bool isPaused = status == TimerStatus.paused;

          return Row(
            children: [
              // Start Button - enabled only when timer is initial or finished
              Expanded(
                child: _TimerButton(
                  label: "Start",
                  backgroundColor: AppColors.lakersGreen,
                  disabledColor: Colors.grey.shade400,
                  onPressed: isInitialOrFinished ? () => cubit.start() : null,
                ),
              ),
              const SizedBox(width: 8),

              // Resume Button - enabled only when timer is paused
              Expanded(
                child: _TimerButton(
                  label: "Resume",
                  backgroundColor: Colors.blue,
                  disabledColor: Colors.grey.shade400,
                  onPressed: isPaused ? () => cubit.resume() : null,
                ),
              ),
              const SizedBox(width: 8),

              // Pause Button - enabled only when timer is running
              Expanded(
                child: _TimerButton(
                  label: "Pause",
                  backgroundColor: AppColors.scoreOrange,
                  disabledColor: Colors.grey.shade400,
                  onPressed: isRunning ? () => cubit.pause() : null,
                ),
              ),
              const SizedBox(width: 8),

              // Reset Button - enabled when timer is not in initial state
              Expanded(
                child: _TimerButton(
                  label: "Reset",
                  backgroundColor: Colors.blueGrey,
                  disabledColor: Colors.grey.shade400,
                  onPressed: !isInitialOrFinished ? () => cubit.reset() : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color disabledColor;
  final VoidCallback? onPressed;


  const _TimerButton({
    required this.label,
    required this.backgroundColor,
    required this.disabledColor,
    required this.onPressed,

  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    return SizedBox(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? backgroundColor : disabledColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: disabledColor,
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
