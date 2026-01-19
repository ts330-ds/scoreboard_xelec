import 'package:flutter/material.dart';

class ServeIndicator extends StatelessWidget {
  const ServeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
                (_) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 6,
          color: Colors.green,
        ),
      ],
    );
  }
}
