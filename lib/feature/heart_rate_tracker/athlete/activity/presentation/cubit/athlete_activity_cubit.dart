import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/data/model/activity_session_model.dart';
import 'athlete_activity_state.dart';

class AthleteActivityCubit extends Cubit<AthleteActivityState> {
  AthleteActivityCubit() : super(const AthleteActivityState());

  Timer? _timer;
  static const _uuid = Uuid();

  // ── Selection ─────────────────────────────────────────────────────────────

  void selectActivity(String type) =>
      emit(state.copyWith(selectedActivity: type));

  void selectDuration(int minutes) =>
      emit(state.copyWith(selectedDuration: minutes));

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> fetchLocation() async {
    emit(state.copyWith(isLoadingLocation: true, locationText: 'Fetching location...'));
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(state.copyWith(isLoadingLocation: false, locationText: 'Location permission denied'));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final place = placemarks.isNotEmpty ? placemarks.first : null;

      final address = place != null
          ? '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}'
              .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
              .replaceAll(RegExp(r',\s*,'), ',')
          : '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';

      emit(state.copyWith(isLoadingLocation: false, locationText: address));
    } catch (_) {
      emit(state.copyWith(isLoadingLocation: false, locationText: 'Unable to fetch location'));
    }
  }

  // ── Session ───────────────────────────────────────────────────────────────

  void startSession() {
    final session = ActivitySession(
      id: _uuid.v4(),
      activityType: state.selectedActivity,
      targetDurationMinutes: state.selectedDuration,
      startTime: DateTime.now(),
      location: state.locationText,
    );

    emit(state.copyWith(
      activeSession: session,
      elapsedSeconds: 0,
    ));

    _startTimer();
  }

  void stopSession() {
    _timer?.cancel();
    _timer = null;

    if (state.activeSession == null) return;

    final completed = state.activeSession!.copyWith(
      endTime: DateTime.now(),
      isCompleted: true,
    );

    emit(state.copyWith(
      sessions: [completed, ...state.sessions],
      clearActiveSession: true,
      elapsedSeconds: 0,
    ));
  }

  // Heart rate record karo active session me (UI se call hoga BlocListener k through)
  void recordHeartRate(int bpm) {
    if (!state.isSessionActive || bpm <= 0) return;

    final sample = HeartRateSample(time: DateTime.now(), bpm: bpm);
    final updated = state.activeSession!.copyWith(
      heartRateSamples: [...state.activeSession!.heartRateSamples, sample],
    );
    emit(state.copyWith(activeSession: updated));
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isSessionActive) {
        _timer?.cancel();
        return;
      }
      final newElapsed = state.elapsedSeconds + 1;
      emit(state.copyWith(elapsedSeconds: newElapsed));

      // Auto stop when target duration reached
      if (newElapsed >= state.activeSession!.targetDurationMinutes * 60) {
        stopSession();
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String formatSeconds(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
