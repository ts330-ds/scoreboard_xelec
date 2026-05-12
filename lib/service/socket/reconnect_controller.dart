import 'dart:async';
import 'package:flutter/foundation.dart';

/// Centralized exponential-backoff reconnect logic for socket services.
///
/// Schedule:  2s → 4s → 8s → 16s → 30s (capped).
/// `maxTotal` reach hote hi `onExhausted` fire hota hai — UI ko "Retry" button
/// dikhana chahiye, automatic retry band.
class ReconnectController {
  ReconnectController({
    this.tag = 'RECONNECT',
    this.initialDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(seconds: 30),
    this.maxTotal = const Duration(minutes: 2),
  });

  final String tag;
  final Duration initialDelay;
  final Duration maxDelay;
  final Duration maxTotal;

  Timer? _timer;
  int _attempt = 0;
  DateTime? _startedAt;
  bool _exhausted = false;

  int get attempt => _attempt;
  bool get isScheduled => _timer != null;
  bool get isExhausted => _exhausted;

  /// Schedule next reconnect attempt. `onAttempt` background-isolate me
  /// connect call kare. `onExhausted` jab budget khatm — caller UI me
  /// "Retry" button dikhae.
  void schedule({
    required void Function(int attempt) onAttempt,
    required void Function() onExhausted,
  }) {
    if (_exhausted) return;
    _startedAt ??= DateTime.now();

    final elapsed = DateTime.now().difference(_startedAt!);
    if (elapsed >= maxTotal) {
      debugPrint('[$tag] budget khatm (${elapsed.inSeconds}s) — giving up');
      _exhausted = true;
      _timer?.cancel();
      _timer = null;
      onExhausted();
      return;
    }

    final delay = _nextDelay();
    _attempt++;
    debugPrint('[$tag] attempt #$_attempt in ${delay.inSeconds}s');

    _timer?.cancel();
    _timer = Timer(delay, () {
      _timer = null;
      onAttempt(_attempt);
    });
  }

  Duration _nextDelay() {
    // 2, 4, 8, 16, 30, 30, 30...
    final exp = initialDelay.inMilliseconds * (1 << _attempt);
    return Duration(milliseconds: exp.clamp(0, maxDelay.inMilliseconds));
  }

  /// Connect succeed hone par call karo — counters reset.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _attempt = 0;
    _startedAt = null;
    _exhausted = false;
  }

  /// Pending retry cancel — session stop / cubit close pe.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// User ne manual "Retry" dabaya — budget reset karke turant try.
  void forceRetry(void Function() doConnect) {
    reset();
    doConnect();
  }

  void dispose() {
    cancel();
  }
}
