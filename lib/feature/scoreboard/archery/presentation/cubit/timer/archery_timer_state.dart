part of 'archery_timer_cubit.dart';

enum TimerPhase { red, green, yellow, stopped }

class ArcheryTimerState extends Equatable {
  final TimerPhase phase;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isPaused;

  const ArcheryTimerState({
    this.phase = TimerPhase.stopped,
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.isRunning = false,
    this.isPaused = false,
  });

  /// Get color based on current phase
  Color get phaseColor {
    switch (phase) {
      case TimerPhase.red:
        return const Color(0xFFFF0000);
      case TimerPhase.green:
        return const Color(0xFF00FF00);
      case TimerPhase.yellow:
        return const Color(0xFFFFFF00);
      case TimerPhase.stopped:
        return const Color(0xFF00FF00); // Default green when stopped
    }
  }

  /// Format seconds to display string (000 format for single display, or MM:SS)
  String get displayTime {
    if (remainingSeconds < 100) {
      return remainingSeconds.toString().padLeft(3, '0');
    } else {
      final mins = remainingSeconds ~/ 60;
      final secs = remainingSeconds % 60;
      return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  ArcheryTimerState copyWith({
    TimerPhase? phase,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    bool? isPaused,
  }) {
    return ArcheryTimerState(
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override
  List<Object?> get props => [phase, remainingSeconds, totalSeconds, isRunning, isPaused];
}
