

import 'package:flutter/material.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

class IndiviProfileMobile extends StatelessWidget {
  const IndiviProfileMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(title: "Profile Screen", 
    onSettingsPressed: (){

    },
    settingsIcon: const Icon(Icons.bluetooth),
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text("Welcome to the Individual Profile Screen!"),
        SizedBox(height: 16),
        Text("This is where you can access your profile information and settings."),
      ],
      ));
  }
}