import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/Kabaddi/presentation/layout/khabaddi_mobile.dart';
import 'package:xelex_esp/feature/scoreboard/Kabaddi/presentation/layout/khabaddi_tablet.dart';
import 'package:xelex_esp/feature/scoreboard/badminton/presentation/layout/badmintion_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

import '../../../../../service/dependency_injection/di_service.dart';
import '../cubit/controller/badminton_controller_cubit.dart';
import '../layout/badminton_desktop.dart';
import '../layout/badminton_tablet.dart';

class BadmintonScreen extends StatelessWidget {
  const BadmintonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<BadmintonControllerCubit>()),
      ],
      child: ResponsiveLayout(
          mobile: BadmintionMobile(),
          tablet: BadmintionTablet(),
          desktop: BadmintionDesktop()
      ),
    );
  }
}
