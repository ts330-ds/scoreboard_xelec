import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/alternate_game_controller/archery_alternate_game_controller.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/alternate_game_controller/archery_alternate_game_controller_state.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/alternate_game_timer/archery_alternate_game_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/layout/archery_alternate_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';


import '../cubit/controller/archery_controller_cubit.dart';
import '../cubit/timer/archery_timer_cubit.dart';


class ArcheryAlternateScreen extends StatefulWidget {
  const ArcheryAlternateScreen({super.key});

  @override
  State<ArcheryAlternateScreen> createState() => _ArcheryAlternateScreenState();
}

class _ArcheryAlternateScreenState extends State<ArcheryAlternateScreen> {
  @override
  void initState() {
    super.initState();
    _setupTimerCallback();
  }

  void _setupTimerCallback() {
    final timerCubit = sl<ArcheryTimerCubit>();
    final controllerCubit = sl<ArcheryControllerCubit>();

    timerCubit.onCycleComplete = () {
      controllerCubit.onTimerCycleComplete();

      // Auto-start next cycle for all modes if match is not complete
      if (!controllerCubit.state.isMatchComplete &&
          controllerCubit.state.matchPhase != MatchPhase.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!controllerCubit.state.isMatchComplete &&
              controllerCubit.state.matchPhase != MatchPhase.completed) {
            timerCubit.startCycle();
          }
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<ArcheryAlternateGameControllerCubit>()),
        BlocProvider.value(value: sl<ArcheryAlternateGameTimerCubit>()),
      ],
      child: BlocBuilder<ArcheryAlternateGameControllerCubit, ArcheryAlternateGameControllerState>(
        builder: (context, state) {
          return const ResponsiveLayout(
            mobile: ArcheryAlternateMobile(),
            tablet: ArcheryAlternateMobile(),
            desktop: ArcheryAlternateMobile(),
          );
        },
      ),
    );
  }
}
