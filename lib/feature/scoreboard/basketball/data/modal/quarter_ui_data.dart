class QuarterUiData {
  final int quarter;
  final bool isFinished;

  const QuarterUiData({
    required this.quarter,
    required this.isFinished,
  });

  @override
  bool operator ==(Object other) {
    return other is QuarterUiData &&
        other.quarter == quarter &&
        other.isFinished == isFinished;
  }

  @override
  int get hashCode => quarter.hashCode ^ isFinished.hashCode;
}