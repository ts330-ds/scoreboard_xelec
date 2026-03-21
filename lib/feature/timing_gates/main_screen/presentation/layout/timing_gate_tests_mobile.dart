import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/test_session_model.dart';
import 'package:xelex_esp/router/timing_gate_path.dart';

class TimingGateTestsMobile extends StatelessWidget {
  const TimingGateTestsMobile({super.key});

  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFDDE3EC);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _success = Color(0xFF16A34A);
  static const _successBg = Color(0xFFDCFCE7);
  static const _warning = Color(0xFFD97706);
  static const _warningBg = Color(0xFFFEF3C7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            Expanded(
              child: ValueListenableBuilder<Box<TestSessionModel>>(
                valueListenable:
                    Hive.box<TestSessionModel>('sessions').listenable(),
                builder: (context, box, _) {
                  final sessions = box.values.toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _newTestCard(context),
                        const SizedBox(height: 20),
                        _recentSection(context, sessions),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: const Row(children: [
        Text('Tests',
            style: TextStyle(
                color: _text, fontSize: 18, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _newTestCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(TimingGatePaths.timingGateSession),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primary.withAlpha(80)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_circle_outline,
                color: _primary, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Test Session',
                    style: TextStyle(
                        color: _text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(
                    'Mode → Setup → Athletes → Config → Gates → Run',
                    style:
                        TextStyle(color: _subtext, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: _primary, size: 18),
        ]),
      ),
    );
  }

  Widget _recentSection(
      BuildContext context, List<TestSessionModel> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Recent Sessions',
                style: TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            if (sessions.isNotEmpty)
              Text(
                '${sessions.length} session${sessions.length == 1 ? '' : 's'}',
                style: const TextStyle(color: _subtext, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          _emptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _sessionCard(sessions[i]),
          ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.history, color: _subtext, size: 36),
          SizedBox(height: 12),
          Text('No sessions yet',
              style: TextStyle(
                  color: _text, fontSize: 14, fontWeight: FontWeight.w500)),
          SizedBox(height: 4),
          Text(
            'Start a new test to record your first session.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _subtext, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(TestSessionModel session) {
    final isCompleted = session.isCompleted;
    final statusColor = isCompleted ? _success : _warning;
    final statusBg = isCompleted ? _successBg : _warningBg;
    final statusLabel = isCompleted ? 'Completed' : 'In Progress';

    final completedTrials = session.completedTrialsCount;
    final totalTrials = session.totalTrials;
    final progressValue =
        totalTrials == 0 ? 0.0 : session.progressPercent.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name + Status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  session.sessionName,
                  style: const TextStyle(
                      color: _text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: Mode · Athletes · Location
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: _subtext, size: 13),
              const SizedBox(width: 4),
              Text(session.modeLabel,
                  style: const TextStyle(color: _subtext, fontSize: 12)),
              const SizedBox(width: 12),
              const Icon(Icons.people_outline, color: _subtext, size: 13),
              const SizedBox(width: 4),
              Text(
                  '${session.athletes.length} athlete${session.athletes.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: _subtext, fontSize: 12)),
              if (session.location.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined,
                    color: _subtext, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    session.location,
                    style: const TextStyle(color: _subtext, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Row 3: Progress bar + trial count
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: const Color(0xFFE3F2FD),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? _success : _primary),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$completedTrials / $totalTrials trials',
                style: const TextStyle(color: _subtext, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 4: Date
          Text(
            _formatDate(session.date),
            style: const TextStyle(color: _subtext, fontSize: 11),
          ),
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
