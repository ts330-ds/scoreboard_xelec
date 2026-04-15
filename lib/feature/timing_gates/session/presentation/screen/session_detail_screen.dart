import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/timing_gates/profile/presentation/cubit/profile_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_result_model.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/test_session_model.dart';
import 'widget/session_detail_widget.dart';

class SessionDetailScreen extends StatefulWidget {
  final TestSessionModel session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

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

  List<AthleteResultModel> get _ranked {
    if (s.isYoyo) {
      // YoYo: sort by highest level (best = highest totalTime)
      return [...s.results]..sort((a, b) {
          final al = yoyoLevel(a), bl = yoyoLevel(b);
          if (al == null && bl == null) return 0;
          if (al == null) return 1;
          if (bl == null) return -1;
          return bl.compareTo(al); // descending — highest level first
        });
    }
    return [...s.results]..sort((a, b) {
        final ab = a.bestTime, bb = b.bestTime;
        if (ab == null && bb == null) return 0;
        if (ab == null) return 1;
        if (bb == null) return -1;
        return ab.compareTo(bb);
      });
  }

  void _showPdfOptions() {
    final profileCubit = context.read<ProfileCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: profileCubit,
        child: SafeArea(child: PdfOptionsSheet(session: s)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sdBg,
      body: SafeArea(
        child: Column(
          children: [
            SessionDetailHeader(
              sessionName: s.sessionName,
              onBack: () => Navigator.of(context).pop(),
              onPdf: _showPdfOptions,
            ),
            SessionDetailTabBar(tabs: _tabs),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  OverviewTab(session: s, ranked: _ranked),
                  LeaderboardTab(ranked: _ranked, gateDistances: s.gateDistances, isYoyo: s.isYoyo),
                  ChartsTab(ranked: _ranked, gateDistances: s.gateDistances, isYoyo: s.isYoyo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
