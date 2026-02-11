import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ColorPickerWidget extends StatelessWidget {
  final BuildContext parentContext;

  /// Selected color from parent (can be null)
  final Color? selectedColor;

  /// Default color if nothing is selected yet
  final Color defaultColor;

  /// Callback when user confirms color
  final ValueChanged<Color> onColorSelected;

  const ColorPickerWidget({
    super.key,
    required this.parentContext,
    required this.onColorSelected,
    this.selectedColor,
    this.defaultColor = Colors.blue, // ✅ default color
  });

  void _openPicker() {
    showDialog(
      context: parentContext,
      builder: (context) {
        Color tempColor = selectedColor ?? defaultColor;

        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              enableAlpha: false,
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                onColorSelected(tempColor);
                Navigator.pop(context);
              },
              child: const Text('SELECT'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorToShow = selectedColor ?? defaultColor;

    return GestureDetector(
      onTap: _openPicker,
      child: CircleAvatar(radius: 18.w, backgroundColor: colorToShow),
    );
  }
}
