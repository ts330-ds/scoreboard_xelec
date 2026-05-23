import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  final List<Widget> children;
  const StatsRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 8)])
          .toList()
        ..removeLast(),
    );
  }
}
