import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/session/presentation/cubit/session/timing_session_state.dart';

class StepModeSelection extends StatelessWidget {
  const StepModeSelection({super.key});

  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF1565C0);
  static const _border = Color(0xFFDDE3EC);
  static const _disabled = Color(0xFFE5E7EB);
  static const _disabledText = Color(0xFFADB5BD);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimingSessionCubit, TimingSessionState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  // ── Level 1: Mode ──────────────────────────────────────
                  const _SectionLabel(text: 'Select Test Mode'),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: '📏',
                    title: 'Linear',
                    subtitle: 'Sprint, T-Test, 505 Agility',
                    selected: state.mode == 'linear',
                    onTap: () => context.read<TimingSessionCubit>().selectMode('linear'),
                  ),
                  const SizedBox(height: 10),
                  _ModeCard(
                    icon: '🔄',
                    title: 'Shuttle Run',
                    subtitle: 'Back & forth — up to 3 parallel lanes',
                    selected: state.mode == 'shuttle',
                    onTap: () => context.read<TimingSessionCubit>().selectMode('shuttle'),
                  ),
                  const SizedBox(height: 10),
                  _ModeCard(
                    icon: '🏃',
                    title: 'Yo-Yo Test',
                    subtitle: state.mode == 'yoyo'
                        ? '${state.yoyoNumLanes} ${state.yoyoNumLanes == 1 ? "lane" : "lanes"} — endurance with levels & strikes'
                        : 'Multi-lane endurance test with levels & strikes',
                    selected: state.mode == 'yoyo',
                    onTap: () => context.read<TimingSessionCubit>().selectMode('yoyo'),
                  ),

                  // ── Level 2: Lane count (YOYO only) ───────────────────
                  if (state.mode == 'yoyo') ...[
                    const SizedBox(height: 28),
                    const _SectionLabel(text: 'Number of Lanes'),
                    const SizedBox(height: 4),
                    const Text(
                      'Each lane needs 1 finish gate + 1 turn gate',
                      style: TextStyle(color: Color(0xFF6B7A8D), fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    _YoyoLaneSelector(
                      selected: state.yoyoNumLanes,
                      onSelect: (n) => context.read<TimingSessionCubit>().selectYoyoLanes(n),
                    ),
                  ],

                  // ── Level 2: Sub-mode (Linear only) ───────────────────
                  if (state.mode == 'linear') ...[
                    const SizedBox(height: 28),
                    const _SectionLabel(text: 'Select Test Type'),
                    const SizedBox(height: 12),
                    _SubModeCard(
                      icon: Icons.speed,
                      title: 'Sprint',
                      subtitle: 'Straight-line speed — multiple gate distances',
                      selected: state.subMode == 'sprint',
                      onTap: () => context.read<TimingSessionCubit>().selectSubMode('sprint'),
                    ),
                    const SizedBox(height: 10),
                    _SubModeCard(
                      icon: Icons.rotate_right,
                      title: '505 Agility',
                      subtitle: '5m run, 180° turn, 5m return — single gate',
                      selected: state.subMode == '505',
                      onTap: () => context.read<TimingSessionCubit>().selectSubMode('505'),
                    ),
                    const SizedBox(height: 10),
                    _SubModeCard(
                      icon: Icons.sports,
                      title: 'T-Test',
                      subtitle: 'Forward, lateral and backward movement — single gate',
                      selected: state.subMode == 'ttest',
                      onTap: () => context.read<TimingSessionCubit>().selectSubMode('ttest'),
                    ),
                  ],

                  // ── Level 3: Protocol (Sprint only) ───────────────────
                  if (state.mode == 'linear' && state.subMode == 'sprint') ...[
                    const SizedBox(height: 28),
                    const _SectionLabel(text: 'Select Distance'),
                    const SizedBox(height: 12),
                    _ProtocolGrid(
                      selected: state.protocol,
                      onSelect: (p) => context.read<TimingSessionCubit>().selectProtocol(p),
                    ),
                    if (state.protocol == 'custom') ...[
                      const SizedBox(height: 16),
                      _CustomDistanceField(state: state),
                    ],
                  ],
                ],
              ),
            ),
            _buildFooter(context, state),
          ],
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, TimingSessionState state) {
    final canProceed = _canProceed(state);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: ElevatedButton(
        onPressed: canProceed
            ? () => context.read<TimingSessionCubit>().nextStep()
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _disabled,
          disabledForegroundColor: _disabledText,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          canProceed ? 'Next — Test Info →' : _hintText(state),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  bool _canProceed(TimingSessionState state) {
    if (state.mode.isEmpty) return false;
    if (state.mode == 'linear') {
      if (state.subMode.isEmpty) return false;
      if (state.subMode == 'sprint') {
        if (state.protocol.isEmpty) return false;
        if (state.protocol == 'custom' &&
            (state.customDistance == null || state.customDistance! <= 0)) {
          return false;
        }
      }
    }
    return true;
  }

  String _hintText(TimingSessionState state) {
    if (state.mode.isEmpty) return 'Select a test mode to continue';
    if (state.mode == 'linear' && state.subMode.isEmpty) return 'Select a test type';
    if (state.subMode == 'sprint' && state.protocol.isEmpty) return 'Select a distance';
    if (state.protocol == 'custom') return 'Enter custom distance';
    return 'Next →';
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1E2A3A),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Mode card (Level 1) ────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFDDE3EC);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? const Color(0xFFF5F5F5)
        : selected
            ? _primaryLight
            : _surface;
    final borderColor = disabled
        ? const Color(0xFFE5E7EB)
        : selected
            ? _primary.withValues(alpha: 0.5)
            : _border;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: disabled
                    ? const Color(0xFFEEEEEE)
                    : selected
                        ? _primary.withValues(alpha: 0.15)
                        : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: disabled
                          ? const Color(0xFFADB5BD)
                          : selected
                              ? _primary
                              : _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: disabled
                          ? const Color(0xFFCED4DA)
                          : _subtext,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (disabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Soon',
                  style: TextStyle(
                      color: Color(0xFFADB5BD),
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              )
            else if (selected)
              const Icon(Icons.check_circle, color: _primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Sub-mode card (Level 2) ────────────────────────────────────────────────────

class _SubModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SubModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFDDE3EC);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _primaryLight : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _primary.withValues(alpha: 0.4) : _border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? _primary : _subtext, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? _primary : _text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          const TextStyle(color: _subtext, fontSize: 12)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: _primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Protocol grid (Level 3) ────────────────────────────────────────────────────

class _ProtocolGrid extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  static const _protocols = [
    {'key': '10m', 'label': '10m', 'desc': 'Standing start'},
    {'key': '20m', 'label': '20m', 'desc': 'Acceleration'},
    {'key': '30m', 'label': '30m', 'desc': 'Short sprint'},
    {'key': '40m', 'label': '40m', 'desc': 'NFL Combine'},
    {'key': 'flying10', 'label': 'Flying\n10m', 'desc': 'Max velocity'},
    {'key': 'flying20', 'label': 'Flying\n20m', 'desc': 'Max velocity'},
    {'key': 'custom', 'label': 'Custom', 'desc': 'Set distance'},
  ];

  const _ProtocolGrid({required this.selected, required this.onSelect});

  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFDDE3EC);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _protocols.map((p) {
        final key = p['key']!;
        final isSelected = selected == key;
        return GestureDetector(
          onTap: () => onSelect(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? _primaryLight : _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? _primary.withValues(alpha: 0.5) : _border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  p['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? _primary : _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p['desc']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _subtext, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── YOYO lane selector ─────────────────────────────────────────────────────────

class _YoyoLaneSelector extends StatelessWidget {
  final int selected;
  final void Function(int) onSelect;

  const _YoyoLaneSelector({required this.selected, required this.onSelect});

  static const _primary = Color(0xFF1565C0);
  static const _primaryLight = Color(0xFFE3F2FD);
  static const _border = Color(0xFFDDE3EC);
  static const _text = Color(0xFF1E2A3A);
  static const _subtext = Color(0xFF6B7A8D);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(5, (i) {
        final n = i + 1;
        final isSelected = selected == n;
        return GestureDetector(
          onTap: () => onSelect(n),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? _primary.withValues(alpha: 0.5) : _border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$n',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? _primary : _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  n == 1 ? 'lane' : 'lanes',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _subtext, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Custom distance field ──────────────────────────────────────────────────────

class _CustomDistanceField extends StatefulWidget {
  final TimingSessionState state;
  const _CustomDistanceField({required this.state});

  @override
  State<_CustomDistanceField> createState() => _CustomDistanceFieldState();
}

class _CustomDistanceFieldState extends State<_CustomDistanceField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.state.customDistance?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE3EC)),
      ),
      child: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Color(0xFF1E2A3A), fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Enter distance in metres (e.g. 15)',
          hintStyle: TextStyle(color: Color(0xFF6B7A8D), fontSize: 13),
          suffixText: 'm',
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onChanged: (v) {
          final d = double.tryParse(v);
          context.read<TimingSessionCubit>().updateCustomDistance(d);
        },
      ),
    );
  }
}
