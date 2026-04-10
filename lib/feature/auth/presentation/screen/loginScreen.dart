import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:xelex_esp/feature/auth/presentation/cubit/auth_state.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';
import '../../../../utility/appColor.dart';
import '../widget/socialButton.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go(AppPaths.featureSelection);
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Something went wrong'),
                backgroundColor: AppColors.scoreOrange,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;
          return _LoginBody(isLoading: isLoading);
        },
      ),
    );
  }
}

class _LoginBody extends StatelessWidget {
  final bool isLoading;

  const _LoginBody({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Column(
          children: [
            // ── Top blue header section ───────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.bgGradientStart,
                    AppColors.bgGradientMiddle,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(top: 36.h, bottom: 40.h),
                  child: Column(
                    children: [
                      // App Icon
                      Container(
                        width: 90.w,
                        height: 90.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
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

                      SizedBox(height: 16.h),

                      Text(
                        'XELEX ESP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3.0,
                        ),
                      ),

                      SizedBox(height: 6.h),

                      Text(
                        'Sports Intelligence Platform',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom white section ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 36.h),

                    // ── Sign in label ─────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              color: const Color(0xFF1A1F36),
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Sign in to your account to continue',
                            style: TextStyle(
                              color: const Color(0xFF8A8FA3),
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // ── Google ────────────────────────────────────
                    _WhiteSocialButton(
                      text: 'Continue with Google',
                      logo: const GoogleLogo(),
                      isLoading: isLoading,
                      onPressed: isLoading
                          ? null
                          : () => context.read<AuthCubit>().signInWithGoogle(),
                    ),

                    SizedBox(height: 12.h),

                    // ── Apple (iOS only) ──────────────────────────
                    if (Platform.isIOS) ...[
                      _WhiteSocialButton(
                        text: 'Continue with Apple',
                        logo: const AppleLogo(dark: true),
                        onPressed: isLoading ? null : () {},
                      ),
                      SizedBox(height: 12.h),
                    ],

                    // ── LinkedIn ──────────────────────────────────
                    _WhiteSocialButton(
                      text: 'Continue with LinkedIn',
                      logo: const LinkedInLogo(),
                      onPressed: isLoading
                          ? null
                          : () => context.go(AppPaths.featureSelection),
                    ),

                    SizedBox(height: 12.h),

                    // ── Microsoft ─────────────────────────────────
                    _WhiteSocialButton(
                      text: 'Continue with Microsoft',
                      logo: const MicrosoftLogo(),
                      onPressed: isLoading
                          ? null
                          : () => context.go(AppPaths.featureSelection),
                    ),

                    SizedBox(height: 36.h),

                    // ── Divider ───────────────────────────────────
                    Row(
                      children: [
                        const Expanded(
                            child: Divider(color: Color(0xFFE0E3EF))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Text(
                            'Secure & Encrypted',
                            style: TextStyle(
                              color: const Color(0xFFB0B5C9),
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                        const Expanded(
                            child: Divider(color: Color(0xFFE0E3EF))),
                      ],
                    ),

                    SizedBox(height: 28.h),

                    // ── Terms ─────────────────────────────────────
                    Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFB0B5C9),
                        fontSize: 11.sp,
                        height: 1.7,
                      ),
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── White Theme Social Button ─────────────────────────────────────────

class _WhiteSocialButton extends StatelessWidget {
  final String text;
  final Widget logo;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _WhiteSocialButton({
    required this.text,
    required this.logo,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE0E3EF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.blueButton,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 24.w, height: 24.h, child: logo),
                  SizedBox(width: 12.w),
                  Text(
                    text,
                    style: TextStyle(
                      color: const Color(0xFF1A1F36),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
