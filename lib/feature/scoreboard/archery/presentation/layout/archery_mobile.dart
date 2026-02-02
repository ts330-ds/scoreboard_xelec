import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widget/archery_control_panel.dart';
import '../widget/archery_end_label.dart';
import '../widget/archery_player_indicator.dart';
import '../widget/archery_timer_display.dart';
import '../widget/archery_traffic_light.dart';

class ArcheryMobile extends StatelessWidget {
  const ArcheryMobile({super.key});

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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top section - Timer and Traffic Light
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    // Timer Display
                    const Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ArcheryEndLabel(),
                          SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ArcheryTimerDisplay(),
                          ),
                          SizedBox(height: 16),
                          ArcheryPlayerIndicator(),
                        ],
                      ),
                    ),
                    // Traffic Light
                    const Expanded(
                      flex: 1,
                      child: Center(
                        child: ArcheryTrafficLight(size: 50),
                      ),
                    ),
                  ],
                ),
              ),

              // Control Panel
              const ArcheryControlPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
