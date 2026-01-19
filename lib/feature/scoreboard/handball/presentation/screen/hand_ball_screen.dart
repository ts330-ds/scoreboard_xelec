import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/cubit/controller/hand_ball_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/layout/hand_ball_desktop.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/layout/hand_ball_mobile.dart';
import 'package:xelex_esp/feature/scoreboard/handball/presentation/layout/hand_ball_tablet.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

import '../../../../../service/dependency_injection/di_service.dart';
import '../cubit/timer/hand_ball_timer_cubit.dart';

class HandBallScreen extends StatelessWidget {
  const HandBallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value : sl<HandBallTimerCubit>()),
        BlocProvider.value(value : sl<HandBallControlCubit>())
      ],
      child:  ResponsiveLayout(mobile: HandBallMobile(), tablet: HandBallTablet(), desktop: HandBallDesktop()),
    );
  }
}
