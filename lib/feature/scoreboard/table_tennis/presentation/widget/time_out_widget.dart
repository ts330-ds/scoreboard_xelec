import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

Widget TimeOutWidget({
  required String label,
  required bool isTimeout,
  required BuildContext context
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
          label,
          style: context.text.titleSmall!.copyWith(color: context.colors.surface)
      ),
      const SizedBox(width: 8),
      Container(
        width: 72,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isTimeout?Colors.grey:Colors.green
        ),
      ),
    ],
  );
}
