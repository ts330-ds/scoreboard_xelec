/// A single R-R interval sample. [stampSec] is always normalized to *seconds*
/// since epoch (the SQL layer stores seconds), regardless of how the device
/// originally reported it (ms or s).
class RrSample {
  final int stampSec;
  final int value;

  const RrSample({required this.stampSec, required this.value});

  /// Builds from a legacy map (`{stamp, value}`). `stamp` may be in seconds or
  /// milliseconds — it is normalized to seconds.
  factory RrSample.fromMap(Map<dynamic, dynamic> m) {
    final raw = (m['stamp'] as num?)?.toInt() ?? 0;
    final sec = raw > 9999999999 ? raw ~/ 1000 : raw;
    return RrSample(
      stampSec: sec,
      value: (m['value'] as num?)?.toInt() ?? 0,
    );
  }

  DateTime get time => DateTime.fromMillisecondsSinceEpoch(stampSec * 1000);
}
