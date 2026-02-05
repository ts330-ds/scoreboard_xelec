import 'package:flutter/foundation.dart';

class ArcheryBleMapper {
  String _log(String command) {
    debugPrint('🏹 BLE Command: $command');
    return command;
  }

  // === CLOCK MODE ===

  // Activate Clock Mode
  String activateClockMode() => _log("AR");

  // Set Time (HH, MM, SS)
  String setTime(int hours, int minutes, int seconds) {
    String h = hours.toString().padLeft(2, '0');
    String m = minutes.toString().padLeft(2, '0');
    String s = seconds.toString().padLeft(2, '0');
    return _log("TIME$h$m$s");
  }

  // Set Day (e.g., "MONDAY")
  String setDay(String dayName) => _log("DAY_$dayName");

  // Set Date (e.g., "15/06/2024")
  String setDate(String date) => _log("DATE_$date");

  // === GAME MODE ===

  // Start Match (totalSeconds = shooting time in seconds)
  String startMatch(int totalSeconds) => _log("ARTN$totalSeconds");

  // Pause Match
  String pauseMatch() => _log("ARTP");

  // Resume Match
  String resumeMatch() => _log("ARTR");

  // Reset Match
  String resetMatch() => _log("ARRT");

  // === ARCHER GROUPS ===

  // All 4 Archers (ABCD) - all green
  String showArchersABCD() => _log("ARM4");

  // 3 Archers (ABC) - all green
  String showArchersABC() => _log("ARM3");

  // First Group Shooting (AB=green, CD=grey)
  String showFirstGroupShooting() => _log("FGAB");

  // Second Group Shooting (AB=grey, CD=green)
  String showSecondGroupShooting() => _log("SGCD");

  // === END INFO ===

  // Set End Info Text (e.g., "SI END 1")
  String setEndInfo(String text) => _log("ARED$text");

  // === BUZZER ===

  // Trigger Single Buzzer Beep
  String triggerBuzzer() => _log("ARBZ");
}