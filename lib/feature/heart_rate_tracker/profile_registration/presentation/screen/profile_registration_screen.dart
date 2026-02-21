import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/profile_registration/presentation/layout/profile_registration_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';

class IndiviProfileRegistrationScreen extends StatelessWidget {
  const IndiviProfileRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: IndiviRegistrationMobile(),
      tablet: IndiviRegistrationMobile(),
      desktop: IndiviRegistrationMobile(),
    );
  }
}
