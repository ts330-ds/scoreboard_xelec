import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/utility/theme_extension.dart';
import '../cubit/timer/khokho_timer_cubit.dart';

class KhokhoFooter extends StatelessWidget {
  const KhokhoFooter({super.key});

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '00:$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KhokhoTimerCubit, KhokhoTimerState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              _formatDuration(state.duration),
              style: context.text.titleMedium
            ),
          ),
        );
      },
    );
  }
}
