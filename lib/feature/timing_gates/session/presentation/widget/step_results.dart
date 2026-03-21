import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_state.dart';

// TODO: Rebuild results screen with AthleteResultModel + TrialResultModel
class StepResults extends StatelessWidget {
  const StepResults({super.key});

  static const _bg = Color(0xFFF4F6F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF1565C0);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _border = Color(0xFFDDE3EC);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimingSessionCubit, TimingSessionState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state),
                Expanded(child: _buildResults(state)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, TimingSessionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: _surface,
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: _primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Session Complete',
              style: const TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.read<TimingSessionCubit>().resetSession(),
            child: const Text('New Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(TimingSessionState state) {
    if (state.results.isEmpty) {
      return const Center(
        child: Text(
          'No results recorded.',
          style: TextStyle(color: _subtext, fontSize: 14),
        ),
      );
    }

    final isYoyo = state.mode == 'yoyo';

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final result = state.results[index];
        final best = result.bestTime;
        final completed = result.completedTrials.length;

        // YOYO: determine status from trial
        final isEliminated = isYoyo &&
            result.trials.isNotEmpty &&
            result.trials.first.status == 'eliminated';
        final yoyoLevel = isYoyo && best != null
            ? best.toStringAsFixed(1)
            : null;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEliminated
                ? const Color(0xFFFEF2F2)
                : _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEliminated
                  ? const Color(0xFFFCA5A5)
                  : _border,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isEliminated
                    ? const Color(0xFFFCA5A5)
                    : _primary.withValues(alpha: 0.1),
                child: Text(
                  result.fullName.isNotEmpty
                      ? result.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: isEliminated ? const Color(0xFFDC2626) : _primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.fullName,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (result.team.isNotEmpty)
                      Text(
                        result.team,
                        style: const TextStyle(color: _subtext, fontSize: 12),
                      ),
                    if (isYoyo)
                      Text(
                        isEliminated ? 'Eliminated' : 'Survived',
                        style: TextStyle(
                          color: isEliminated
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        '$completed trial(s) completed',
                        style: const TextStyle(color: _subtext, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (isYoyo && yoyoLevel != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Lv $yoyoLevel',
                      style: TextStyle(
                        color: isEliminated
                            ? const Color(0xFFDC2626)
                            : _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      isEliminated ? 'Eliminated' : 'Reached',
                      style: const TextStyle(color: _subtext, fontSize: 11),
                    ),
                  ],
                )
              else if (!isYoyo && best != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${best.toStringAsFixed(3)}s',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      'Best',
                      style: TextStyle(color: _subtext, fontSize: 11),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
