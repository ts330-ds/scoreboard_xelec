import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

class FootballTeamCard extends StatelessWidget {
  final String teamName;
  final String score;
  final Color teamNameColor;

  const FootballTeamCard({
    super.key,
    required this.teamName,
    required this.score,
    required this.teamNameColor,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 REMOVED Expanded from here. 
    // Always let the Parent layout decide if a widget should expand.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Container(
          color: Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05, 
            vertical: height * 0.05
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Name Section
              SizedBox(
                height: height * 0.25,
                width: width,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown, // Ensures text shrinks but never wraps/breaks
                  child: Text(
                    teamName,
                    style: context.text.displayLarge?.copyWith(
                      color: teamNameColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const Spacer(),

              // Score Box Section
              Center(
                child: Container(
                  width: width * 0.9,
                  height: height * 0.55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222), // Lighter black for contrast
                    borderRadius: BorderRadius.circular(width * 0.1),
                    border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain, // Maximize score size inside the box
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          score,
                          style: context.text.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}
