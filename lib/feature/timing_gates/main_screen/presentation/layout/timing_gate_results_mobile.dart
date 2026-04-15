import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/test_session_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/trial_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/repository/session_repository.dart';
import 'package:xelex_esp/router/timing_gate_path.dart';

class TimingGateResultsMobile extends StatefulWidget {
  const TimingGateResultsMobile({super.key});

  @override
  State<TimingGateResultsMobile> createState() =>
      _TimingGateResultsMobileState();
}

class _TimingGateResultsMobileState extends State<TimingGateResultsMobile> {
  bool _seeding = false;

  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _border = Color(0xFFDDE3EC);
  static const _gold = Color(0xFFD97706);

  // ── Dev: seed a large test session ────────────────────────────────────────
  Future<void> _seedLargeSession() async {
    if (_seeding) return;
    setState(() => _seeding = true);
    try {
      const uuid = Uuid();
      final rng = Random();

      const gateCount = 20; // Master + 19 timing gates
      const segCount = gateCount - 1; // 19 segments
      const segDist = 5.0; // 5 m per segment → 95 m total

      // gateDistances: [Master=0, seg1=5, seg2=5, ..., seg19=5]
      final gateDists = [0.0, ...List.filled(segCount, segDist)];

      // ── Helper: simulate one trial ────────────────────────────────────
      TrialResultModel makeTrialForAthlete(int trialNum, double athleteBonus) {
        // First segment (from rest): slow; subsequent segments faster then plateau
        final splits = <double>[];
        final speeds = <double>[];
        final segTimes = <double>[];

        for (int i = 0; i < segCount; i++) {
          double base;
          if (i == 0) {
            base = 1.35 + rng.nextDouble() * 0.25; // 1.35–1.60s
          } else if (i < 5) {
            base = 0.78 - i * 0.03 + rng.nextDouble() * 0.06; // accelerating
          } else if (i < 12) {
            base = 0.63 + rng.nextDouble() * 0.05; // peak speed
          } else {
            base = 0.65 + (i - 12) * 0.01 + rng.nextDouble() * 0.04; // mild decel
          }
          final t = double.parse(
              ((base - athleteBonus).clamp(0.45, 2.0)).toStringAsFixed(3));
          splits.add(t);
          segTimes.add(t);
          speeds.add(segDist / t);
        }

        final accels = <double>[];
        for (int i = 0; i < speeds.length; i++) {
          final vPrev = i == 0 ? 0.0 : speeds[i - 1];
          accels.add(double.parse(
              ((speeds[i] - vPrev) / segTimes[i]).toStringAsFixed(3)));
        }

        final totalTime = double.parse(
            splits.fold(0.0, (a, b) => a + b).toStringAsFixed(3));

        return TrialResultModel(
          trialNumber: trialNum,
          totalTime: totalTime,
          splits: splits,
          status: 'completed',
          timestamp: DateTime.now(),
          speeds: speeds,
          accelerations: accels,
        );
      }

      // ── 50 athletes ───────────────────────────────────────────────────
      const firstNames = [
        'Aarav', 'Vihaan', 'Arjun', 'Rohan', 'Karan', 'Dev', 'Ayaan', 'Kabir',
        'Ishaan', 'Reyansh', 'Aditya', 'Siddharth', 'Vivaan', 'Neel', 'Dhruv',
        'Shaurya', 'Arnav', 'Yash', 'Pranav', 'Ansh', 'Samar', 'Kunal', 'Nikhil',
        'Mihir', 'Param', 'Ritvik', 'Laksh', 'Vedant', 'Ahan', 'Rudra',
        'Priya', 'Ananya', 'Diya', 'Kavya', 'Ishita', 'Aisha', 'Riya', 'Sneha',
        'Pooja', 'Meera', 'Shruti', 'Tara', 'Anya', 'Nisha', 'Aditi',
        'Carlos', 'James', 'Luca', 'Omar', 'Yuki',
      ];
      const lastNames = [
        'Sharma', 'Patel', 'Singh', 'Kumar', 'Verma', 'Gupta', 'Joshi',
        'Nair', 'Rao', 'Reddy', 'Mehta', 'Shah', 'Kapoor', 'Malhotra',
        'Bose', 'Das', 'Iyer', 'Pillai', 'Menon', 'Saxena',
      ];

      final athletes = <AthleteModel>[];
      final results = <AthleteResultModel>[];

      for (int i = 0; i < 50; i++) {
        final id = uuid.v4();
        final name =
            '${firstNames[i % firstNames.length]} ${lastNames[i % lastNames.length]}';
        // Bonus makes each athlete slightly different in speed
        final bonus = (i / 50) * 0.12; // 0 → 0.12s per segment spread

        athletes.add(AthleteModel(
          id: id,
          fullName: name,
          athleteId: 'ATH${(i + 1).toString().padLeft(3, '0')}',
          bib: '${i + 1}',
          dob: '',
          age: 18 + (i % 12),
          sex: i < 30 ? 'Male' : 'Female',
          discipline: 'Sprint',
          team: i < 25 ? 'Team Alpha' : 'Team Beta',
          trials: 3,
          completedTrials: 3,
        ));

        results.add(AthleteResultModel(
          athleteId: id,
          fullName: name,
          bib: '${i + 1}',
          team: i < 25 ? 'Team Alpha' : 'Team Beta',
          discipline: 'Sprint',
          trials: [
            makeTrialForAthlete(1, bonus),
            makeTrialForAthlete(2, bonus + 0.01),
            makeTrialForAthlete(3, bonus - 0.005),
          ],
        ));
      }

      final sessionId = uuid.v4();
      final session = TestSessionModel(
        id: sessionId,
        sessionName: '🧪 Stress Test — 50 Athletes / 20 Gates',
        date: DateTime.now(),
        mode: 'linear',
        subMode: 'sprint',
        protocol: 'custom',
        customDistance: segDist * segCount,
        trialMode: 'round_robin',
        trialsCount: 3,
        status: 'completed',
        athletes: athletes,
        results: results,
        location: 'Dev Sandbox',
        notes: 'Auto-generated stress-test session',
        completedAt: DateTime.now(),
        gateDistances: gateDists,
      );

      await GetIt.instance<SessionRepository>().save(session);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Stress-test session saved — 50 athletes, 20 gates'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Seed failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

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
    );
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
          // const Spacer(),
          // // ── DEV ONLY: seed stress-test session ───────────────────────
          // if (kDebugMode)
          //   _seeding
          //       ? const SizedBox(
          //           width: 20,
          //           height: 20,
          //           child: CircularProgressIndicator(strokeWidth: 2),
          //         )
          //       : Tooltip(
          //           message: 'Seed 50 athletes / 20 gates (Dev)',
          //           child: IconButton(
          //             onPressed: _seedLargeSession,
          //             icon: const Icon(Icons.science_outlined,
          //                 color: Color(0xFF7C3AED)),
          //             iconSize: 22,
          //             padding: EdgeInsets.zero,
          //             constraints: const BoxConstraints(),
          //           ),
          //         ),
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
    final ranked = [...session.results]..sort((a, b) {
        final aBest = a.bestTime;
        final bBest = b.bestTime;
        if (aBest == null && bBest == null) return 0;
        if (aBest == null) return 1;
        if (bBest == null) return -1;
        return session.isYoyo
            ? bBest.compareTo(aBest)
            : aBest.compareTo(bBest);
      });

    final winner = ranked.isNotEmpty ? ranked.first : null;
    final winnerBest = winner?.bestTime;
    final athleteCount = session.results.length;
    final completedTrials = session.results
        .fold<int>(0, (sum, r) => sum + r.completedTrials.length);

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Session header ──────────────────────────────────────────
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
                    const Icon(Icons.chevron_right, color: _subtext, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: _subtext, size: 13),
                    const SizedBox(width: 4),
                    Text(session.modeLabel,
                        style: const TextStyle(color: _subtext, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_outlined,
                        color: _subtext, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(session.completedAt ?? session.date),
                      style: const TextStyle(color: _subtext, fontSize: 12),
                    ),
                    if (session.location.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined,
                          color: _subtext, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.location,
                          style:
                              const TextStyle(color: _subtext, fontSize: 12),
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

          const Divider(height: 1, color: _border),

          // ── Summary: Winner + Stats ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                if (winner != null) ...[
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
