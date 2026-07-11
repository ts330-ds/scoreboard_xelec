import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/presentation/cubit/athlete_activity_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/dashboard/presentation/cubit/shell_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';
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

  // BT-off notify guard — snackbar ek hi baar dikhao jab tak BT off rehta hai
  // (har state emit pe repeat na ho). BT on hote hi reset ho jaata hai.
  StreamSubscription<HeartBleState>? _bleSub;
  bool _btOffNotified = false;

  // Lazy tab build — IndexedStack normally saare tabs turant build karta hai,
  // isliye Activity tab ka MyTasksCubit..fetchTasks() dashboard khulte hi chal
  // jaata tha (chahe user Activity kabhi na khole). Sirf visited tabs ko build
  // karo; visit hone ke baad IndexedStack unhe alive rakhta hai (state preserve).
  final Set<int> _visitedTabs = {};

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
    // recover karo — server status ke hisaab se resume / discard.
    // Recovery ne session resume nahi ki (ya thi hi nahi) to idle case me
    // last-connected band se bounded auto-reconnect chala do — app kholte hi
    // wahi band jud jaye jo aam taur pe use hota hai (jaise smartwatch app).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final activityCubit = sl<AthleteActivityCubit>();
      await activityCubit.attemptSessionRecovery();
      if (!mounted) return;
      if (!activityCubit.state.isSessionActive) {
        sl<HeartBleCubit>().attemptLaunchReconnect();
      }
    });

    // BT-off notification — launch pe auto-reconnect athlete main screen se
    // chalta hai (Connect Device screen mounted nahi hota), isliye wahan wala
    // BT-off dialog nahi aata. Yahan dashboard-level pe sunke snackbar dikhao.
    final bleCubit = sl<HeartBleCubit>();
    _bleSub = bleCubit.stream.listen((s) {
      if (!mounted) return;
      if (s.isBluetoothOff && !_btOffNotified) {
        _btOffNotified = true;
        _showBtOffSnackbar(bleCubit);
      } else if (!s.isBluetoothOff && _btOffNotified) {
        _btOffNotified = false;
      }
    });
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    super.dispose();
  }

  void _showBtOffSnackbar(HeartBleCubit cubit) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Bluetooth is off — turn it on to connect your heart rate monitor',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Enable',
          onPressed: () {
            cubit
              ..clearBluetoothOffFlag()
              ..openBluetoothSettings();
          },
        ),
      ),
    );
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
    // Current tab ko visited maano — ye tabhi build hoga (aur uska cubit/fetch
    // tabhi chalega). Visit hone ke baad alive rehta hai.
    _visitedTabs.add(currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubitIdx = context.read<AthleteShellCubit>().state;
      if (cubitIdx != currentIndex) context.read<AthleteShellCubit>().changeTab(currentIndex);
    });

    return BlocBuilder<AthleteShellCubit, int>(
      builder: (context, state) => Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: List.generate(_pages.length, (i) {
            // Jo tab abhi tak nahi khula, use build mat karo — sirf placeholder.
            if (!_visitedTabs.contains(i)) return const SizedBox.shrink();
            return Navigator(
              key: _navigatorKeys[i],
              onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _pages[i]),
            );
          }),
        ),
        bottomNavigationBar: _buildBottomNav(context, currentIndex),
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

