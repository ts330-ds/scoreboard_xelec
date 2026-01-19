import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/utility/theme_extension.dart';
import '../cubit/controller/khokho_controller_cubit.dart';
import '../cubit/match_timer/match_timer_cubit.dart';

class KhokhoHeader extends StatelessWidget {
  const KhokhoHeader({super.key});

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KhokhoControllerCubit, KhokhoControllerState>(
      builder: (context, controllerState) {
        return Container(
          color: context.colors.primary,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoColumn(context, "Inn.", "${controllerState.inn}/2"),
              _buildInfoColumn(context, "Turn", "${controllerState.turn}/4"),
              
              // Match Timer Display
              BlocBuilder<MatchTimerCubit, MatchTimerState>(
                builder: (context, timerState) {
                  return _buildInfoColumn(context, "Match Time", _formatDuration(timerState.duration));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: context.text.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500
          ),
        ),
        Text(
          value,
          style: context.text.titleSmall?.copyWith(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
