import 'package:flutter/material.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';

class ArcheryModeSelectionScreen extends StatelessWidget {
	final VoidCallback onSimpleModeSelected;
	final VoidCallback onAlternatingFinalsSelected;

	const ArcheryModeSelectionScreen({
		super.key,
		required this.onSimpleModeSelected,
		required this.onAlternatingFinalsSelected,
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
							title: 'Simple Archery',
							subtitle: 'Standard archery scoring',
							color: Colors.orange,
							onTap: onSimpleModeSelected,
						),
						const SizedBox(height: 16),
						_ModeButton(
							title: 'Alternating Finals',
							subtitle: 'Alternating finals mode',
							color: Colors.blue,
							onTap: onAlternatingFinalsSelected,
						),
					],
				),
			),
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
									const SizedBox(height: 4),
									Text(
										subtitle,
										style: TextStyle(
											fontSize: 12,
											color: color.withValues(alpha: .7),
										),
									),
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
