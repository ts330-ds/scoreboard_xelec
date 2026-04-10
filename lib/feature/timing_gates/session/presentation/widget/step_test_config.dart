import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_state.dart';

// Step 4 — Trial Config: trialsCount, trialMode (round_robin / athlete_complete)
class StepTestConfig extends StatelessWidget {
  const StepTestConfig({super.key});

  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);
  static const _border = Color(0xFFDDE3EC);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimingSessionCubit, TimingSessionState>(
      builder: (context, state) {
        final cubit = context.read<TimingSessionCubit>();
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSection(
                    title: 'Number of Trials',
                    child: Row(
                      children: [
                        _countBtn(Icons.remove, () =>
                            cubit.updateTrialsCount(state.trialsCount - 1)),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${state.trialsCount}',
                              style: const TextStyle(
                                  color: _text,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        _countBtn(Icons.add, () =>
                            cubit.updateTrialsCount(state.trialsCount + 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Trial Order',
                    child: Column(
                      children: [
                        _trialModeCard(
                          context,
                          mode: 'round_robin',
                          selected: state.trialMode,
                          title: 'Round Robin',
                          subtitle: 'All athletes complete Trial 1, then Trial 2...',
                          icon: Icons.repeat,
                          onTap: () => cubit.selectTrialMode('round_robin'),
                        ),
                        const SizedBox(height: 10),
                        _trialModeCard(
                          context,
                          mode: 'athlete_complete',
                          selected: state.trialMode,
                          title: 'Athlete Complete',
                          subtitle: 'Each athlete finishes all trials before the next',
                          icon: Icons.person,
                          onTap: () => cubit.selectTrialMode('athlete_complete'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        );
      },
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
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
          Text(title,
              style: const TextStyle(
                  color: _text, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _countBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _primaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _primary, size: 20),
      ),
    );
  }

  Widget _trialModeCard(
    BuildContext context, {
    required String mode,
    required String selected,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _primaryLight : _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected
                  ? _primary.withValues(alpha: 0.4)
                  : _border),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? _primary : _subtext, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: isSelected ? _primary : _text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(subtitle,
                      style:
                          const TextStyle(color: _subtext, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.read<TimingSessionCubit>().prevStep(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back', style: TextStyle(color: _text)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => context.read<TimingSessionCubit>().nextStep(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Next →'),
            ),
          ),
        ],
      ),
    );
  }
}
