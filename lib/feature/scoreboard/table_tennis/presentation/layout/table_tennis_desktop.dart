import 'package:flutter/material.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';


class TableTennisDesktop extends StatelessWidget {
  const TableTennisDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(title: "Table Tennis", body: Column(
      children: [
        Text("Table Tennis"),
      ],
    ));
  }
}
