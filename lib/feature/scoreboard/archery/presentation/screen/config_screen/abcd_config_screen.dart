import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/bluetooth/mapper/archery_ble_mapper.dart';
import 'package:xelex_esp/feature/bluetooth/service/ble_service.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../../cubit/abcd_cubit/abcd_timer_cubit.dart';

class AbcdConfigScreen extends StatefulWidget {
  const AbcdConfigScreen({super.key});

  @override
  State<AbcdConfigScreen> createState() => _AbcdConfigScreenState();
}

class _AbcdConfigScreenState extends State<AbcdConfigScreen> {
  static const int _minSeconds = 1;
  static const int _maxSeconds = 9999;
  static const int _stepSeconds = 1;
  static const int _minSighterRounds = 0;
  static const int _minScoringRounds = 1;
  static const int _maxRounds = 99;

  late final TextEditingController _secondsController;
  late final AbcdTimerCubit _timerCubit;
  late final BleService _bleService;
  late final ArcheryBleMapper _bleMapper;

  int _initialSeconds = 90;
  int _sighterRounds = 0;
  int _scoringRounds = 6;

  @override
  void initState() {
    super.initState();
    _timerCubit = sl<AbcdTimerCubit>();
    _bleService = sl<BleService>();
    _bleMapper = sl<ArcheryBleMapper>();
    final state = _timerCubit.state;
    _initialSeconds = state.initialSeconds;
    _sighterRounds = state.totalSighterRounds;
    _scoringRounds = state.totalScoringRounds;
    _secondsController = TextEditingController(
      text: _initialSeconds.toString(),
    );
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
        title: 'ABCD Config',
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Initial Duration (seconds)'),
              const SizedBox(height: 8),
              _buildDurationInput(),
              const SizedBox(height: 24),
              _buildSectionTitle('Sighter Rounds'),
              const SizedBox(height: 8),
              _buildRoundsSelector(
                value: _sighterRounds,
                minValue: _minSighterRounds,
                onDecrement: () =>
                    setState(() => _sighterRounds = _sighterRounds - 1),
                onIncrement: () =>
                    setState(() => _sighterRounds = _sighterRounds + 1),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Scoring Rounds'),
              const SizedBox(height: 8),
              _buildRoundsSelector(
                value: _scoringRounds,
                minValue: _minScoringRounds,
                onDecrement: () =>
                    setState(() => _scoringRounds = _scoringRounds - 1),
                onIncrement: () =>
                    setState(() => _scoringRounds = _scoringRounds + 1),
              ),
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

  Widget _buildRoundsSelector({
    required int value,
    required int minValue,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: value > minValue ? onDecrement : null,
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
            value.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: value < _maxRounds ? onIncrement : null,
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
          content: Text('Duration must be between 1 and 9999 seconds.'),
        ),
      );
      return;
    }

    final clampedSighter = _sighterRounds.clamp(0, _maxRounds);
    final clampedScoring = _scoringRounds.clamp(_minScoringRounds, _maxRounds);

    if (clampedSighter > 0) {
      try {
        _bleService.send(_bleMapper.setEndInfo('SI END 1'));
      } catch (_) {
        // Ignore BLE errors in config screen
      }
    }else{
      try {
        _bleService.send(_bleMapper.setEndInfo('SC END 1'));
      } catch (_) {
        // Ignore BLE errors in config screen
      }
    }

    _timerCubit.setInitialSeconds(_initialSeconds);
    _timerCubit.setSighterRounds(clampedSighter);
    _timerCubit.setScoringRounds(clampedScoring);
    context.pushReplacement(AppPaths.archeryAbcdScreen);
  }
}
