import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/layout/athlete_main_screen_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/profile/presentation/cubit/athlete_profile_cubit.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class AthleteMainScreen extends StatelessWidget {
  final Widget child;
  const AthleteMainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AthleteProfileCubit>()..fetchProfile(),
      child: ResponsiveLayout(
        mobile:  AthleteMainScreenMobile(child: child),
        tablet:  AthleteMainScreenMobile(child: child),
        desktop: AthleteMainScreenMobile(child: child),
      ),
    );
  }
}
