import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import 'package:xelex_esp/core/widgets/ecg_waveform.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/coach/live_task/presentation/screen/coach_live_task_screen.dart';
import '../cubit/coach_team_live_cubit.dart';
import '../cubit/coach_team_live_state.dart';

class CoachTeamLiveMobile extends StatefulWidget {
  const CoachTeamLiveMobile({super.key});

  @override
  State<CoachTeamLiveMobile> createState() => _CoachTeamLiveMobileState();
}

class _CoachTeamLiveMobileState extends State<CoachTeamLiveMobile> {
  // Cubit ka reference pehle hi pakad lo. dispose() me context.read karna unsafe
  // hai — tab tak ancestor BlocProvider deactivate ho chuka hota hai.
  CoachTeamLiveCubit? _cubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit = context.read<CoachTeamLiveCubit>();
  }

  @override
  void dispose() {
    // Screen chhodte hi watch band — per-task unwatch + disconnect.
    _cubit?.stopWatching();
    super.dispose();
  }

  void _openAthleteLive(TeamAthleteCard card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoachLiveTaskScreen(
          taskId: card.taskId,
          athleteName: card.athleteName,
          taskName: card.taskName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Whole Team'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<CoachTeamLiveCubit, CoachTeamLiveState>(
        builder: (context, state) {
          // Auth fail — re-login chahiye.
          if (state.isAuthFailure) {
            return _MessageView(
              icon: Icons.lock_outline,
              title: 'Session expired',
              message: state.errorMessage ?? 'Please log in again',
            );
          }

          // Pehli baar connect ho raha hai aur abhi koi card nahi.
          if (state.status == CoachTeamLiveStatus.connecting &&
              state.cards.isEmpty) {
            return const _ConnectingView();
          }

          // Genuine error (watching/reconnect ke bahar) aur grid khali.
          if (state.status == CoachTeamLiveStatus.error && state.cards.isEmpty) {
            return _MessageView(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              message: state.errorMessage ?? 'Could not connect',
              onRetry: () =>
                  context.read<CoachTeamLiveCubit>().retryConnectionManually(),
            );
          }

          final cards = state.sortedCards;

          return Column(
            children: [
              if (state.status == CoachTeamLiveStatus.reconnecting)
                _ReconnectBanner(
                  isExhausted: state.isReconnectExhausted,
                  onRetry: () => context
                      .read<CoachTeamLiveCubit>()
                      .retryConnectionManually(),
                ),
              Expanded(
                child: cards.isEmpty
                    ? const _WaitingView()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.92,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) => _AthleteCard(
                          card: cards[index],
                          onTap: () => _openAthleteLive(cards[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Athlete Card ──────────────────────────────────────────────────────────────

class _AthleteCard extends StatelessWidget {
  final TeamAthleteCard card;
  final VoidCallback onTap;
  const _AthleteCard({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final offline = card.isOffline;
    final accent = offline ? AppColors.subtext : AppColors.heartRed;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: offline ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: offline ? AppColors.border : AppColors.success.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name + status dot
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: offline ? AppColors.subtext : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      card.athleteName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // ── BPM
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.favorite, color: accent, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    card.hasReading ? '${card.heartRate}' : '--',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Text(
                      'bpm',
                      style: TextStyle(color: AppColors.subtext, fontSize: 12),
                    ),
                  ),
                ],
              ),

              // ── Mini live waveform (sirf heart rate se driven)
              const SizedBox(height: 6),
              EcgWaveform(
                bpm: card.heartRate,
                active: !offline && card.hasReading,
                height: 30,
                showGrid: false,
                lineWidth: 1.5,
                lineColor: AppColors.heartRed,
              ),

              // ── HRV (backend isko sugar_level column me store karta hai).
              // null/0 ho to hide, warna dikhao.
              if (card.sugarLevel != null && card.sugarLevel! > 0) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.monitor_heart_outlined,
                        color: AppColors.subtext, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${card.sugarLevel!.round()}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 1),
                      child: Text(
                        'HRV',
                        style:
                            TextStyle(color: AppColors.subtext, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],

              if (offline) ...[
                const SizedBox(height: 8),
                const Text(
                  'OFFLINE',
                  style: TextStyle(
                    color: AppColors.subtext,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reconnect banner ───────────────────────────────────────────────────────────

class _ReconnectBanner extends StatelessWidget {
  final bool isExhausted;
  final VoidCallback onRetry;
  const _ReconnectBanner({required this.isExhausted, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warningBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (!isExhausted)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.warning),
            )
          else
            const Icon(Icons.wifi_off, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isExhausted
                  ? 'Connection lost'
                  : 'Reconnecting…',
              style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          if (isExhausted)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry',
                  style: TextStyle(color: AppColors.warning)),
            ),
        ],
      ),
    );
  }
}

// ── Connecting / Waiting / Message views ────────────────────────────────────────

class _ConnectingView extends StatelessWidget {
  const _ConnectingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Connecting…',
              style: TextStyle(color: AppColors.subtext, fontSize: 14)),
        ],
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups_outlined, color: AppColors.subtext, size: 52),
          SizedBox(height: 16),
          Text(
            'Waiting for athletes',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Cards appear as your athletes\nstart sending readings',
            style: TextStyle(color: AppColors.subtext, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: AppColors.subtext, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
