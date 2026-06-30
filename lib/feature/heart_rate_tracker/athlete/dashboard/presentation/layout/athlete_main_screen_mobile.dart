import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/widgets/session_feedback_sheet.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/cubit/shell_cubit.dart';
import 'package:xelex_esp/feature/onboarding/battery_optimization_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/layout/athlete_activity_mobile.dart';
// SQL-backed history screen. To revert to the Hive version, swap this import
// back to athlete_history_screen.dart and use AthleteHistoryScreen below.
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/history_sql/presentation/screen/athlete_history_sql_screen.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/layout/athlete_home_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/layout/athlete_profile_mobile.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class AthleteMainScreenMobile extends StatefulWidget {
  final Widget child;
  const AthleteMainScreenMobile({super.key, required this.child});

  @override
  State<AthleteMainScreenMobile> createState() => _AthleteMainScreenMobileState();
}

class _AthleteMainScreenMobileState extends State<AthleteMainScreenMobile> {
  static bool _promptAttempted = false;
  bool _feedbackSheetShowing = false;

  @override
  void initState() {
    super.initState();
    if (!_promptAttempted) {
      _promptAttempted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) BatteryOptimizationScreen.showIfNeeded(context);
      });
    }
    // Process death (phone off / app swipe-kill) ke baad adhoori session
    // recover karo — server status ke hisaab se resume / upload / discard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sl<AthleteActivityCubit>().attemptSessionRecovery();
    });
  }

  Future<void> _showFeedbackSheet(BuildContext context, int taskId) async {
    if (_feedbackSheetShowing) return;
    _feedbackSheetShowing = true;
    await SessionFeedbackSheet.show(context, taskId: taskId);
    _feedbackSheetShowing = false;
    if (!mounted) return;
    sl<AthleteActivityCubit>().acknowledgeFeedbackPrompt();
  }

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Home',     icon: Icons.grid_view_outlined,  activeIcon: Icons.grid_view,   path: HeartTrackerPaths.athleteHome),
    _NavItem(label: 'Activity', icon: Icons.scoreboard_outlined, activeIcon: Icons.scoreboard,  path: HeartTrackerPaths.athleteActivity),
    _NavItem(label: 'Profile',  icon: Icons.person_outline,      activeIcon: Icons.person,      path: HeartTrackerPaths.athleteProfile),
    _NavItem(label: 'History',  icon: Icons.history,             activeIcon: Icons.history,     path: HeartTrackerPaths.athleteHistory),
  ];

  static final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(_navItems.length, (_) => GlobalKey<NavigatorState>());

  static final List<Widget> _pages = [
    const AthleteHomeMobile(),
    const AthleteActivityMobile(),
    const AthleteProfileMobile(),
    const AthleteHistorySqlScreen(),
  ];

  int _locationToIndex(String location) {
    final idx = _navItems.indexWhere((item) => location.startsWith(item.path));
    return idx == -1 ? 0 : idx;
  }

  void _onTabTapped(BuildContext context, int index, int currentIndex) {
    if (index == currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    context.read<AthleteShellCubit>().changeTab(index);
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubitIdx = context.read<AthleteShellCubit>().state;
      if (cubitIdx != currentIndex) context.read<AthleteShellCubit>().changeTab(currentIndex);
    });

    return BlocProvider.value(
      value: sl<AthleteActivityCubit>(),
      child: BlocBuilder<AthleteActivityCubit, AthleteActivityState>(
        buildWhen: (prev, curr) =>
            prev.pendingFeedbackTaskId != curr.pendingFeedbackTaskId,
        builder: (context, activityState) {
          final taskId = activityState.pendingFeedbackTaskId;

          if (taskId != null) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please submit session feedback first.'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Scaffold(
                backgroundColor: AppColors.bg,
                body: _FeedbackBlockingScreen(
                  onOpenFeedback: () => _showFeedbackSheet(context, taskId),
                ),
              ),
            );
          }

          return BlocBuilder<AthleteShellCubit, int>(
            builder: (context, state) => Scaffold(
              body: IndexedStack(
                index: currentIndex,
                children: _pages.asMap().entries.map((e) =>
                  Navigator(
                    key: _navigatorKeys[e.key],
                    onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => e.value),
                  ),
                ).toList(),
              ),
              bottomNavigationBar: _buildBottomNav(context, currentIndex),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: _navItems.asMap().entries.map((e) {
              final isSelected = currentIndex == e.key;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onTabTapped(context, e.key, currentIndex),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? e.value.activeIcon : e.value.icon,
                          key: ValueKey(isSelected),
                          color: isSelected ? AppColors.primary : AppColors.subtext,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? AppColors.primary : AppColors.subtext,
                        ),
                        child: Text(e.value.label),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3, width: isSelected ? 20 : 0,
                        decoration: BoxDecoration(
                            color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label, path;
  final IconData icon, activeIcon;
  const _NavItem({required this.label, required this.icon, required this.activeIcon, required this.path});
}

class _FeedbackBlockingScreen extends StatelessWidget {
  final VoidCallback onOpenFeedback;
  const _FeedbackBlockingScreen({required this.onOpenFeedback});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Session Feedback Required',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please submit your session feedback before continuing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.subtext,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onOpenFeedback,
                icon: const Icon(Icons.edit_note),
                label: const Text(
                  'Submit Feedback',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
