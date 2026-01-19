import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/cubit/controller/table_tennis_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/layout/table_tennis_desktop.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/layout/table_tennis_mobile.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/layout/table_tennis_tablets.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

import '../../../../../service/dependency_injection/di_service.dart';


class TableTennisScreen extends StatelessWidget {
  const TableTennisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: sl<TableTennisControllerCubit>()),
        ],
        child: ResponsiveLayout(mobile: TableTennisMobile(),
            tablet: TableTennisTablet(), desktop: TableTennisDesktop()))
    ;
  }
}
