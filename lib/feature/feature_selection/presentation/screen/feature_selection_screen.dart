import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import 'package:xelex_esp/utility/appColor.dart';

// ── Feature Data ──────────────────────────────────────────────────────────────

class _FeatureData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String featureKey;

  const _FeatureData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.featureKey,
  });
}

const List<_FeatureData> _features = [
  _FeatureData(
    title: 'Smart Scoreboard',
    subtitle: 'Real-time scores & game timer',
    icon: Icons.scoreboard_outlined,
    color: Color(0xFFFF6B35),
    featureKey: 'scoreboard',
  ),
  _FeatureData(
    title: 'Heart Rate Sensors',
    subtitle: 'Monitor athlete heart rate live',
    icon: Icons.favorite_outline,
    color: Color(0xFFE91E63),
    featureKey: 'heart_rate',
  ),
  _FeatureData(
    title: 'Electronic Timing Gates',
    subtitle: 'Precision sprint & speed timing',
    icon: Icons.timer_outlined,
    color: Color(0xFF2196F3),
    featureKey: 'timing_gates',
  ),
  _FeatureData(
    title: 'VBT',
    subtitle: 'Velocity-Based Training analysis',
    icon: Icons.fitness_center,
    color: Color(0xFF4CAF50),
    featureKey: 'vbt',
  ),
  _FeatureData(
    title: 'EEG',
    subtitle: 'Electroencephalography insights',
    icon: Icons.psychology_outlined,
    color: Color(0xFF9C27B0),
    featureKey: 'eeg',
  ),
  _FeatureData(
    title: 'AMS',
    subtitle: 'Athlete Management System',
    icon: Icons.manage_accounts,
    color: Color(0xFF00BCD4),
    featureKey: 'ams',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class FeatureSelectionScreen extends StatefulWidget {
  const FeatureSelectionScreen({super.key});

  @override
  State<FeatureSelectionScreen> createState() => _FeatureSelectionScreenState();
}

class _FeatureSelectionScreenState extends State<FeatureSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Header fade-in
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _headerFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Staggered fade per card
  Animation<double> _fadeFor(int index) => CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (0.15 + index * 0.1).clamp(0.0, 0.85),
          (0.45 + index * 0.1).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      );

  // Staggered slide per card
  Animation<Offset> _slideFor(int index) =>
      Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            (0.15 + index * 0.1).clamp(0.0, 0.85),
            (0.45 + index * 0.1).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );

  Future<void> _onFeatureSelected(_FeatureData feature) async {
    await sl<SharedPreferences>().setString(PrefKeys.selectedFeature, feature.featureKey);
    if (!mounted) return;

    // Scoreboard ke liye login ki zaroorat nahi — seedha jaao
    if (feature.featureKey == 'scoreboard') {
      context.push('${AppPaths.deviceSelection}?feature=scoreboard');
      return;
    }

    // Baaki sab features ke liye pehle login
    context.push(AppPaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
                itemCount: _features.length,
                separatorBuilder: (_, __) => SizedBox(height: 14.h),
                itemBuilder: (context, index) => FadeTransition(
                  opacity: _fadeFor(index),
                  child: SlideTransition(
                    position: _slideFor(index),
                    // RepaintBoundary isolates each card's repaint
                    child: RepaintBoundary(
                      child: _FeatureCard(
                        feature: _features[index],
                        onTap: () => _onFeatureSelected(_features[index]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgGradientStart, AppColors.bgGradientMiddle],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 28.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Your Device',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Select a feature to get started',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.sp,
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

// ── Feature Card ──────────────────────────────────────────────────────────────

class _FeatureCard extends StatefulWidget {
  final _FeatureData feature;
  final VoidCallback onTap;

  const _FeatureCard({required this.feature, required this.onTap});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _pressController.forward();
  void _onTapUp(TapUpDetails _) => _pressController.reverse();
  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    final color = widget.feature.color;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withValues(alpha: 0.75), color],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(widget.feature.icon, color: Colors.white, size: 26.sp),
              ),

              SizedBox(width: 16.w),

              // Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.feature.title,
                      style: TextStyle(
                        color: const Color(0xFF1A1F36),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      widget.feature.subtitle,
                      style: TextStyle(
                        color: const Color(0xFF8A8FA3),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow button
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
