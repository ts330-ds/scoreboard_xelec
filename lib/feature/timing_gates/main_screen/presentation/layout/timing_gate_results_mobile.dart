import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/test_session_model.dart';
import 'package:xelex_esp/router/timing_gate_path.dart';

class TimingGateResultsMobile extends StatelessWidget {
  const TimingGateResultsMobile({super.key});

  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _border = Color(0xFFDDE3EC);
  static const _gold = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: ValueListenableBuilder<Box<TestSessionModel>>(
                valueListenable:
                    Hive.box<TestSessionModel>('sessions').listenable(),
                builder: (context, box, _) {
                  final completed = box.values
                      .where((s) => s.isCompleted)
                      .toList()
                    ..sort((a, b) {
                      final aDate = a.completedAt ?? a.date;
                      final bDate = b.completedAt ?? b.date;
                      return bDate.compareTo(aDate);
                    });
                  return completed.isEmpty
                      ? _buildEmptyState()
                      : _buildList(completed);
                },
              ),
            ),
          ],
        ),
      ),
    );  // Scaffold
  }

  Widget _buildHeader() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: _primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Results',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _border, width: 2),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: _subtext,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Results Yet',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete a test session to see\nresults here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _subtext,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<TestSessionModel> sessions) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => _openDetail(ctx, sessions[i]),
        child: _buildSessionBlock(sessions[i]),
      ),
    );
  }

  void _openDetail(BuildContext context, TestSessionModel session) {
    context.push(TimingGatePaths.timingGateSessionDetail, extra: session);
  }

  Widget _buildSessionBlock(TestSessionModel session) {
    // Sort athletes by best time (nulls at the end)
    final ranked = [...session.results]..sort((a, b) {
        final aBest = a.bestTime;
        final bBest = b.bestTime;
        if (aBest == null && bBest == null) return 0;
        if (aBest == null) return 1;
        if (bBest == null) return -1;
        return session.isYoyo
            ? bBest.compareTo(aBest) // YOYO: higher level = better
            : aBest.compareTo(bBest); // Normal: faster = better
      });

    // Winner info
    final winner = ranked.isNotEmpty ? ranked.first : null;
    final winnerBest = winner?.bestTime;
    final athleteCount = session.results.length;
    final completedTrials = session.results.fold<int>(
        0, (sum, r) => sum + r.completedTrials.length);

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Session header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.sessionName,
                        style: const TextStyle(
                            color: _text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: _subtext, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: _subtext, size: 13),
                    const SizedBox(width: 4),
                    Text(session.modeLabel,
                        style: const TextStyle(
                            color: _subtext, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_outlined,
                        color: _subtext, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(session.completedAt ?? session.date),
                      style: const TextStyle(
                          color: _subtext, fontSize: 12),
                    ),
                    if (session.location.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined,
                          color: _subtext, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.location,
                          style: const TextStyle(
                              color: _subtext, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────
          const Divider(height: 1, color: _border),

          // ── Summary: Winner + Stats ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                // Winner info
                if (winner != null) ...[
                  // Trophy icon
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _gold.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events,
                        color: _gold, size: 18),
                  ),
                  const SizedBox(width: 10),
                  // Winner name + best time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          winner.fullName,
                          style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          winnerBest != null
                              ? (session.isYoyo
                                  ? 'Level ${winnerBest.toStringAsFixed(1)}'
                                  : '${winnerBest.toStringAsFixed(3)}s')
                              : 'No time',
                          style: const TextStyle(
                              color: _gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const Expanded(
                    child: Text('No results',
                        style: TextStyle(color: _subtext, fontSize: 12)),
                  ),

                // Stats badges
                _statBadge(Icons.people_outline, '$athleteCount'),
                const SizedBox(width: 8),
                _statBadge(Icons.flag_outlined, '$completedTrials'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Small stat badge (icon + number) ──────────────────────────────────────
  Widget _statBadge(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _primary, size: 14),
          const SizedBox(width: 4),
          Text(value,
              style: const TextStyle(
                  color: _primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
