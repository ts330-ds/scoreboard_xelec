import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/athlete_model.dart';
import '../../../data/models/gate_model.dart';
import '../../../data/models/trial_result_model.dart';

part 'wizard_state.dart';

class WizardCubit extends Cubit<WizardState> {
  WizardCubit() : super(const WizardState());

  // ── Step 1 ───────────────────────────────────────────
  void setStep1({
    required String testName,
    required String protocol,
    required double distanceMeters,
    required DateTime date,
    required String location,
  }) {
    emit(state.copyWith(
      testName: testName,
      protocol: protocol,
      distanceMeters: distanceMeters,
      date: date,
      location: location,
      currentStep: 2,
    ));
  }

  // ── Step 2 ───────────────────────────────────────────
  void setStep2({required List<AthleteModel> athletes}) {
    emit(state.copyWith(athletes: athletes, currentStep: 3));
  }

  // ── Step 3 ───────────────────────────────────────────
  void setStep3({
    required GateModel masterGate,
    required GateModel slaveGate,
    List<GateModel>? intermediateGates,
  }) {
    emit(state.copyWith(
      masterGate: masterGate,
      slaveGate: slaveGate,
      intermediateGates: intermediateGates ?? [],
      currentStep: 4,
    ));
  }

  // ── Step 4 ───────────────────────────────────────────
  void setStep4({
    required String layoutDiagram,
    required String triggerMode,
    required int falseStartThresholdMs,
    required int resetDelaySeconds,
    required String timingResolution,
    required bool autoAdvanceAthletes,
  }) {
    emit(state.copyWith(
      layoutDiagram: layoutDiagram,
      triggerMode: triggerMode,
      falseStartThresholdMs: falseStartThresholdMs,
      resetDelaySeconds: resetDelaySeconds,
      timingResolution: timingResolution,
      autoAdvanceAthletes: autoAdvanceAthletes,
      currentStep: 5,
    ));
  }

  // ── Step 5 — add trial result ─────────────────────────
  void addTrialResult(TrialResultModel result) {
    final updated = [...state.results, result];
    emit(state.copyWith(results: updated));
  }

  void setCurrentStep(int step) {
    emit(state.copyWith(currentStep: step));
  }

  void reset() => emit(const WizardState());
}
