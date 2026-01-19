import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/football/presentation/layout/football_desktop.dart';
import 'package:xelex_esp/feature/scoreboard/football/presentation/layout/football_mobile.dart';
import 'package:xelex_esp/feature/scoreboard/football/presentation/layout/football_tablet.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../cubit/controller/football_controller_cubit.dart';
import '../cubit/timer/football_timer_cubit.dart';

class FootballScreen extends StatelessWidget {
  const FootballScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<FootballControllerCubit>()),
        BlocProvider.value(value: sl<FootballTimerCubit>()),
      ],
      child: const ResponsiveLayout(
        mobile: FootballMobile(),
        tablet: FootballTablet(),
        desktop: FootballDesktop(),
      ),
    );
  }
}
