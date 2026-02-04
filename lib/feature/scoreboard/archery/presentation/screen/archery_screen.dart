import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../../../../bluetooth/mapper/archery_ble_mapper.dart';
import '../cubit/controller/archery_controller_cubit.dart';
import '../cubit/timer/archery_timer_cubit.dart';
import '../layout/archery_desktop.dart';
import '../layout/archery_mobile.dart';
import '../layout/archery_tablet.dart';
import 'archery_idle_screen.dart';

class ArcheryScreen extends StatefulWidget {
  const ArcheryScreen({super.key});

  @override
  State<ArcheryScreen> createState() => _ArcheryScreenState();
}

class _ArcheryScreenState extends State<ArcheryScreen> {
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
        BlocProvider.value(value: sl<ArcheryControllerCubit>()),
        BlocProvider.value(value: sl<ArcheryTimerCubit>()),
      ],
      child: BlocBuilder<ArcheryControllerCubit, ArcheryControllerState>(
        builder: (context, state) {
          // Show Idle Screen with Time/Date
          if (state.isIdleScreen) {
            return ArcheryIdleScreen(
              onLetsPlay: () {
                context.read<ArcheryControllerCubit>().showGameScreen();
              },
              archeryBleMapper: sl<ArcheryBleMapper>(),
              bleService: sl<BleService>(),
            );
          }

          // Show Game Screen
          return const ResponsiveLayout(
            mobile: ArcheryMobile(),
            tablet: ArcheryTablet(),
            desktop: ArcheryDesktop(),
          );
        },
      ),
    );
  }
}
