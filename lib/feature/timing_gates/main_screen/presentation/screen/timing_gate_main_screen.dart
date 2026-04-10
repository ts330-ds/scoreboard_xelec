import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/presentation/layout/timing_gate_main_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

class TimingGateMainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TimingGateMainScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: TimingGateMainMobile(navigationShell: navigationShell),
      tablet: TimingGateMainMobile(navigationShell: navigationShell),
      desktop: TimingGateMainMobile(navigationShell: navigationShell),
    );
  }
}
