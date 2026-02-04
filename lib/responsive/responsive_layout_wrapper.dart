import 'package:flutter/material.dart';
import 'breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isDesktop(context)) {
      return desktop;
    } else if (Breakpoints.isTablet(context)) {
      return mobile; // Use mobile layout for tablet
    } else {
      return mobile;
    }
  }
}
