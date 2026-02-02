import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/controller/archery_controller_cubit.dart';

class ArcheryPlayerIndicator extends StatelessWidget {
  const ArcheryPlayerIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArcheryControllerCubit, ArcheryControllerState>(
      builder: (context, state) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: state.allPlayers.map((player) {
            final isActive = state.isPlayerActive(player);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                player,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isActive ? const Color(0xFF00FF00) : Colors.grey[600],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
