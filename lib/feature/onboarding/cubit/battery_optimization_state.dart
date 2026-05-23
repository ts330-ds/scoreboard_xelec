class BatteryOptimizationState {
  final bool ignoring;
  final String manufacturer;
  final bool busy;

  const BatteryOptimizationState({
    this.ignoring = false,
    this.manufacturer = '',
    this.busy = false,
  });

  bool get isAggressiveOem {
    const aggressive = ['xiaomi', 'redmi', 'poco', 'vivo', 'oppo', 'realme', 'oneplus', 'honor', 'huawei'];
    return aggressive.any(manufacturer.contains);
  }

  BatteryOptimizationState copyWith({
    bool? ignoring,
    String? manufacturer,
    bool? busy,
  }) =>
      BatteryOptimizationState(
        ignoring: ignoring ?? this.ignoring,
        manufacturer: manufacturer ?? this.manufacturer,
        busy: busy ?? this.busy,
      );
}
