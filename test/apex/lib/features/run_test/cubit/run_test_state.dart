part of 'run_test_cubit.dart';

abstract class RunTestState extends Equatable {
  const RunTestState();
  @override List<Object?> get props => [];
}

class RunTestIdle extends RunTestState {
  const RunTestIdle();
}

class RunTestReady extends RunTestState {
  final AthleteModel currentAthlete;
  final int currentTrial;
  final int totalTrials;
  final List<AthleteModel> upcomingAthletes;
  final int completedTrials;
  final int totalExpected;

  const RunTestReady({
    required this.currentAthlete,
    required this.currentTrial,
    required this.totalTrials,
    required this.upcomingAthletes,
    required this.completedTrials,
    required this.totalExpected,
  });

  @override
  List<Object?> get props => [
    currentAthlete, currentTrial, totalTrials,
    upcomingAthletes, completedTrials, totalExpected
  ];
}

class RunTestCountdown extends RunTestState {
  final int count; // 3, 2, 1
  const RunTestCountdown({required this.count});
  @override List<Object?> get props => [count];
}

class RunTestRunning extends RunTestState {
  final Duration elapsed;
  final AthleteModel currentAthlete;
  final int currentTrial;

  const RunTestRunning({
    required this.elapsed,
    required this.currentAthlete,
    required this.currentTrial,
  });

  double get seconds => elapsed.inMilliseconds / 1000.0;
  String get formattedTime => seconds.toStringAsFixed(3);

  @override
  List<Object?> get props => [elapsed, currentAthlete, currentTrial];
}

class RunTestTrialResult extends RunTestState {
  final AthleteModel currentAthlete;
  final int currentTrial;
  final double timeSeconds;
  final bool isManualStop;
  final double? previousBest;

  const RunTestTrialResult({
    required this.currentAthlete,
    required this.currentTrial,
    required this.timeSeconds,
    required this.isManualStop,
    this.previousBest,
  });

  String get formattedTime => timeSeconds.toStringAsFixed(3);

  String? get deltaVsBest {
    if (previousBest == null) return null;
    final delta = timeSeconds - previousBest!;
    if (delta <= 0) return '🏆 New Best!';
    return '+${delta.toStringAsFixed(3)}s vs best';
  }

  @override
  List<Object?> get props => [currentAthlete, currentTrial, timeSeconds, isManualStop, previousBest];
}

class RunTestAllDone extends RunTestState {
  final List<TrialResultModel> allResults;
  const RunTestAllDone({required this.allResults});
  @override List<Object?> get props => [allResults];
}
