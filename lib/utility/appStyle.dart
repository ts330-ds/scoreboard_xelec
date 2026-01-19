// lib/theme/app_styles.dart

import 'package:flutter/material.dart';
import 'appColor.dart';


class AppStyles {
  static const TextStyle welcomeBack = TextStyle(
    color: AppColors.darkText,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle signInToContinue = TextStyle(
    color: AppColors.subtleText,
    fontSize: 16,
  );

  static const TextStyle label = TextStyle(
    color: AppColors.lightText,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle inputPlaceholder = TextStyle(
    color: AppColors.subtleText,
    fontSize: 16,
  );

  static const TextStyle buttonText = TextStyle(
    color: AppColors.darkText,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle orDivider = TextStyle(
    color: AppColors.subtleText,
    fontSize: 14,
  );

  static const TextStyle linkText = TextStyle(
    color: AppColors.lightText,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle socialButtonText = TextStyle(
    color: AppColors.darkText,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle accountQuestion = TextStyle(
    color: AppColors.subtleText,
    fontSize: 14,
  );
}