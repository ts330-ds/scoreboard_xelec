import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widget/archery_control_panel.dart';
import '../widget/archery_end_label.dart';
import '../widget/archery_player_indicator.dart';
import '../widget/archery_timer_display.dart';
import '../widget/archery_traffic_light.dart';

class ArcheryDesktop extends StatelessWidget {
  const ArcheryDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Archery Timer'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/archery-config'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              // Left - Control Panel
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const ArcheryControlPanel(),
                ),
              ),

              // Center - Main Display
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // End Label at top
                    const ArcheryEndLabel(),
                    const SizedBox(height: 24),

                    // Timer Display
                    const ArcheryTimerDisplay(),
                    const SizedBox(height: 32),

                    // Player Indicator
                    const ArcheryPlayerIndicator(),
                  ],
                ),
              ),

              // Right - Traffic Light
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    ArcheryTrafficLight(size: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
