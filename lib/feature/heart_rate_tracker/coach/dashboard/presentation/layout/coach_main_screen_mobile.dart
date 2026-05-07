import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/dashboard/presentation/cubit/coach_shell_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/dashboard/presentation/layout/coach_home_mobile.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/dashboard/presentation/layout/coach_profile_mobile.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';

class CoachMainScreenMobile extends StatelessWidget {
  final Widget child;
  const CoachMainScreenMobile({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Home',    icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view,  path: HeartTrackerPaths.coachHome),
    _NavItem(label: 'Profile', icon: Icons.person_outline,     activeIcon: Icons.person,     path: HeartTrackerPaths.coachProfile),
  ];

  static final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(_navItems.length, (_) => GlobalKey<NavigatorState>());

  static final List<Widget> _pages = [
    const CoachHomeMobile(),
    const CoachProfileMobile(),
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
    context.read<CoachShellCubit>().changeTab(index);
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubitIdx = context.read<CoachShellCubit>().state;
      if (cubitIdx != currentIndex) {
        context.read<CoachShellCubit>().changeTab(currentIndex);
      }
    });

    return BlocBuilder<CoachShellCubit, int>(
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
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12, offset: const Offset(0, -3)),
        ],
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
                        height: 3,
                        width: isSelected ? 20 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
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
