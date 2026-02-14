import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/ab_cd_cubit/ab_cd_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/layout/all_abcd_layouts/ab_cd_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class Ab_CdScreen extends StatelessWidget {
  const Ab_CdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider.value(value: sl<Ab_CdTimerCubit>())],
      child: ResponsiveLayout(
        mobile: const AB_CDMobile(),
        tablet: const AB_CDMobile(),
        desktop: const AB_CDMobile(),
      ),
    );
  }
}
