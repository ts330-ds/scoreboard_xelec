import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/kho_kho/presentation/layout/khokho_desktop.dart';
import 'package:xelex_esp/feature/scoreboard/kho_kho/presentation/layout/khokho_mobile.dart';
import 'package:xelex_esp/feature/scoreboard/kho_kho/presentation/layout/khokho_tablet.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../cubit/controller/khokho_controller_cubit.dart';
import '../cubit/timer/khokho_timer_cubit.dart';
import '../cubit/match_timer/match_timer_cubit.dart';


class KhoKhoScreen extends StatelessWidget {
  const KhoKhoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<KhokhoControllerCubit>()),
        BlocProvider.value(value: sl<KhokhoTimerCubit>()),
        BlocProvider.value(value: sl<MatchTimerCubit>()),
      ],
      child: const ResponsiveLayout(mobile: KhokhoMobile(),
          tablet: KhokhoTablet(), desktop: KhokhoDesktop()),
    );
  }
}
