import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/athlete_model.dart';
import '../../../data/models/trial_result_model.dart';

part 'run_test_state.dart';

class RunTestCubit extends Cubit<RunTestState> {
  Timer? _countdownTimer;
  Timer? _runTimer;
  final Stopwatch _stopwatch = Stopwatch();

  RunTestCubit() : super(const RunTestIdle());

  // ── Initialize with athlete list ─────────────────────
  void initialize({
    required List<AthleteModel> athletes,
    required bool autoAdvance,
  }) {
    if (athletes.isEmpty) return;
    _athletes = athletes;
    _autoAdvance = autoAdvance;
    _curAthIdx = 0;
    _curTrial = 1;
    _emitReady();
  }

  List<AthleteModel> _athletes = [];
  bool _autoAdvance = true;
  int _curAthIdx = 0;
  int _curTrial = 1;
  final List<TrialResultModel> _allResults = [];

  AthleteModel get _currentAthlete => _athletes[_curAthIdx];

  // ── STEP A: Start countdown ───────────────────────────
  void startCountdown() {
    int count = 3;
    emit(RunTestCountdown(count: count));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      count--;
      if (count > 0) {
        emit(RunTestCountdown(count: count));
      } else {
        t.cancel();
        _startTimer();
      }
    });
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    _emitReady();
  }

  // ── STEP B: Timer running ─────────────────────────────
  void _startTimer() {
    _stopwatch.reset();
    _stopwatch.start();

    emit(RunTestRunning(
      elapsed: Duration.zero,
      currentAthlete: _currentAthlete,
      currentTrial: _curTrial,
    ));

    _runTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (isClosed) return;
      emit(RunTestRunning(
        elapsed: _stopwatch.elapsed,
        currentAthlete: _currentAthlete,
        currentTrial: _curTrial,
      ));
    });
  }

  // ── STEP C: Stop timer (BLE beam-break OR manual) ─────
  void stopTimer({required bool isManual}) {
    _stopwatch.stop();
    _runTimer?.cancel();

    final seconds = _stopwatch.elapsedMilliseconds / 1000.0;

    emit(RunTestTrialResult(
      currentAthlete: _currentAthlete,
      currentTrial: _curTrial,
      timeSeconds: seconds,
      isManualStop: isManual,
      previousBest: _bestForCurrentAthlete(),
    ));
  }

  // ── STEP D: Accept trial ──────────────────────────────
  void acceptTrial(double time) {
    final result = TrialResultModel(
      athleteId: _currentAthlete.id,
      athleteName: _currentAthlete.name,
      trialNumber: _curTrial,
      timeSeconds: time,
      isManualStop: state is RunTestTrialResult
          ? (state as RunTestTrialResult).isManualStop
          : false,
    );
    _allResults.add(result);

    _advance();
  }

  // ── STEP D: Reject trial ──────────────────────────────
  void rejectTrial() {
    _emitReady(); // same athlete, same trial
  }

  // ── Internal helpers ──────────────────────────────────
  void _advance() {
    final totalTrialsForAthlete = _currentAthlete.trials;

    if (_curTrial < totalTrialsForAthlete) {
      // Next trial same athlete
      _curTrial++;
      _emitReady();
    } else if (_curAthIdx < _athletes.length - 1) {
      // Next athlete
      _curAthIdx++;
      _curTrial = 1;
      _emitReady();
    } else {
      // All done!
      emit(RunTestAllDone(allResults: List.unmodifiable(_allResults)));
    }
  }

  void _emitReady() {
    final upcoming = _athletes.skip(_curAthIdx + 1).take(3).toList();
    emit(RunTestReady(
      currentAthlete: _currentAthlete,
      currentTrial: _curTrial,
      totalTrials: _currentAthlete.trials,
      upcomingAthletes: upcoming,
      completedTrials: _allResults.length,
      totalExpected: _athletes.fold(0, (s, a) => s + a.trials),
    ));
  }

  double? _bestForCurrentAthlete() {
    final times = _allResults
        .where((r) => r.athleteId == _currentAthlete.id)
        .map((r) => r.timeSeconds)
        .toList();
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a < b ? a : b);
  }

  List<TrialResultModel> get collectedResults => List.unmodifiable(_allResults);

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _runTimer?.cancel();
    _stopwatch.stop();
    return super.close();
  }
}
