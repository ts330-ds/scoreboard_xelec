import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/home/presentation/layout/home_screen_mobile.dart';
import 'package:xelex_esp/feature/home/presentation/layout/home_screen_tablet.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

import '../layout/home_screen_desktop.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
        mobile: HomeScreenMobile(),
        tablet: HomeScreenTablet(),
        desktop: HomeScreenDesktop()
    );
  }
}
