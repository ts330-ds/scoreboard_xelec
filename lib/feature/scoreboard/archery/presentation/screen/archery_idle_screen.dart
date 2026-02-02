import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ArcheryIdleScreen extends StatefulWidget {
  final VoidCallback onLetsPlay;

  const ArcheryIdleScreen({
    super.key,
    required this.onLetsPlay,
  });

  @override
  State<ArcheryIdleScreen> createState() => _ArcheryIdleScreenState();
}

class _ArcheryIdleScreenState extends State<ArcheryIdleScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');
    final dayFormat = DateFormat('EEEE'); // Full day name like "SATURDAY"

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: widget.onLetsPlay,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Time Display
                Text(
                  timeFormat.format(_currentTime),
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFF00), // Yellow like LED
                    fontFamily: 'monospace',
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 24),
                // Day Display
                Text(
                  dayFormat.format(_currentTime).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFF00), // Yellow like LED
                    fontFamily: 'monospace',
                    letterSpacing: 12,
                  ),
                ),
                const SizedBox(height: 60),
                // Let's Play Button
                ElevatedButton(
                  onPressed: widget.onLetsPlay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "LET'S PLAY",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Tap hint
                const Text(
                  'Tap anywhere to start',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
