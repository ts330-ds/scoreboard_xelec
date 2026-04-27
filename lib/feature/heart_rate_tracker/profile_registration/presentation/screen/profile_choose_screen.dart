import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/auth/presentation/cubit/athlete_auth_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/profile_registration/presentation/layout/profile_choose_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class ProfileChooseScreen extends StatelessWidget {
  const ProfileChooseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AthleteAuthCubit>(),
      child: ResponsiveLayout(
        mobile: const ProfileChooseMobile(),
        tablet: const ProfileChooseMobile(),
        desktop: const ProfileChooseMobile(),
      ),
    );
  }
}