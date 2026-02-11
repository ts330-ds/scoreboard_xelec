import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/scoreboard/game_config/presentation/widget/team_color_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// your reusable color picker

class TwoTextFieldWidget extends StatelessWidget {
  final TextEditingController team1Controller;
  final TextEditingController team2Controller;

  final Color? team1Color;
  final Color? team2Color;

  final ValueChanged<Color> onTeam1ColorChanged;
  final ValueChanged<Color> onTeam2ColorChanged;

  const TwoTextFieldWidget({
    super.key,
    required this.team1Controller,
    required this.team2Controller,
    required this.team1Color,
    required this.team2Color,
    required this.onTeam1ColorChanged,
    required this.onTeam2ColorChanged,
  });

  bool _isValid() {
    return team1Controller.text.trim().isNotEmpty &&
        team2Controller.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TEAM 1 ROW
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: team1Controller,
                decoration: const InputDecoration(
                  labelText: 'Team 1',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            ColorPickerWidget(
              parentContext: context,
              selectedColor: team1Color,
              defaultColor: Colors.red,
              onColorSelected: onTeam1ColorChanged,
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // TEAM 2 ROW
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: team2Controller,
                decoration: const InputDecoration(
                  labelText: 'Team 2',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            ColorPickerWidget(
              parentContext: context,
              selectedColor: team2Color,
              defaultColor: Colors.blue,
              onColorSelected: onTeam2ColorChanged,
            ),
          ],
        ),
      ],
    );
  }
}
