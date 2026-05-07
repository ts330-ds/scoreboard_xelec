import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/auth/presentation/cubit/athlete_auth_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/auth/presentation/cubit/athlete_auth_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/auth/presentation/cubit/coach_auth_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/auth/presentation/cubit/coach_auth_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/profile_registration/presentation/widget/loding_widget.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class ProfileChooseMobile extends StatelessWidget {
  const ProfileChooseMobile({super.key});

  void _onSelectIndividual(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _IndividualRoleSheet(
        onCoach: () {
          context.pop();
          _checkCoachAccount(context);
        },
        onAthlete: () {
          context.pop();
          _checkAthleteAccount(context);
        },
      ),
    );
  }

  void _checkCoachAccount(BuildContext context) {
    final email = sl<SharedPreferences>().getString(PrefKeys.validEmail) ?? '';
    context.read<CoachAuthCubit>().login(email: email, password:'123456');
  }

  void _checkAthleteAccount(BuildContext context) {
    final email = sl<SharedPreferences>().getString(PrefKeys.validEmail) ?? '';
    context.read<AthleteAuthCubit>().login(email: email, password: '123456');
  }

  void _onSelectOrganisation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.rocket_launch_outlined,
              color: AppColors.primary,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Coming Soon',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Organisation accounts are coming soon. Stay tuned for team and business features!',
          style: TextStyle(color: AppColors.subtext, fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AthleteAuthCubit, AthleteAuthState>(
          listener: (context, state) {
            if (state.status == AthleteAuthStatus.authenticated) {
              context.go(HeartTrackerPaths.athleteHome);
            } else if (state.status == AthleteAuthStatus.notRegistered) {
              context.push(HeartTrackerPaths.athleteRegistration);
            } else if (state.status == AthleteAuthStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'Something went wrong'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
        ),
        BlocListener<CoachAuthCubit, CoachAuthState>(
          listener: (context, state) {
            if (state.status == CoachAuthStatus.authenticated) {
              context.go(HeartTrackerPaths.coachHome);
            } else if (state.status == CoachAuthStatus.notRegistered) {
              context.push(HeartTrackerPaths.coachRegistration);
            } else if (state.status == CoachAuthStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'Something went wrong'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
        ),
      ],
      child: BlocBuilder<AthleteAuthCubit, AthleteAuthState>(
        builder: (context, athleteState) {
          return BlocBuilder<CoachAuthCubit, CoachAuthState>(
            builder: (context, coachState) {
              final isLoading =
                  athleteState.status == AthleteAuthStatus.loading ||
                  coachState.status == CoachAuthStatus.loading;

              if (isLoading) {
                return const AdaptiveScaffold(
                  title: 'Choose Profile',
                  bodyBackground: AppColors.bg,
                  appBarBackground: AppColors.primary,
                  body: Center(child: LoadingOverlay()),
                );
              }

              return AdaptiveScaffold(
                title: 'Choose Profile',
                bodyBackground: AppColors.bg,
                appBarBackground: AppColors.primary,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _onSelectIndividual(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary, width: 2),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.person, size: 40, color: AppColors.primary),
                                SizedBox(width: 16),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Individual',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'Personal account for single user',
                                        style: TextStyle(fontSize: 13, color: AppColors.subtext),
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () => _onSelectOrganisation(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.success, width: 2),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.business, size: 40, color: AppColors.success),
                                SizedBox(width: 16),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Organisation',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                      Text(
                                        'Account for teams or businesses',
                                        style: TextStyle(fontSize: 13, color: AppColors.subtext),
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                _ComingSoonBadge(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Coming Soon Badge ─────────────────────────────────────────────────────────

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: const Text(
        'Soon',
        style: TextStyle(
          color: AppColors.warning,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Individual Role Bottom Sheet ──────────────────────────────────────────────

class _IndividualRoleSheet extends StatelessWidget {
  final VoidCallback onCoach;
  final VoidCallback onAthlete;

  const _IndividualRoleSheet({required this.onCoach, required this.onAthlete});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Your Role',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose the role that best describes you',
              style: TextStyle(color: AppColors.subtext, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _RoleTile(
              icon: Icons.sports,
              iconColor: AppColors.primary,
              iconBg: AppColors.primaryLight,
              title: 'Coach',
              subtitle: 'Monitor and manage athlete performance',
              borderColor: AppColors.primary,
              onTap: onCoach,
            ),
            const SizedBox(height: 14),
            _RoleTile(
              icon: Icons.directions_run,
              iconColor: AppColors.heartRed,
              iconBg: AppColors.errorBg,
              title: 'Athlete',
              subtitle: 'Track your own health and performance',
              borderColor: AppColors.heartRed,
              onTap: onAthlete,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Role Tile ─────────────────────────────────────────────────────────────────

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Color borderColor;
  final VoidCallback onTap;

  const _RoleTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.subtext,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: iconColor, size: 16),
          ],
        ),
      ),
    );
  }
}
