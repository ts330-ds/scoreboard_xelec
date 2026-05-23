import 'package:equatable/equatable.dart';

enum RangePreset {
  last1h,
  last2h,
  last4h,
  last6h,
  last24h,
  last7d,
  last30d,
  all,
  custom,
}

class HistoryState extends Equatable {
  final RangePreset preset;
  final DateTime? customFrom;
  final DateTime? customTo;

  const HistoryState({
    this.preset = RangePreset.all,
    this.customFrom,
    this.customTo,
  });

  /// Returns the effective filter window. `null` means open-ended.
  ({DateTime? from, DateTime? to}) effectiveWindow() {
    final now = DateTime.now();
    switch (preset) {
      case RangePreset.last1h:
        return (from: now.subtract(const Duration(hours: 1)), to: now);
      case RangePreset.last2h:
        return (from: now.subtract(const Duration(hours: 2)), to: now);
      case RangePreset.last4h:
        return (from: now.subtract(const Duration(hours: 4)), to: now);
      case RangePreset.last6h:
        return (from: now.subtract(const Duration(hours: 6)), to: now);
      case RangePreset.last24h:
        return (from: now.subtract(const Duration(hours: 24)), to: now);
      case RangePreset.last7d:
        return (
          from: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 6)),
          to: now,
        );
      case RangePreset.last30d:
        return (
          from: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 29)),
          to: now,
        );
      case RangePreset.all:
        return (from: null, to: null);
      case RangePreset.custom:
        return (from: customFrom, to: customTo);
    }
  }

  HistoryState copyWith({
    RangePreset? preset,
    DateTime? customFrom,
    DateTime? customTo,
    bool clearCustom = false,
  }) {
    return HistoryState(
      preset: preset ?? this.preset,
      customFrom: clearCustom ? null : (customFrom ?? this.customFrom),
      customTo: clearCustom ? null : (customTo ?? this.customTo),
    );
  }

  @override
  List<Object?> get props => [preset, customFrom, customTo];
}
