import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

class ControllerHeading extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const ControllerHeading({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final defaultStyle =
        context.text.headlineMedium!.copyWith(
          fontWeight: FontWeight.bold,color: context.colors.onSurface
        );
    return Text(
      text,
      style: style??defaultStyle
    );
  }
}
