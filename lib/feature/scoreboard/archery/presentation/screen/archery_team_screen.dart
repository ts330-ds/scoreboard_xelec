import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/teams_cubit/timer/archery_team_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/layout/archery_teams_round_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class ArcheryTeamScreen extends StatelessWidget {
  const ArcheryTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider.value(value: sl<ArcheryTeamTimerCubit>())],
      child: ResponsiveLayout(
        mobile: const ArcheryTeamsRoundMobile(),
        tablet: const ArcheryTeamsRoundMobile(),
        desktop: const ArcheryTeamsRoundMobile(),
      ),
    );
  }
}
