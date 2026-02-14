import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../cubit/individual_cubit/timer/archery_individual_timer_cubit.dart';
import '../cubit/individual_cubit/timer/archery_individual_timer_state.dart';

class ArcheryIndividualConfigScreen extends StatefulWidget {
  const ArcheryIndividualConfigScreen({super.key});

  @override
  State<ArcheryIndividualConfigScreen> createState() =>
      _ArcheryIndividualConfigScreenState();
}

class _ArcheryIndividualConfigScreenState
    extends State<ArcheryIndividualConfigScreen> {
  static const int _minSeconds = 10;
  static const int _maxSeconds = 900;
  static const int _stepSeconds = 5;
  static const int _minRounds = 1;
  static const int _maxRounds = 99;

  late final TextEditingController _secondsController;
  late final ArcheryIndividualTimerCubit _timerCubit;
  int _initialSeconds = 20;
  int _totalRounds = 3;
  ArcheryIndividualSide _startSide = ArcheryIndividualSide.left;

  @override
  void initState() {
    super.initState();
    _secondsController = TextEditingController(
      text: _initialSeconds.toString(),
    );
    _timerCubit = sl<ArcheryIndividualTimerCubit>();
  }

  @override
  void dispose() {
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _timerCubit,
      child: AdaptiveScaffold(
        title: 'Individual Config',
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Start Side'),
              const SizedBox(height: 8),
              _buildStartSideSelection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Initial Duration (seconds)'),
              const SizedBox(height: 8),
              _buildDurationInput(),
              const SizedBox(height: 24),
              _buildSectionTitle('Total Rounds'),
              const SizedBox(height: 8),
              _buildRoundsSelector(),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _applyConfig,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'SAVE',
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStartSideSelection() {
    return DropdownButtonFormField<ArcheryIndividualSide>(
      initialValue: _startSide,
      items: const [
        DropdownMenuItem(
          value: ArcheryIndividualSide.left,
          child: Text('Left'),
        ),
        DropdownMenuItem(
          value: ArcheryIndividualSide.right,
          child: Text('Right'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _startSide = value);
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildDurationInput() {
    return Row(
      children: [
        IconButton(
          onPressed: _initialSeconds > _minSeconds
              ? () => _setSeconds(_initialSeconds - _stepSeconds)
              : null,
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 32,
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _secondsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              suffixText: 's',
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed == null) return;
              _setSeconds(parsed, updateText: false);
            },
            onEditingComplete: () {
              final parsed = int.tryParse(_secondsController.text);
              _setSeconds(parsed ?? _initialSeconds);
              FocusScope.of(context).unfocus();
            },
          ),
        ),
        IconButton(
          onPressed: _initialSeconds < _maxSeconds
              ? () => _setSeconds(_initialSeconds + _stepSeconds)
              : null,
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 32,
        ),
      ],
    );
  }

  Widget _buildRoundsSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: _totalRounds > _minRounds
              ? () => setState(() => _totalRounds -= 1)
              : null,
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 32,
        ),
        Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$_totalRounds',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: _totalRounds < _maxRounds
              ? () => setState(() => _totalRounds += 1)
              : null,
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 32,
        ),
      ],
    );
  }

  void _setSeconds(int value, {bool updateText = true}) {
    final clamped = value.clamp(_minSeconds, _maxSeconds);
    setState(() => _initialSeconds = clamped);
    if (updateText) {
      _secondsController.text = clamped.toString();
      _secondsController.selection = TextSelection.collapsed(
        offset: _secondsController.text.length,
      );
    }
  }

  void _applyConfig() {
    if (_initialSeconds < _minSeconds || _initialSeconds > _maxSeconds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duration must be between 10 and 900 seconds.'),
        ),
      );
      return;
    }

    _timerCubit.setInitialSeconds(_initialSeconds);
    _timerCubit.setTotalRounds(_totalRounds);
    _timerCubit.setStartSide(_startSide);
    context.pushReplacement(AppPaths.archeryIndividualRoundScreen);
  }
}
