import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

class ArcheryModeSelectionScreen extends StatelessWidget {
  final VoidCallback onQualificationAbcdSelected;
  final VoidCallback onQualificationAbcSelected;
  final VoidCallback onQualificationAb_CdSelected;
  final VoidCallback onIndividualRoundSelected;
  final VoidCallback onTeamRoundSelected;

  const ArcheryModeSelectionScreen({
    super.key,
    required this.onQualificationAbcdSelected,
    required this.onQualificationAbcSelected,
    required this.onQualificationAb_CdSelected,
    required this.onIndividualRoundSelected,
    required this.onTeamRoundSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Select Archery Mode',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ModeButton(
              title: 'Qualification Round',
              subtitle: 'Standard archery scoring',
              color: Colors.orange,
              onTap: () => _showQualificationSheet(context),
            ),
            const SizedBox(height: 16),
            _ModeButton(
              title: 'Elimination Round',
              subtitle: 'Alternating finals mode',
              color: Colors.blue,
              onTap: () => _showEliminationSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEliminationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Elimination Round',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _ModeButton(
                  title: 'Individual Round',
                  subtitle: 'Single archer elimination',
                  color: Colors.blue,
                  onTap: () {
                    context.pop();
                    onIndividualRoundSelected();
                  },
                ),
                const SizedBox(height: 12),
                _ModeButton(
                  title: 'Team Round',
                  subtitle: 'Team elimination',
                  color: Colors.blue,
                  onTap: () {
                    context.pop();
                    onTeamRoundSelected();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQualificationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Qualification Mode',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _ModeButton(
                  title: 'ABCD',
                  subtitle: '4 Players',
                  color: Colors.orange,
                  onTap: () {
                    context.pop();
                    onQualificationAbcdSelected();
                  },
                ),
                const SizedBox(height: 12),
                _ModeButton(
                  title: 'ABC',
                  subtitle: '3 Players',
                  color: Colors.orange,
                  onTap: () {
                    context.pop();
                    onQualificationAbcSelected();
                  },
                ),
                const SizedBox(height: 12),
                _ModeButton(
                  title: 'AB-CD',
                  subtitle: '2 Teams',
                  color: Colors.orange,
                  onTap: () {
                    context.pop();
                    onQualificationAb_CdSelected();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .5), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sports, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color.withValues(alpha: .9),
                    ),
                  ),
                  // const SizedBox(height: 4),
                  // Text(
                  // 	subtitle,
                  // 	style: TextStyle(
                  // 		fontSize: 12,
                  // 		color: color.withValues(alpha: .7),
                  // 	),
                  // ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: .5)),
          ],
        ),
      ),
    );
  }
}
