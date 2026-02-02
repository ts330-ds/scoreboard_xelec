class ArcheryBleMapper {

  // ======================
  // GAME CONTROLS
  // ======================

  /// Start game with specified time in seconds
  String startGame(int seconds) {
    assert(seconds > 0);
    print("START_$seconds");
    return "START_$seconds";
  }

  String pauseGame() => "PAUSE";
  String resumeGame() => "RESUME";
  String resetGame() => "RESET";

  // ======================
  // SCREEN MODES
  // ======================

  /// Switch to clock display mode
  String setModeClock() => "MODEC";

  /// Archery mode: A B C D all green
  String setMode4Archers() => "MODE4";

  /// Archery mode: A B C all green
  String setMode3Archers() => "MODE3";

  // ======================
  // SPLIT/GROUP MODES
  // ======================

  /// First Group: A B green, C D grey
  String setFirstGroupAB() => "FG_AB";

  /// Second Group: C D green, A B grey
  String setSecondGroupCD() => "SG_CD";

  // ======================
  // CLOCK SETTINGS
  // ======================

  /// Set time (24-hour format: HH, MM, SS)
  String setTime(int hour, int minute, int second) {
    assert(hour >= 0 && hour <= 23);
    assert(minute >= 0 && minute <= 59);
    assert(second >= 0 && second <= 59);
    String h = hour.toString().padLeft(2, '0');
    String m = minute.toString().padLeft(2, '0');
    String s = second.toString().padLeft(2, '0');
    print("TIME$h$m$s");
    return "TIME$h$m$s";
  }

  /// Set time from DateTime object
  String setTimeFromDateTime(DateTime dateTime) {
    return setTime(dateTime.hour, dateTime.minute, dateTime.second);
  }

  /// Sync current system time
  String syncCurrentTime() {
    return setTimeFromDateTime(DateTime.now());
  }

  // ======================
  // DAY & DATE DISPLAY
  // ======================

  /// Set day text (e.g., "MONDAY", "TUESDAY")
  String setDay(String day) {
    print("DAY_${day.toUpperCase()}");
    return "DAY_${day.toUpperCase()}";
  }

  /// Set date text (e.g., "25/12/2024")
  String setDate(String date) {
    print("DATE_${date.toUpperCase()}");
    return "DATE_${date.toUpperCase()}";
  }

  // ======================
  // ARCHERY INFO TEXT
  // ======================

  /// Set info text displayed on screen (e.g., "SIGHTER END 1")
  String setInfoText(String text) {
    print("TXT_${text.toUpperCase()}");
    return "TXT_${text.toUpperCase()}";
  }

  // ======================
  // BRIGHTNESS & HARDWARE
  // ======================

  String setBrightness(int value) {
    assert(value >= 0 && value <= 255);
    return "BRIGHT_$value";
  }

  // ======================
  // SCREEN RESET
  // ======================

  String resetScreen() => "RESET";
}