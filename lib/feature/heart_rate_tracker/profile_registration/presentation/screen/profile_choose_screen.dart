import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/profile_registration/presentation/layout/profile_choose_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';


class ProfileChooseScreen extends StatelessWidget {
  const ProfileChooseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const ProfileChooseMobile(), 
      tablet: const ProfileChooseMobile(), 
      desktop: const ProfileChooseMobile()
      );
  }
}