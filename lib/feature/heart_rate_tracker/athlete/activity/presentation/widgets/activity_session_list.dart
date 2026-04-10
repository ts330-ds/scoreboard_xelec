import 'package:flutter/material.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/athlete/activity/data/model/activity_session_model.dart';
import 'activity_empty_state.dart';
import 'activity_session_card.dart';

class ActivitySessionList extends StatelessWidget {
  final List<ActivitySession> sessions;
  final VoidCallback onStartTap;

  const ActivitySessionList({
    super.key,
    required this.sessions,
    required this.onStartTap,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return ActivityEmptyState(onStartTap: onStartTap);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, i) =>
          ActivitySessionCard(session: sessions[i]),
    );
  }
}
