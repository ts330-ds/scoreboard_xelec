/// BLE Command Mapper for Archery Scoreboard
/// Firmware: P6_Archery_Pro
class ArcheryBleMapper {
  // ======================
  // SCREEN MODE
  // ======================

  /// Switch to Clock display mode
  String showClockScreen() => "AR";

  // ======================
  // GAME CONTROL
  // ======================

  /// Start a new archery match with specified total time in seconds
  /// This triggers: 10 second RED countdown → GREEN phase → ORANGE (last 30s) → RED end
  /// Example: startMatch(120) for 2 minutes
  String startMatch(int totalTimeSeconds) {
    assert(totalTimeSeconds > 0);
    return "ARTN$totalTimeSeconds";
  }

  /// Pause the running timer
  String pauseTimer() => "ARTP";

  /// Resume the paused timer
  String resumeTimer() => "ARTR";

  /// Reset game to IDLE state (timer = 0, phase = IDLE)
  String resetGame() => "ARRT";

  // ======================
  // TARGET/LANE MODES (Bottom Text)
  // ======================

  /// Mode 4: All targets active (A B C D - all green)
  String setMode4Targets() => "ARM4";

  /// Mode 3: Three targets active (A B C - all green)
  String setMode3Targets() => "ARM3";

  /// First Group: A B active (A B green, C D grey)
  String setFirstGroupAB() => "FGAB";

  /// Second Group: C D active (A B grey, C D green)
  String setSecondGroupCD() => "SGCD";

  // ======================
  // INFO TEXT (End/Round Display)
  // ======================

  /// Set the info text displayed on screen
  /// Example: "SIGHTER END 1", "END 2", "PRACTICE"
  String setInfoText(String text) => "ARED$text";

  // ======================
  // BUZZER
  // ======================

  /// Trigger buzzer once (manual beep)
  String triggerBuzzer() => "ARBZ";

  // ======================
  // CLOCK SETTINGS
  // ======================

  /// Set internal clock time
  /// [hour] 0-23, [minute] 0-59, [second] 0-59
  String setTime(int hour, int minute, int second) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    final s = second.toString().padLeft(2, '0');
    return "TIME$h$m$s";
  }

  /// Set day of week display
  /// Example: "MONDAY", "TUESDAY"
  String setDayOfWeek(String day) => "DAY_$day";

  /// Set date display
  /// Example: "01/01/2024", "25/12/2024"
  String setDate(String date) => "DATE_$date";

  // ======================
  // CONVENIENCE METHODS
  // ======================

  /// Set current DateTime to the display
  String syncDateTime(DateTime dateTime) {
    return setTime(dateTime.hour, dateTime.minute, dateTime.second);
  }

  /// Get day name from DateTime
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

  /// Sync full date and time
  List<String> syncFullDateTime(DateTime dateTime) {
    final day = getDayName(dateTime);
    final date =
        "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";

    return [
      setTime(dateTime.hour, dateTime.minute, dateTime.second),
      setDayOfWeek(day),
      setDate(date),
    ];
  }

  /// Start a standard 2-minute (120s) match
  String startStandardMatch() => startMatch(120);

  /// Start a 4-minute (240s) match
  String start4MinuteMatch() => startMatch(240);
}