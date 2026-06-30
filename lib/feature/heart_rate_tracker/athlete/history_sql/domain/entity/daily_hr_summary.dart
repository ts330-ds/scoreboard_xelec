import 'package:equatable/equatable.dart';

/// Pre-aggregated per-day HR stats, computed by the database (GROUP BY day)
/// instead of in Dart. Powers the date tabs and the AVG/MAX/MIN cards.
class DailyHrSummary extends Equatable {
  /// Local midnight of the day.
  final DateTime date;
  final int avg;
  final int max;
  final int min;
  final int count;

  const DailyHrSummary({
    required this.date,
    required this.avg,
    required this.max,
    required this.min,
    required this.count,
  });

  @override
  List<Object?> get props => [date, avg, max, min, count];
}
