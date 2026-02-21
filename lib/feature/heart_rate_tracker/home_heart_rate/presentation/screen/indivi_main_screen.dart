import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/home_heart_rate/presentation/layout/indivi_main_screen_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

class IndiviMainScreen extends StatelessWidget {
  final Widget child;
  const IndiviMainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: IndiviMainScreenMobile(child: child), 
      tablet: IndiviMainScreenMobile(child: child),
      desktop: IndiviMainScreenMobile(child: child) 
      );
  }
}
