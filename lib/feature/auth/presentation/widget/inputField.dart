import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;

  const InputField({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
