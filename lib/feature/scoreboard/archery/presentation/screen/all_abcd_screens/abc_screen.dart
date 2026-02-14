import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/abc_cubit/abc_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/teams_cubit/timer/archery_team_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/layout/all_abcd_layouts/abc_mobile.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/layout/all_abcd_layouts/abcd_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class AbcScreen extends StatelessWidget {
  const AbcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider.value(value: sl<AbcTimerCubit>())],
      child: ResponsiveLayout(
        mobile: const ABCMobile(),
        tablet: const ABCMobile(),
        desktop: const ABCMobile(),
      ),
    );
  }
}
