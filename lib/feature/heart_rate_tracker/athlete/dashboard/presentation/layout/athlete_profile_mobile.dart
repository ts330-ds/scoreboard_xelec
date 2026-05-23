import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/auth/presentation/cubit/athlete_auth_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/auth/presentation/cubit/athlete_auth_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/profile/presentation/cubit/athlete_profile_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/profile/presentation/cubit/athlete_profile_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/common/sport/presentation/cubit/sport_cubit.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../widgets/profile_error_view.dart';
import '../widgets/profile_form.dart';

class AthleteProfileMobile extends StatelessWidget {
  const AthleteProfileMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SportCubit>()..getSports(),
      child: const _AthleteProfileView(),
    );
  }
}

class _AthleteProfileView extends StatelessWidget {
  const _AthleteProfileView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AthleteAuthCubit, AthleteAuthState>(
          listenWhen: (prev, curr) =>
              curr.status == AthleteAuthStatus.loggedOut,
          listener: (context, state) => context.go(AppPaths.splash),
        ),
        BlocListener<AthleteProfileCubit, AthleteProfileState>(
          listenWhen: (prev, curr) =>
              curr.status == AthleteProfileStatus.updated ||
              (curr.status == AthleteProfileStatus.error &&
                  prev.status == AthleteProfileStatus.updating),
          listener: (context, state) {
            final isSuccess = state.status == AthleteProfileStatus.updated;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isSuccess
                      ? 'Profile updated successfully'
                      : (state.errorMessage ?? 'Update failed'),
                ),
                backgroundColor:
                    isSuccess ? AppColors.success : AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
      child: AdaptiveScaffold(
        title: 'Profile',
        bodyBackground: AppColors.bg,
        appBarBackground: AppColors.primary,
        body: BlocBuilder<AthleteProfileCubit, AthleteProfileState>(
          builder: (context, state) {
            return switch (state.status) {
              AthleteProfileStatus.loading => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              AthleteProfileStatus.error => ProfileErrorView(
                  message: state.errorMessage ?? 'Something went wrong',
                  onRetry: () =>
                      context.read<AthleteProfileCubit>().fetchProfile(),
                ),
              AthleteProfileStatus.loaded ||
              AthleteProfileStatus.updated =>
                ProfileForm(profile: state.profile),
              _ => const SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }
}
