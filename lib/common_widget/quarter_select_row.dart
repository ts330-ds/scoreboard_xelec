import 'package:flutter/material.dart';

class QuarterButtonsRow extends StatelessWidget {
  final int selectedQuarter;
  final ValueChanged<int> onQuarterSelected;

  const QuarterButtonsRow({
    super.key,
    required this.selectedQuarter,
    required this.onQuarterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: List.generate(4, (index) {
        final quarter = index + 1;
        final bool isSelected = selectedQuarter == quarter;

        return Expanded(
          child: GestureDetector(
            onTap: () => onQuarterSelected(quarter),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2E7D32) // selected (green)
                    : const Color(0xFF424242), // unselected (dark grey)
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : Colors.grey,
                  width: 1.5,
                ),
              ),
              child: Text(
                textAlign: TextAlign.center,
                'Q$quarter',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade300,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
