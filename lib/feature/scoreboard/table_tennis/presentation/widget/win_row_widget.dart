import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

Widget WinRowWidget({
  required String label,
  required Color color,
  required int wins, // 👈 number of rounds won (0–4)
  int totalRounds = 4,
  required BuildContext context
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        label,
        style: context.text.titleSmall!.copyWith(color: context.colors.surface)
      ),
      const SizedBox(width: 4),
      Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalRounds, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < wins
                    ? color
                    : Colors.white.withOpacity(0.3),
              ),
              child: Center(child: Text("${index+1}",style: context.text.bodySmall!.copyWith(color: context.colors
                  .surface,fontWeight: FontWeight.bold),)),
            );
          }),
        ),
      ),
    ],
  );
}
