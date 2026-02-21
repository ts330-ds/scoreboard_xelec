

import 'package:flutter/material.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

class IndiviActivityMobile extends StatelessWidget {
  const IndiviActivityMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(title: "Activity Screen", 
    onSettingsPressed: (){

    },
    settingsIcon: const Icon(Icons.bluetooth),
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text("Welcome to the Individual Home Screen!"),
        SizedBox(height: 16),
        Text("This is where you can access your heart rate data and features."),
      ],
      ));
  }
}