import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/presentation/layout/timing_gate_main_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

class TimingGateMainScreen extends StatelessWidget {
  const TimingGateMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: TimingGateMainMobile(),
      tablet: TimingGateMainMobile(),
      desktop: TimingGateMainMobile(),
    );
  }
}
