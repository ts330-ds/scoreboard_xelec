import 'package:flutter/material.dart';
import 'football_mobile.dart';
import '../widget/football_control_panel.dart';

class FootballTablet extends StatelessWidget {
  const FootballTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 7, child: FootballMobile()),
        const VerticalDivider(width: 1),
        const Expanded(flex: 3, child: FootballControlPanel()),
      ],
    );
  }
}
