import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../utility/appColor.dart';
import '../../../../utility/appStyle.dart';

Widget buildLogo() {
  return Center(
    child: Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Icon(
        Icons.flash_on, // Placeholder icon similar to the design
        color: AppColors.darkText,
        size: 30.sp,
      ),
    ),
  );
}

Widget buildInputField({required String hintText, bool obscureText = false}) {
  return TextField(
    obscureText: obscureText,
    style: AppStyles.buttonText, // Use a solid style for input text
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: AppStyles.inputPlaceholder,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      filled: true,
      fillColor: AppColors.inputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.w),
        borderSide: BorderSide(color: AppColors.inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.w),
        borderSide: BorderSide(color: AppColors.inputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.w),
        borderSide: const BorderSide(color: AppColors.blueButton, width: 2),
      ),
    ),
  );
}

Widget buildPrimaryButton({required String text}) {
  return SizedBox(
    height: 50.h,
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blueButton,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
        elevation: 0,
      ),
      child: Text(text, style: AppStyles.buttonText),
    ),
  );
}

Widget buildOrDivider() {
  return const Row(
    children: [
      Expanded(child: Divider(color: AppColors.inputBorderColor)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('or continue with', style: AppStyles.orDivider),
      ),
      Expanded(child: Divider(color: AppColors.inputBorderColor)),
    ],
  );
}

Widget buildSocialButtons() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: buildSocialButton(
          text: 'Google',
          icon: Icons.search, // Placeholder for Google icon
          onPressed: () {},
        ),
      ),
      SizedBox(width: 16.w),
      Expanded(
        child: buildSocialButton(
          text: 'Apple',
          icon: Icons.apple, // Placeholder for Apple icon
          onPressed: () {},
        ),
      ),
    ],
  );
}

Widget buildSocialButton({
  required String text,
  required IconData icon,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    height: 50.h,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.darkBackground,
        side: const BorderSide(color: AppColors.socialButtonBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
      ),
      icon: Icon(icon, color: AppColors.darkText),
      label: Text(text, style: AppStyles.socialButtonText),
    ),
  );
}

Widget buildCreateAccountButton() {
  return SizedBox(
    height: 36.h,
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blueButton,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        elevation: 0,
      ),
      child: const Text('Create Account', style: AppStyles.buttonText),
    ),
  );
}
