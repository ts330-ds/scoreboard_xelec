import '../models/session_model.dart';
import '../models/trial_result_model.dart';

class CsvExport {
  CsvExport._();

  static String generateSessionCsv(SessionModel session) {
    final buffer = StringBuffer();

    // Header info
    buffer.writeln('APEX Timing Gates — Session Export');
    buffer.writeln('Test Name,${session.testName}');
    buffer.writeln('Protocol,${session.protocol.toUpperCase()}');
    buffer.writeln('Distance,${session.distanceMeters}m');
    buffer.writeln('Location,${session.location}');
    buffer.writeln('Date,${_formatDate(session.date)}');
    buffer.writeln();

    // Leaderboard header
    final maxTrials = session.athletes.isEmpty
        ? 3
        : session.athletes.map((a) => a.trials).reduce((a, b) => a > b ? a : b);

    final trialHeaders = List.generate(maxTrials, (i) => 'T${i + 1}').join(',');
    buffer.writeln('Rank,Name,ID,Team,$trialHeaders,Best,Avg,Δ Best');

    // Rows sorted by best time
    final board = session.leaderboard;
    if (board.isEmpty) return buffer.toString();

    final overallBest = board.first.bestTime;

    for (int i = 0; i < board.length; i++) {
      final entry = board[i];
      final trialTimes = List.generate(maxTrials, (j) {
        final trial = entry.trials.where((t) => t.trialNumber == j + 1).firstOrNull;
        return trial != null ? trial.timeSeconds.toStringAsFixed(3) : '—';
      }).join(',');

      final delta = entry.bestTime - overallBest;
      final deltaStr = delta == 0 ? '—BEST—' : '+${delta.toStringAsFixed(3)}s';

      buffer.writeln(
        '${i + 1},'
        '${entry.athlete.name},'
        '${entry.athlete.id},'
        '${entry.athlete.team},'
        '$trialTimes,'
        '${entry.bestTime.toStringAsFixed(3)},'
        '${entry.avgTime.toStringAsFixed(3)},'
        '$deltaStr',
      );
    }

    return buffer.toString();
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// Extension for nullable firstOrNull
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
