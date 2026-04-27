import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/auth/presentation/cubit/athlete_auth_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/auth/presentation/cubit/athlete_auth_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/profile/presentation/cubit/athlete_profile_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/profile/presentation/cubit/athlete_profile_state.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class AthleteProfileMobile extends StatelessWidget {
  const AthleteProfileMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AthleteProfileCubit>()..fetchProfile(),
      child: const _AthleteProfileView(),
    );
  }
}

class _AthleteProfileView extends StatelessWidget {
  const _AthleteProfileView();

  Widget _profileContent(BuildContext context, AthleteProfileState state) {
    return switch (state.status) {
      AthleteProfileStatus.loading => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      AthleteProfileStatus.error => _ErrorView(
          message: state.errorMessage ?? 'Kuch galat ho gaya',
          onRetry: () => context.read<AthleteProfileCubit>().fetchProfile(),
        ),
      AthleteProfileStatus.loaded ||
      AthleteProfileStatus.updated => _ProfileBody(state: state),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AthleteAuthCubit, AthleteAuthState>(
      listenWhen: (prev, curr) => curr.status == AthleteAuthStatus.loggedOut,
      listener: (context, state) => context.go(AppPaths.splash),
      child: AdaptiveScaffold(
        title: 'Profile',
        bodyBackground: AppColors.bg,
        appBarBackground: AppColors.primary,
        body: BlocBuilder<AthleteProfileCubit, AthleteProfileState>(
          builder: (context, state) {
            return Column(
              children: [
                Expanded(child: _profileContent(context, state)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: _LogoutButton(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Profile Body ─────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final AthleteProfileState state;
  const _ProfileBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Avatar + name + email
          _ProfileHeader(
            name: profile?.name ?? '—',
            email: profile?.email ?? '—',
          ),
          const SizedBox(height: 24),

          // Info cards
          _InfoSection(
            title: 'Personal Info',
            items: [
              _InfoItem(
                icon: Icons.sports,
                label: 'Sport',
                value: profile?.sportName ?? '—',
              ),
              _InfoItem(
                icon: Icons.cake_outlined,
                label: 'Age',
                value: profile?.age != null ? '${profile!.age} yrs' : '—',
              ),
              _InfoItem(
                icon: Icons.person_outline,
                label: 'Gender',
                value: profile?.gender ?? '—',
              ),
              _InfoItem(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: profile?.phone ?? '—',
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  const _ProfileHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Avatar circle
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
            ),
            child: const Icon(Icons.person, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.subtext,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Section ──────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;
  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.subtext,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                e.value,
                if (!isLast) const Divider(height: 1, indent: 52, color: AppColors.borderLight),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.subtext),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AthleteAuthCubit, AthleteAuthState>(
      builder: (context, authState) {
        final isLoading = authState.status == AthleteAuthStatus.loggingOut;

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading ? null : () => _confirmLogout(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isLoading ? AppColors.border : AppColors.error,
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Kya aap logout karna chahte hain?',
          style: TextStyle(color: AppColors.subtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.subtext),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AthleteAuthCubit>().logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.subtext),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
