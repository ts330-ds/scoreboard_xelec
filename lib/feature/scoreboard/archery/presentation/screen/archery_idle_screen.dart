import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

class ArcheryIdleScreen extends StatefulWidget {
  final VoidCallback onLetsPlay;
  BleService bleService;
  ArcheryBleMapper archeryBleMapper;
   ArcheryIdleScreen({
    super.key,
    required this.onLetsPlay,
    required this.bleService,
     required this.archeryBleMapper
  });

  @override
  State<ArcheryIdleScreen> createState() => _ArcheryIdleScreenState();
}

class _ArcheryIdleScreenState extends State<ArcheryIdleScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();


  String getDayName(DateTime dateTime) {
    const days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY'
    ];
    return days[dateTime.weekday - 1];
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    _sendTimeToBle(_currentTime);
  }
  void _sendTimeToBle(DateTime dateTime) {
    final date =
        "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";

    final day = getDayName(dateTime);

    widget.bleService.send(
      widget.archeryBleMapper.syncDateTime(dateTime)
    );
    widget.bleService.send(
      widget.archeryBleMapper.setDate(date),
    );
    widget.bleService.send(
      widget.archeryBleMapper.setDayOfWeek(day)
    );
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
