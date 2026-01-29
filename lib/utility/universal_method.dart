import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

String safeName(String name) =>
    name.substring(0, name.length.clamp(0, 10));

bool isValidHex565(String hex) =>
    RegExp(r'^[0-9A-Fa-f]{4}$').hasMatch(hex);


int toRgb565(Color color) {
  final argb = color.toARGB32();

  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;

  return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3);
}

String colorToHex(Color color) {
  return color.toARGB32()
      .toRadixString(16)
      .padLeft(8, '0')
      .substring(2) // remove alpha
      .toUpperCase();
}

String formatScore(int score) {
  return score.toString().padLeft(3, '0');
}

Text controllerHeading({required String label, required BuildContext context}){
  return Text(label,
      style: context.text.headlineMedium!.copyWith(fontWeight: FontWeight.bold)
  );
}

Widget buttonGap(){
  return const SizedBox(height: 6,);
}
Widget widgetGap(){
  return const SizedBox(height: 16,);
}


String formatTime(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final BorderRadius borderRadius;
  final TextStyle? textStyle;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 36, // sensible default
    this.backgroundColor = Colors.blue,
    this.foregroundColor = Colors.white,
    this.icon,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height, // 🔥 HEIGHT ENFORCED HERE
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: EdgeInsets.zero, // important
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
          textStyle: textStyle ??
              context.text.headlineMedium!.copyWith(fontWeight: FontWeight.w500,color: context.colors.surface)
        ),
        child: icon == null
            ? Text(label,style: textStyle ??
            context.text.headlineMedium!.copyWith(fontWeight: FontWeight.w500,color: context.colors.surface))
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 8),
            Text(label,style: context.text.titleSmall,),
          ],
        ),
      ),
    );
  }
}

