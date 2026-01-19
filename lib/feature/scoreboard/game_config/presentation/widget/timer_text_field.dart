import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimerTextFieldWidget extends StatelessWidget {
  final TextEditingController timerController;

  const TimerTextFieldWidget({
    super.key,
    required this.timerController,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: timerController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: const InputDecoration(
        labelText: 'Timer (minutes)',
        border: OutlineInputBorder(),
      ),
    );
  }
}
