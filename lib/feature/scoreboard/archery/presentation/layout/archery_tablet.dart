import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widget/archery_control_panel.dart';
import '../widget/archery_end_label.dart';
import '../widget/archery_player_indicator.dart';
import '../widget/archery_timer_display.dart';
import '../widget/archery_traffic_light.dart';

class ArcheryTablet extends StatelessWidget {
  const ArcheryTablet({super.key});

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
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Main Display Area
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // End Label
                    const ArcheryEndLabel(),
                    const SizedBox(height: 16),

                    // Timer Display
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ArcheryTimerDisplay(),
                    ),
                    const SizedBox(height: 24),

                    // Player Indicator
                    const ArcheryPlayerIndicator(),
                  ],
                ),
              ),

              // Right Panel - Traffic Light
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    ArcheryTrafficLight(size: 70),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black,
        child: const ArcheryControlPanel(),
      ),
    );
  }
}
