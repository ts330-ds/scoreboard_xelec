import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/controlPanal/controlPanalCubit.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/shot_clock/shot_clock_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/layouts/basketball/basket_ball_desktop.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/layouts/basketball/basket_ball_mobile.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/layouts/basketball/basket_ball_tablet.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

import '../../../../../service/dependency_injection/di_service.dart';
import '../cubit/timer/basketball_timer_cubit.dart';

class BasketBallScreen extends StatelessWidget {
  const BasketBallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<BasketBallTimerCubit>()),
        BlocProvider.value(value: sl<BasketControlPanelCubit>()),
        BlocProvider.value(value: sl<ShotClockCubit>()),
      ],
      child: const ResponsiveLayout(
          mobile: BasketBallMobile(), 
          tablet: BasketBallTablet(), 
          desktop: BasketBallDesktop()
      ),
    );
  }
}
