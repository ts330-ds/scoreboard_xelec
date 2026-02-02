import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/controller/archery_controller_cubit.dart';

class ArcheryEndLabel extends StatelessWidget {
  const ArcheryEndLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArcheryControllerCubit, ArcheryControllerState>(
      builder: (context, state) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blue indicator dot
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            // Label text
            Text(
              '${state.phaseLabel} END ${state.currentEndNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        );
      },
    );
  }
}
