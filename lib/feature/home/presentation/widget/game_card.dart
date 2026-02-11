import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GameCard extends StatelessWidget {
  final String name;
  final String iconPath;
  final bool iconRight;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.name,
    required this.iconPath,
    this.iconRight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: SizedBox(
          height: 90.h,
          child: Stack(
            clipBehavior: Clip.none, // 🔥 allow overflow
            children: [
              // 🧱 Card
              Positioned.fill(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
                  padding: EdgeInsets.only(
                    left: iconRight ? 40.w : 62.w,
                    right: iconRight ? 62.w : 40.w,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 14.w,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  alignment: iconRight
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // 🎮 Floating SVG Icon
              Positioned(
                left: iconRight ? null : 50.w,
                right: iconRight ? 50.w : null,
                top: -30.h,

                child: Transform.translate(
                  offset: Offset(0, 6.h),
                  child: Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(color: Colors.transparent),
                    child: SvgPicture.asset(iconPath, fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
