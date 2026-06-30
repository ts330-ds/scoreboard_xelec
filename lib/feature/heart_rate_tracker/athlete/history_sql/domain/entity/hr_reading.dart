/// A single heart-rate sample. [stampSec] is always normalized to *seconds*
/// since epoch (the SQL layer stores seconds), regardless of how the device
/// originally reported it (ms or s).
class HrReading {
  final int stampSec;
  final int heartRate;

  const HrReading({required this.stampSec, required this.heartRate});

  /// Builds from a legacy map (`{stamp, heartRate}`). `stamp` may be in
  /// seconds or milliseconds — it is normalized to seconds.
  factory HrReading.fromMap(Map<dynamic, dynamic> m) {
    final raw = (m['stamp'] as num?)?.toInt() ?? 0;
    final sec = raw > 9999999999 ? raw ~/ 1000 : raw;
    return HrReading(
      stampSec: sec,
      heartRate: (m['heartRate'] as num?)?.toInt() ?? 0,
    );
  }

  DateTime get time =>
      DateTime.fromMillisecondsSinceEpoch(stampSec * 1000);

  /// Shape expected by the existing pure chart/sleep widgets
  /// (they read `'stamp'` + `'heartRate'`).
  Map<String, dynamic> toLegacyMap() => {
        'stamp': stampSec,
        'heartRate': heartRate,
      };
}
