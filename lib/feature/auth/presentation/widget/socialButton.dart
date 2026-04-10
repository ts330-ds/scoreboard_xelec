import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../utility/appColor.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final Widget logo;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final bool isLoading;

  const SocialButton({
    super.key,
    required this.text,
    required this.logo,
    this.onPressed,
    this.borderColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(vertical: 16.h),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: borderColor ?? AppColors.inputBorder,
            width: 1.2,
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
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
                      color: AppColors.textPrimary,
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

// ── Brand Logo Widgets ──────────────────────────────────────────────

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 2.8;

    // Red arc (top)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      3.67,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.1,
      1.05,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14,
      1.05,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      4.19,
      1.05,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt,
    );

    // Horizontal bar of "G"
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius, center.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AppleLogo extends StatelessWidget {
  final bool dark;
  const AppleLogo({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.apple,
      color: dark ? Colors.black : Colors.white,
      size: 24.sp,
    );
  }
}

class LinkedInLogo extends StatelessWidget {
  const LinkedInLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.w,
      height: 24.h,
      decoration: BoxDecoration(
        color: const Color(0xFF0A66C2),
        borderRadius: BorderRadius.circular(4.r),
      ),
      alignment: Alignment.center,
      child: Text(
        'in',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class MicrosoftLogo extends StatelessWidget {
  const MicrosoftLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20.w,
      height: 20.w,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _Square(color: const Color(0xFFF25022)),
                SizedBox(width: 2.w),
                _Square(color: const Color(0xFF7FBA00)),
              ],
            ),
          ),
          SizedBox(height: 2.w),
          Expanded(
            child: Row(
              children: [
                _Square(color: const Color(0xFF00A4EF)),
                SizedBox(width: 2.w),
                _Square(color: const Color(0xFFFFB900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Square extends StatelessWidget {
  final Color color;
  const _Square({required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(color: color),
      ),
    );
  }
}
