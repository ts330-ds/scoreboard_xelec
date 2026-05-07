import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/router/heart_tracker_path.dart';
import 'package:xelex_esp/router/timing_gate_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import 'package:xelex_esp/utility/appColor.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _navigate();
    });
  }

  void _navigate() {
    final prefs = sl<SharedPreferences>();
    final coachToken = prefs.getString(PrefKeys.coachToken);
    final athleteToken = prefs.getString(PrefKeys.userToken);

    // Coach logged in — seedha coach dashboard
    if (coachToken != null && coachToken.isNotEmpty) {
      context.go(HeartTrackerPaths.coachHome);
      return;
    }

    // Athlete logged in — feature ke hisaab se route
    if (athleteToken != null && athleteToken.isNotEmpty) {
      final feature = prefs.getString(PrefKeys.selectedFeature);
      context.go(_routeForFeature(feature));
      return;
    }

    // Koi bhi logged in nahi
    context.go(AppPaths.featureSelection);
  }

  String _routeForFeature(String? feature) {
    switch (feature) {
      case 'scoreboard':
        return '${AppPaths.deviceSelection}?feature=scoreboard';
      case 'heart_rate':
        return HeartTrackerPaths.athleteHome;
      case 'timing_gates':
        return TimingGatePaths.timingGateHomeMobile;
      case 'vbt':
      case 'eeg':
      case 'ams':
        return HeartTrackerPaths.chooseProfile;
      default:
        return AppPaths.featureSelection;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgGradientStart,
              AppColors.bgGradientMiddle,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'images/logo/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Sports IQ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sports Intelligence Platform',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
