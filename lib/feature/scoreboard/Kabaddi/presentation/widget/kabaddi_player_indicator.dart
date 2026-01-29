import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

class PlayerIndicator extends StatelessWidget {
  final int playerNumber;
  final int selectedNumber;

  const PlayerIndicator({
    Key? key,
    required this.playerNumber,
    required this.selectedNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:  playerNumber == selectedNumber ? Colors.red : Colors.grey.shade400,
      ),
      child: Center(
        child: Text(
          '$playerNumber',
          style: context.text.titleSmall!.copyWith(
            color: context.colors.onSecondary
          )
        ),
      ),
    );
  }
}
