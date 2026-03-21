import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/router/timing_gate_path.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/home_heart_rate/presentation/cubit/navigation_cubit/shell_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/presentation/layout/timing_gate_home_mobile.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/presentation/layout/timing_gate_results_mobile.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/presentation/layout/timing_gate_athletes_mobile.dart';
import 'package:xelex_esp/feature/timing_gates/main_screen/presentation/layout/timing_gate_profile_mobile.dart';

class TimingGateMainMobile extends StatelessWidget {
  const TimingGateMainMobile({super.key});

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      path: TimingGatePaths.timingGateHomeMobile,
    ),
    _NavItem(
      label: 'Results',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      path: TimingGatePaths.timingGateResultsMobile,
    ),
    _NavItem(
      label: 'Athletes',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      path: TimingGatePaths.timingGateAthletesMobile,
    ),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      path: TimingGatePaths.timingGateProfileMobile,
    ),
  ];

  static final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    _navItems.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  static const List<Widget> _pages = [
    TimingGateHomeMobile(),
    TimingGateResultsMobile(),
    TimingGateAthletesMobile(),
    TimingGateProfileMobile(),
  ];

  int _locationToIndex(String location) {
    final index = _navItems.indexWhere(
      (item) => location.startsWith(item.path),
    );
    return index == -1 ? 0 : index;
  }

  void _onTabTapped(BuildContext context, int index, int currentIndex) {
    if (index == currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    context.read<ShellCubit>().changeTab(index);
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    // Wrap inside Title if needed, here we'll directly return a Scaffold
    // with IndexedStack and bottom nav.
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return BlocBuilder<ShellCubit, int>(
        builder: (_, state) {
          return Scaffold(
            body: IndexedStack(
              index: currentIndex,
              children: _pages
                  .asMap()
                  .entries
                  .map(
                    (entry) => Navigator(
                      key: _navigatorKeys[entry.key],
                      onGenerateRoute: (_) =>
                          MaterialPageRoute(builder: (_) => entry.value),
                    ),
                  )
                  .toList(),
            ),
            bottomNavigationBar: _buildBottomNav(context, currentIndex),
          );
        },
      );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).toInt()),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onTabTapped(context, index, currentIndex),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          key: ValueKey(isSelected),
                          color: isSelected
                              ? const Color(0xFF1A73E8)
                              : Colors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? const Color(0xFF1A73E8)
                              : Colors.grey,
                        ),
                        child: Text(item.label),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        width: isSelected ? 20 : 0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8),
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
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}
