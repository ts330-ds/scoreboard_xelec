import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';

class ArcheryIdleScreen extends StatefulWidget {
  final VoidCallback onLetsPlay;
  final BleService bleService;
  final ArcheryBleMapper archeryBleMapper;
  ArcheryIdleScreen({
    super.key,
    required this.onLetsPlay,
    required this.bleService,
    required this.archeryBleMapper,
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
      'SUNDAY',
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
      widget.archeryBleMapper.setTime(
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
      ),
    );
    widget.bleService.send(widget.archeryBleMapper.setDate(date));
    widget.bleService.send(widget.archeryBleMapper.setDay(day));
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          'Archery Game',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFFFFFF00), // Yellow like LED
            fontWeight: FontWeight.bold,
            letterSpacing: 2.sp,
          ),
        ),
      ),
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
                SizedBox(
                  width: 1.sw,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      timeFormat.format(_currentTime),
                      style: TextStyle(
                        fontSize: 40.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFFF00), // Yellow like LED
                        letterSpacing: 8.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                // Day Display
                SizedBox(
                  width: 1.sw,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      dayFormat.format(_currentTime).toUpperCase(),
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFFF00), // Yellow like LED
                        letterSpacing: 12.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: 1.sw,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${_currentTime.day.toString().padLeft(2, '0')}/"
                      "${_currentTime.month.toString().padLeft(2, '0')}/"
                      "${_currentTime.year}",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFFF00), // Yellow like LED
                        letterSpacing: 8.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 60.h),
                // Let's Play Button
                ElevatedButton(
                  onPressed: widget.onLetsPlay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: 48.w,
                      vertical: 20.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                  ),
                  child: Text(
                    "LET'S PLAY",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.sp,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                // Tap hint
                Text(
                  'Tap anywhere to start',
                  style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
