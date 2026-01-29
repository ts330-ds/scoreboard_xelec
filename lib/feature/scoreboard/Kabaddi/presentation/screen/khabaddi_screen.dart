import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/Kabaddi/presentation/layout/khabaddi_mobile.dart';
import 'package:xelex_esp/feature/scoreboard/Kabaddi/presentation/layout/khabaddi_tablet.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

import '../../../../../service/dependency_injection/di_service.dart';
import '../cubit/controller/kabaddi_controller_cubit.dart';
import '../cubit/timer/kabaddi_timer_cubit.dart';
import '../layout/khabaddi_desktop.dart';

class KhabaddiScreen extends StatelessWidget {
  const KhabaddiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<KabaddiControllerCubit>()),
        BlocProvider.value(value: sl<KabaddiTimerCubit>()),
      ],
      child: ResponsiveLayout(mobile: KhabaddiMobile(),
          tablet: KhabaddiTablet(),
          desktop: KhabaddiDesktop()
      ),
    );
  }
}
