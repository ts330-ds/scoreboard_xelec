import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/layout/archery_individual_round_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../cubit/individual_cubit/timer/archery_individual_timer_cubit.dart';

class ArcheryIndividualScreen extends StatelessWidget {
  const ArcheryIndividualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider.value(value: sl<ArcheryIndividualTimerCubit>())],
      child: ResponsiveLayout(
        mobile: const ArcheryIndividualRoundMobile(),
        tablet: const ArcheryIndividualRoundMobile(),
        desktop: const ArcheryIndividualRoundMobile(),
      ),
    );
  }
}
