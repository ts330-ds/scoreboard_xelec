part of 'wizard_cubit.dart';

class WizardState extends Equatable {
  // Step 1
  final String testName;
  final String protocol;
  final double distanceMeters;
  final DateTime? date;
  final String location;

  // Step 2
  final List<AthleteModel> athletes;

  // Step 3
  final GateModel? masterGate;
  final GateModel? slaveGate;
  final List<GateModel> intermediateGates;

  // Step 4
  final String layoutDiagram;
  final String triggerMode;
  final int falseStartThresholdMs;
  final int resetDelaySeconds;
  final String timingResolution;
  final bool autoAdvanceAthletes;

  // Step 5 accumulated results
  final List<TrialResultModel> results;

  // Navigation
  final int currentStep;

  const WizardState({
    this.testName = '',
    this.protocol = '',
    this.distanceMeters = 40.0,
    this.date,
    this.location = '',
    this.athletes = const [],
    this.masterGate,
    this.slaveGate,
    this.intermediateGates = const [],
    this.layoutDiagram = 'linear',
    this.triggerMode = 'auto',
    this.falseStartThresholdMs = 100,
    this.resetDelaySeconds = 5,
    this.timingResolution = '0.001',
    this.autoAdvanceAthletes = true,
    this.results = const [],
    this.currentStep = 1,
  });

  bool get step1Valid => testName.isNotEmpty && protocol.isNotEmpty;
  bool get step2Valid => athletes.isNotEmpty;
  bool get step3Valid => masterGate != null && slaveGate != null;

  int get totalTrials => athletes.fold(0, (sum, a) => sum + a.trials);

  WizardState copyWith({
    String? testName,
    String? protocol,
    double? distanceMeters,
    DateTime? date,
    String? location,
    List<AthleteModel>? athletes,
    GateModel? masterGate,
    GateModel? slaveGate,
    List<GateModel>? intermediateGates,
    String? layoutDiagram,
    String? triggerMode,
    int? falseStartThresholdMs,
    int? resetDelaySeconds,
    String? timingResolution,
    bool? autoAdvanceAthletes,
    List<TrialResultModel>? results,
    int? currentStep,
  }) {
    return WizardState(
      testName: testName ?? this.testName,
      protocol: protocol ?? this.protocol,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      date: date ?? this.date,
      location: location ?? this.location,
      athletes: athletes ?? this.athletes,
      masterGate: masterGate ?? this.masterGate,
      slaveGate: slaveGate ?? this.slaveGate,
      intermediateGates: intermediateGates ?? this.intermediateGates,
      layoutDiagram: layoutDiagram ?? this.layoutDiagram,
      triggerMode: triggerMode ?? this.triggerMode,
      falseStartThresholdMs: falseStartThresholdMs ?? this.falseStartThresholdMs,
      resetDelaySeconds: resetDelaySeconds ?? this.resetDelaySeconds,
      timingResolution: timingResolution ?? this.timingResolution,
      autoAdvanceAthletes: autoAdvanceAthletes ?? this.autoAdvanceAthletes,
      results: results ?? this.results,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  @override
  List<Object?> get props => [
    testName, protocol, distanceMeters, date, location,
    athletes, masterGate, slaveGate, intermediateGates,
    layoutDiagram, triggerMode, falseStartThresholdMs,
    resetDelaySeconds, timingResolution, autoAdvanceAthletes,
    results, currentStep,
  ];
}
