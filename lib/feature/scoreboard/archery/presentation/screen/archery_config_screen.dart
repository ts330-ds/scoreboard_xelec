import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../cubit/controller/archery_controller_cubit.dart';
import '../cubit/timer/archery_timer_cubit.dart';

class ArcheryConfigScreen extends StatefulWidget {
  const ArcheryConfigScreen({super.key});

  @override
  State<ArcheryConfigScreen> createState() => _ArcheryConfigScreenState();
}

class _ArcheryConfigScreenState extends State<ArcheryConfigScreen> {
  ArcheryMode _selectedMode = ArcheryMode.abcd;
  int _practiceEnds = 0;
  int _scoringEnds = 6;
  int _greenTime = 90;

  final List<int> _greenTimeOptions = [60, 90, 120, 180];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Archery Config',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selection
            _buildSectionTitle('Select Mode'),
            const SizedBox(height: 8),
            _buildModeSelection(),

            const SizedBox(height: 24),

            // Practice/Sighter Ends
            _buildSectionTitle('Sighter Sets (0-99)'),
            const SizedBox(height: 8),
            _buildNumberSelector(
              value: _practiceEnds,
              min: 0,
              max: 99,
              onChanged: (value) => setState(() => _practiceEnds = value),
            ),

            const SizedBox(height: 24),

            // Scoring Ends
            _buildSectionTitle('Scoring Sets (1-99)'),
            const SizedBox(height: 8),
            _buildNumberSelector(
              value: _scoringEnds,
              min: 1,
              max: 99,
              onChanged: (value) => setState(() => _scoringEnds = value),
            ),

            const SizedBox(height: 24),

            // Green Time
            _buildSectionTitle('Green Time (Shooting Time)'),
            const SizedBox(height: 8),
            _buildGreenTimeSelection(),

            const SizedBox(height: 24),

            // Timer Preview
            _buildTimerPreview(),

            const SizedBox(height: 32),

            // Start Button
            Center(
              child: ElevatedButton(
                onPressed: _startMatch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  'START MATCH',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildModeSelection() {
    return Row(
      children: [
        _buildModeChip('ABCD', ArcheryMode.abcd, '4 Players'),
        const SizedBox(width: 8),
        _buildModeChip('ABC', ArcheryMode.abc, '3 Players'),
        const SizedBox(width: 8),
        _buildModeChip('AB-CD', ArcheryMode.abCd, '2 Teams'),
      ],
    );
  }

  Widget _buildModeChip(String label, ArcheryMode mode, String subtitle) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = mode),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberSelector({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 32,
        ),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 32,
        ),
      ],
    );
  }

  Widget _buildGreenTimeSelection() {
    return Row(
      children: _greenTimeOptions.map((time) {
        final isSelected = _greenTime == time;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _greenTime = time),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${time}s',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimerPreview() {
    final totalCycleTime = 10 + _greenTime + 30;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timer Cycle Preview',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTimerPhasePreview('🔴 RED', '10s', Colors.red),
              const Icon(Icons.arrow_forward, size: 16),
              _buildTimerPhasePreview('🟢 GREEN', '${_greenTime}s', Colors.green),
              const Icon(Icons.arrow_forward, size: 16),
              _buildTimerPhasePreview('🟡 YELLOW', '30s', Colors.yellow[700]!),
            ],
          ),
          const SizedBox(height: 8),
          Text('Total cycle: ${totalCycleTime}s'),
        ],
      ),
    );
  }

  Widget _buildTimerPhasePreview(String label, String time, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.fromRGBO(color.red, color.green, color.blue, 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10)),
            Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _startMatch() {
    if (_scoringEnds < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scoring sets must be at least 1')),
      );
      return;
    }

    final controllerCubit = sl<ArcheryControllerCubit>();
    final timerCubit = sl<ArcheryTimerCubit>();

    // Set configuration
    controllerCubit.setMode(_selectedMode);
    controllerCubit.setPracticeEnds(_practiceEnds);
    controllerCubit.setScoringEnds(_scoringEnds);
    controllerCubit.setGreenTime(_greenTime);

    timerCubit.setGreenTime(_greenTime);

    // Initialize match
    controllerCubit.initializeMatch();

    // Navigate to archery screen
    context.pop();
  }
}
