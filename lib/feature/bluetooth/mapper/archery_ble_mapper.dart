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

// === INDIVIDUAL MODE SCREEN ===
  
  // Timer Settings
  /// Set timer duration in seconds (e.g., 20 for 20 seconds)
  /// Example: ARIT20
  String setTimerIndividuals(int seconds) => _log("ARIT$seconds");
  
  // Set Selection (Number of rounds)
  /// Set the number of rounds/sets in individual mode
  /// Example: ARSS3 (sets to 3 times)
  String setSelection(int rounds) => _log("ARSS$rounds");
  
  // Start Timer
  /// Starts the timer with 10 seconds practice and then according to the set
  String startTimer() => _log("ARIS");
  
  // === TEAM ROUND MODE ===
  
  /// Switch to team round mode
  String setTeamMode() => _log("ARTM");
  
  /// Set timer for team round
  /// Example: ARTI120 (for 120 seconds)
  String setTeamTimer(int seconds) => _log("ARTI$seconds");
  
  String startAlternateTimer() => _log("ARST");
   String pauseAlternateTimer() => _log("ARTP");
    String resumeAlternateTimer() => _log("ARTR");
  // === ARROW INDICATORS ===
  
  /// Arrow left - left will glow green and right will go grey
  String arrowLeft() => _log("ARAL");
  
  /// Arrow right - right will glow green and left will go grey
  String arrowRight() => _log("ARAR");
  
  String switchSide() => _log("ARTS");

  // === SET CONTROLS ===
  
  /// Set the number of sets
  /// Example: ARCS6 (for 6 sets)
  String setNumberOfSets(int sets) => _log("ARCS$sets");
  
  /// Skip to the next set
  String nextSet() => _log("ARNR");
  
  // === SCREEN MODE ===
  
  /// Switch to individual mode screen
  String setIndividualMode() => _log("ARIN");
  
  // === HELPER METHODS ===
  
  /// Reset to default state (if ESP32 supports it)
  String reset() => _log("ARRT");
  
  /// Set timer with minutes conversion
  String setTimerMinutes(int minutes) => setTimerIndividuals(minutes * 60);
  
  /// Set team timer with minutes conversion
  String setTeamTimerMinutes(int minutes) => setTeamTimer(minutes * 60);



  // === BUZZER ===

  // Trigger Single Buzzer Beep
  String triggerBuzzer() => _log("ARBZ");
}