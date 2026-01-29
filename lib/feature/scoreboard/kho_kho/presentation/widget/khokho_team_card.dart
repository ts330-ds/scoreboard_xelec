import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

class KhokhoTeamCard extends StatelessWidget {
  final String teamName;
  final String score;
  final String status;
  final Color backgroundColor;
  final Color scoreBoxColor;
  final Color statusColor;

  const KhokhoTeamCard({
    super.key,
    required this.teamName,
    required this.score,
    required this.status,
    required this.backgroundColor,
    required this.scoreBoxColor,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final width = constraints.maxWidth;

          return Container(
            color: backgroundColor,
            padding: EdgeInsets.all(width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team Name at the Top
                SizedBox(
                  height: height * 0.2,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      teamName,
                      textAlign: TextAlign.center,
                      style: context.text.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 0.9,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Score Box in the middle
                Center(
                  child: Container(
                    width: width * 0.8,
                    height: height * 0.45,
                    decoration: BoxDecoration(
                      color: scoreBoxColor,
                      borderRadius: BorderRadius.circular(width * 0.08),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
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

                const Spacer(),

                // Status Badge at the Bottom
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.05,
                      vertical: height * 0.02,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(width * 0.05),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        status,
                        style: context.text.headlineMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
