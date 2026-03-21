import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/test_session_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/trial_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/service/session_pdf_service.dart';

class SessionDetailScreen extends StatefulWidget {
  final TestSessionModel session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _border = Color(0xFFDDE3EC);
  static const _success = Color(0xFF16A34A);
  static const _gold = Color(0xFFD97706);
  static const _silver = Color(0xFF64748B);
  static const _bronze = Color(0xFF92400E);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  TestSessionModel get s => widget.session;

  // ── PDF Options Bottom Sheet ──────────────────────────────────────────────
  void _showPdfOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PdfOptionsSheet(session: s),
    );
  }

  List<AthleteResultModel> get _ranked {
    return [...s.results]..sort((a, b) {
        final ab = a.bestTime, bb = b.bestTime;
        if (ab == null && bb == null) return 0;
        if (ab == null) return 1;
        if (bb == null) return -1;
        return ab.compareTo(bb);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar()],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildOverviewTab(),
                  _buildLeaderboardTab(),
                  _buildChartsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: _primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          tooltip: 'PDF Report',
          icon: const Icon(Icons.picture_as_pdf_outlined,
              color: Colors.white, size: 22),
          onPressed: _showPdfOptions,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
        title: Text(
          s.sessionName,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _primary.withAlpha(200)],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 44),
              child: Wrap(
                spacing: 12,
                children: [
                  _chip(Icons.timer_outlined, s.modeLabel),
                  _chip(Icons.people_outline,
                      '${s.athletes.length} athletes'),
                  if (s.location.isNotEmpty)
                    _chip(Icons.location_on_outlined, s.location),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: _surface,
      child: TabBar(
        controller: _tabs,
        labelColor: _primary,
        unselectedLabelColor: _subtext,
        indicatorColor: _primary,
        indicatorWeight: 2,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Leaderboard'),
          Tab(text: 'Charts'),
        ],
      ),
    );
  }

  // ── Overview Tab ─────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final ranked = _ranked;
    final allBest = ranked
        .map((r) => r.bestTime)
        .where((t) => t != null)
        .cast<double>()
        .toList();
    final overallBest = allBest.isEmpty
        ? null
        : allBest.reduce((a, b) => a < b ? a : b);
    final overallAvg = allBest.isEmpty
        ? null
        : allBest.reduce((a, b) => a + b) / allBest.length;
    final winner = ranked.isNotEmpty ? ranked.first : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Session info card
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Session Info'),
              const SizedBox(height: 12),
              _infoRow(Icons.calendar_today_outlined, 'Date',
                  _formatDate(s.completedAt ?? s.date)),
              _infoRow(Icons.timer_outlined, 'Mode', s.modeLabel),
              _infoRow(Icons.people_outline, 'Athletes',
                  '${s.athletes.length}'),
              _infoRow(Icons.repeat, 'Trials per athlete',
                  '${s.trialsCount}'),
              _infoRow(Icons.sort, 'Trial order',
                  s.trialMode == 'round_robin'
                      ? 'Round Robin'
                      : 'Athlete Complete'),
              if (s.location.isNotEmpty)
                _infoRow(
                    Icons.location_on_outlined, 'Location', s.location),
              if (s.notes.isNotEmpty)
                _infoRow(Icons.notes_outlined, 'Notes', s.notes),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Stats cards row
        Row(
          children: [
            Expanded(
              child: _statCard(
                label: 'Best Time',
                value: overallBest != null
                    ? '${overallBest.toStringAsFixed(3)}s'
                    : '—',
                icon: Icons.emoji_events_outlined,
                color: _gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                label: 'Avg Time',
                value: overallAvg != null
                    ? '${overallAvg.toStringAsFixed(3)}s'
                    : '—',
                icon: Icons.analytics_outlined,
                color: _primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                label: 'Total Trials',
                value: '${s.completedTrialsCount}',
                icon: Icons.check_circle_outline,
                color: _success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                label: 'Top Athlete',
                value: winner?.fullName.split(' ').first ?? '—',
                icon: Icons.star_outline,
                color: _gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Podium (top 3)
        if (ranked.isNotEmpty) ...[
          _card(child: _buildPodium(ranked)),
        ],
      ],
    );
  }

  Widget _buildPodium(List<AthleteResultModel> ranked) {
    final top = ranked.take(3).toList();
    final podiumOrder = <int>[];
    if (top.length >= 2) podiumOrder.add(1);
    podiumOrder.add(0);
    if (top.length >= 3) podiumOrder.add(2);

    final heights = [80.0, 100.0, 65.0]; // 2nd, 1st, 3rd
    final colors = [_silver, _gold, _bronze];
    final labels = ['2nd', '1st', '3rd'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Podium'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: podiumOrder.map((i) {
            if (i >= top.length) return const SizedBox(width: 90);
            final athlete = top[i];
            final displayIdx = podiumOrder.indexOf(i);
            return Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        colors[displayIdx].withAlpha(30),
                    child: Text(
                      athlete.fullName[0].toUpperCase(),
                      style: TextStyle(
                          color: colors[displayIdx],
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    athlete.fullName.split(' ').first,
                    style: const TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    athlete.bestTime != null
                        ? '${athlete.bestTime!.toStringAsFixed(3)}s'
                        : '—',
                    style: TextStyle(
                        color: colors[displayIdx],
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: heights[displayIdx],
                    decoration: BoxDecoration(
                      color: colors[displayIdx].withAlpha(30),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                      border: Border.all(
                          color: colors[displayIdx].withAlpha(80)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[displayIdx],
                      style: TextStyle(
                          color: colors[displayIdx],
                          fontWeight: FontWeight.w800,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Leaderboard Tab ───────────────────────────────────────────────────────

  Widget _buildLeaderboardTab() {
    final ranked = _ranked;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ranked.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _athleteDetailCard(ranked[i], i + 1),
      ),
    );
  }

  Widget _athleteDetailCard(AthleteResultModel result, int rank) {
    Color rankColor = rank == 1
        ? _gold
        : rank == 2
            ? _silver
            : rank == 3
                ? _bronze
                : _subtext;

    final completedTrials = result.completedTrials;
    final allTrials = result.trials
        .where((t) => t.isCompleted || t.isSkipped || t.isFalseStart)
        .toList()
      ..sort((a, b) => a.trialNumber.compareTo(b.trialNumber));

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Athlete header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rankColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Text('$rank',
                    style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundColor: _primaryLight,
                child: Text(
                  result.fullName[0].toUpperCase(),
                  style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.fullName,
                        style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    if (result.team.isNotEmpty)
                      Text(result.team,
                          style: const TextStyle(
                              color: _subtext, fontSize: 11)),
                  ],
                ),
              ),
              if (result.bestTime != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${result.bestTime!.toStringAsFixed(3)}s',
                      style: TextStyle(
                          color: rank == 1 ? _gold : _primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17),
                    ),
                    const Text('best',
                        style:
                            TextStyle(color: _subtext, fontSize: 10)),
                  ],
                ),
            ],
          ),
          if (completedTrials.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 10),
            // Stats row
            Row(
              children: [
                _miniStat('Trials', '${completedTrials.length}'),
                _vDivider(),
                _miniStat('Best',
                    '${result.bestTime!.toStringAsFixed(3)}s'),
                _vDivider(),
                if (result.avgTime != null)
                  _miniStat('Avg',
                      '${result.avgTime!.toStringAsFixed(3)}s'),
                if (result.avgTime != null) _vDivider(),
                _miniStat(
                  'Worst',
                  () {
                    final times = completedTrials
                        .map((t) => t.totalTime!)
                        .toList();
                    final worst = times.reduce(
                        (a, b) => a > b ? a : b);
                    return '${worst.toStringAsFixed(3)}s';
                  }(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Trial rows
            ...allTrials.map((t) => _trialRow(t, result)),
          ],
        ],
      ),
    );
  }

  Widget _trialRow(TrialResultModel t, AthleteResultModel result) {
    final isBest = t.isCompleted &&
        t.totalTime != null &&
        result.bestTime != null &&
        t.totalTime == result.bestTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isBest ? _gold.withAlpha(15) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isBest ? _gold.withAlpha(80) : _border),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isBest ? _gold.withAlpha(30) : _primaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('T${t.trialNumber}',
                style: TextStyle(
                    color: isBest ? _gold : _primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: t.isCompleted
                ? Wrap(
                    spacing: 6,
                    children: [
                      if (t.splits.isNotEmpty)
                        ...t.splits.asMap().entries.map((e) => Text(
                              'G${e.key + 1}→G${e.key + 2}: ${e.value.toStringAsFixed(3)}s',
                              style: const TextStyle(
                                  color: _subtext, fontSize: 11),
                            )),
                    ],
                  )
                : Text(
                    t.isSkipped ? 'Skipped' : 'False Start',
                    style: const TextStyle(
                        color: _subtext,
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                  ),
          ),
          if (t.isCompleted && t.totalTime != null)
            Row(
              children: [
                Text(
                  '${t.totalTime!.toStringAsFixed(3)}s',
                  style: TextStyle(
                    color: isBest ? _gold : _text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (isBest) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded,
                      color: _gold, size: 14),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // ── Charts Tab ────────────────────────────────────────────────────────────

  Widget _buildChartsTab() {
    final ranked = _ranked;
    final athletesWithData =
        ranked.where((r) => r.completedTrials.isNotEmpty).toList();

    if (athletesWithData.isEmpty) {
      return const Center(
        child: Text('No completed trials to chart.',
            style: TextStyle(color: _subtext)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(child: _buildBestTimeBarChart(athletesWithData)),
        const SizedBox(height: 16),
        if (athletesWithData.any((r) => r.completedTrials.length > 1))
          _card(child: _buildTrialProgressionChart(athletesWithData)),
      ],
    );
  }

  // Leaderboard list: best time per athlete — scales to any number of athletes
  Widget _buildBestTimeBarChart(List<AthleteResultModel> athletes) {
    // Sort by best time ascending (fastest first)
    final sorted = [...athletes]
      ..sort((a, b) => (a.bestTime ?? double.infinity)
          .compareTo(b.bestTime ?? double.infinity));

    final best = sorted.first.bestTime ?? 0;
    final worst = sorted.last.bestTime ?? 0;
    final range = (worst - best).clamp(0.001, double.infinity);

    const rankColors = [_gold, _silver, _bronze];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Best Time Leaderboard'),
        const SizedBox(height: 4),
        const Text(
          'Sorted fastest → slowest',
          style: TextStyle(color: _subtext, fontSize: 11),
        ),
        const SizedBox(height: 16),
        ...sorted.asMap().entries.map((e) {
          final rank = e.key + 1;
          final r = e.value;
          final time = r.bestTime ?? 0;
          // Bar fill: fastest athlete = 100%, slowest = min 20%
          final fill = 1.0 - ((time - best) / range) * 0.8;
          final isTop3 = rank <= 3;
          final rankColor =
              isTop3 ? rankColors[rank - 1] : _primary.withValues(alpha: 0.7);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isTop3
                        ? rankColor.withValues(alpha: 0.15)
                        : const Color(0xFFF0F4FA),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: isTop3 ? rankColor : _subtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + inline bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.fullName,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      LayoutBuilder(builder: (ctx, cons) {
                        return Stack(
                          children: [
                            // Track
                            Container(
                              height: 6,
                              width: cons.maxWidth,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EDF5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            // Fill
                            Container(
                              height: 6,
                              width: cons.maxWidth * fill,
                              decoration: BoxDecoration(
                                color: rankColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Time value
                Text(
                  '${time.toStringAsFixed(3)}s',
                  style: TextStyle(
                    color: isTop3 ? rankColor : _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Line chart: trial progression per athlete
  Widget _buildTrialProgressionChart(List<AthleteResultModel> athletes) {
    final lineColors = [
      _gold,
      _primary,
      _bronze,
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      _silver,
    ];

    final maxTrials = athletes
        .map((r) => r.completedTrials.length)
        .reduce((a, b) => a > b ? a : b);
    final allTimes = athletes
        .expand((r) => r.completedTrials.map((t) => t.totalTime!))
        .toList();
    if (allTimes.isEmpty) return const SizedBox();
    final minY = allTimes.reduce((a, b) => a < b ? a : b);
    final maxY = allTimes.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.2 + 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Trial Progression'),
        const SizedBox(height: 4),
        Text('Performance across trials',
            style: const TextStyle(color: _subtext, fontSize: 11)),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: athletes.asMap().entries.map((e) {
            final color = lineColors[e.key % lineColors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(
                  e.value.fullName.split(' ').first,
                  style: const TextStyle(
                      color: _text, fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 1,
              maxX: maxTrials.toDouble(),
              minY: (minY - padding).clamp(0, double.infinity),
              maxY: maxY + padding,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((s) {
                      final athlete = athletes[s.barIndex];
                      return LineTooltipItem(
                        '${athlete.fullName.split(' ').first}: ${s.y.toStringAsFixed(3)}s',
                        TextStyle(
                            color: lineColors[
                                s.barIndex % lineColors.length],
                            fontWeight: FontWeight.w600,
                            fontSize: 11),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toStringAsFixed(1)}s',
                      style:
                          const TextStyle(color: _subtext, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(
                      'T${v.toInt()}',
                      style:
                          const TextStyle(color: _subtext, fontSize: 10),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: athletes.asMap().entries.map((e) {
                final color = lineColors[e.key % lineColors.length];
                final trials = e.value.completedTrials
                    .where((t) => t.totalTime != null)
                    .toList()
                  ..sort(
                      (a, b) => a.trialNumber.compareTo(b.trialNumber));
                final spots = trials.asMap().entries
                    .map((en) => FlSpot(
                          (en.key + 1).toDouble(),
                          en.value.totalTime!,
                        ))
                    .toList();
                return LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: _text, fontSize: 14, fontWeight: FontWeight.w700));
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _subtext, size: 15),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(color: _subtext, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text(label,
                    style:
                        const TextStyle(color: _subtext, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: _text,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          Text(label,
              style: const TextStyle(color: _subtext, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
        height: 28, width: 1, color: _border);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _PdfOptionsSheet — Bottom sheet: Share ya Save to Device choose karo
//
// Ye ek alag StatefulWidget hai kyoki iske apne loading states hain
// (sharePending, savePending) jo main screen se independent hain.
// ══════════════════════════════════════════════════════════════════════════════
class _PdfOptionsSheet extends StatefulWidget {
  final TestSessionModel session;
  const _PdfOptionsSheet({required this.session});

  @override
  State<_PdfOptionsSheet> createState() => _PdfOptionsSheetState();
}

class _PdfOptionsSheetState extends State<_PdfOptionsSheet> {
  static const _primary  = Color(0xFF1565C0);
  static const _text     = Color(0xFF1E2A3A);
  static const _subtext  = Color(0xFF6B7A8D);
  static const _border   = Color(0xFFDDE3EC);
  static const _success  = Color(0xFF16A34A);

  bool _sharePending = false;
  bool _savePending  = false;

  // ── Share PDF ─────────────────────────────────────────────────────────────
  Future<void> _share() async {
    setState(() => _sharePending = true);
    try {
      await SessionPdfService.generateAndShare(session: widget.session);
      if (mounted) Navigator.of(context).pop(); // sheet band karo
    } catch (e) {
      if (mounted) _showError('Share failed: $e');
    } finally {
      if (mounted) setState(() => _sharePending = false);
    }
  }

  // ── Save to Device ────────────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _savePending = true);
    try {
      final path = await SessionPdfService.saveToDevice(session: widget.session);
      if (!mounted) return;

      Navigator.of(context).pop(); // sheet band karo

      if (path != null) {
        // Success snackbar — file ka path dikhao
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _success,
            duration: const Duration(seconds: 4),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PDF saved!',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  // Path thoda shorten karo — sirf SportsIQ/filename dikhao
                  _shortPath(path),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      } else {
        _showError('Could not access device storage.');
      }
    } catch (e) {
      if (mounted) _showError('Save failed: $e');
    } finally {
      if (mounted) setState(() => _savePending = false);
    }
  }

  // "/.../SportsIQ/filename.pdf" → "SportsIQ/filename.pdf"
  String _shortPath(String path) {
    final idx = path.indexOf('SportsIQ');
    return idx >= 0 ? path.substring(idx) : path;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'PDF Report',
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Session results, leaderboard aur trial times PDF mein',
            style: TextStyle(color: _subtext, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // ── Option 1: Share ──────────────────────────────────────────────
          _OptionTile(
            icon: Icons.share_outlined,
            iconColor: _primary,
            title: 'Share PDF',
            subtitle: 'WhatsApp, Gmail, Drive — kahi bhi bhejo',
            isLoading: _sharePending,
            onTap: (_sharePending || _savePending) ? null : _share,
          ),

          const SizedBox(height: 12),

          // ── Option 2: Save to Device ──────────────────────────────────────
          _OptionTile(
            icon: Icons.download_outlined,
            iconColor: _success,
            title: 'Save to Device',
            subtitle: 'Files app mein SportsIQ folder ke andar save hoga',
            isLoading: _savePending,
            onTap: (_sharePending || _savePending) ? null : _save,
          ),
        ],
      ),
    );
  }
}

// ── Reusable option tile for the bottom sheet ─────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  static const _text    = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _border  = Color(0xFFDDE3EC);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
          color: onTap == null
              ? const Color(0xFFF8FAFC)
              : Colors.white,
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: onTap == null ? _subtext : _text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _subtext, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!isLoading)
              Icon(Icons.chevron_right, color: _subtext, size: 18),
          ],
        ),
      ),
    );
  }
}
