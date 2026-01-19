import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';


class GameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap; // 👈 function

  const GameCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap, // 👈 use function
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: context.text.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
