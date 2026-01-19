import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/cubit/controller/hockey_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/cubit/timer/hockey_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/layout/hockey_desktop.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/layout/hockey_mobile.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/layout/hockey_tablet.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

import '../../../../../service/dependency_injection/di_service.dart';


class HockeyScreen extends StatelessWidget {
  const HockeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value( value: sl<HockeyTimerCubit>()),
        BlocProvider.value( value: sl<HockeyControllerCubit>()),
      ],
        child: ResponsiveLayout(mobile: HockeyMobile(), tablet: HockeyTablet(), desktop: HockeyDesktop()))
    ;
  }
}
