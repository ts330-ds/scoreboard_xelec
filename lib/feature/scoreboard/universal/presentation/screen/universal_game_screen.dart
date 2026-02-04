import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../responsive/responsive_layout_wrapper.dart';
import '../../../../../service/dependency_injection/di_service.dart';
import '../cubit/controller/universal_game_controller_cubit.dart';
import '../layout/universal_game_desktop.dart';
import '../layout/universal_game_mobile.dart';
import '../layout/universal_game_tablet.dart';

class UniversalGameScreen extends StatelessWidget {
  const UniversalGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
   return MultiBlocProvider(
     providers: [
       BlocProvider.value(value: sl<UniversalGameControllerCubit>(

       ))
     ],
     child: ResponsiveLayout(
        mobile: UniversalGameMobile(),
        tablet: UniversalGameTablet(),
        desktop: UniversalGameDesktop(),
      ),
   );
  }
}
