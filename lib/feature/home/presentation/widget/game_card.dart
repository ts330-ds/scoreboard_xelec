import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SizedBox(
          height: 90,
          child: Stack(
            clipBehavior: Clip.none, // 🔥 allow overflow
            children: [
              // 🧱 Card
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: EdgeInsets.only(
                    left: iconRight ? 40 : 62,
                    right: iconRight ? 62 : 40,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment:
                  iconRight ? Alignment.centerLeft : Alignment.centerRight,
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // 🎮 Floating SVG Icon
              Positioned(
                left: iconRight ? null : 50,
                right: iconRight ? 50 : null,
                top: -30,

                child: Transform.translate(
                  offset: const Offset(0, 6),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: SvgPicture.asset(
                      iconPath,
                      fit: BoxFit.contain,
                    ),
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
