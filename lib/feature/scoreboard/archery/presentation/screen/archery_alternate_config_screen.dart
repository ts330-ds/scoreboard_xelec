import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/archery/presentation/cubit/alternate_game_controller/archery_alternate_game_controller_state.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

import '../cubit/alternate_game_controller/archery_alternate_game_controller.dart';
import '../cubit/alternate_game_timer/archery_alternate_game_timer_cubit.dart';

class ArcheryAlternateConfigScreen extends StatefulWidget {
  const ArcheryAlternateConfigScreen({super.key});

  @override
  State<ArcheryAlternateConfigScreen> createState() =>
      _ArcheryAlternateConfigScreenState();
}

class _ArcheryAlternateConfigScreenState
    extends State<ArcheryAlternateConfigScreen> {
  final int _greenTime = 90;

  late TextEditingController _greenTimeController;
  late TextEditingController _durationController;

  // NEW: round type + set timer
  String _roundType = 'Individual Round';
  final List<String> _roundTypes = ['Individual Round', 'Team Round'];

  ArcheryAlternateSide _startSide = ArcheryAlternateSide.left;

  int _totalRounds = 6;
  final int _minRounds = 1;
  final int _maxRounds = 99;

  int _totalDurationSeconds = 60;
  final int _minDurationSeconds = 20;
  final int _maxDurationSeconds = 900;
  final int _stepSeconds = 10;

  late final ArcheryAlternateGameTimerCubit _timerCubit;
  late final ArcheryAlternateGameControllerCubit _controllerCubit;

  @override
  void initState() {
    super.initState();
    _greenTimeController = TextEditingController(text: _greenTime.toString());
    _durationController = TextEditingController(
      text: _totalDurationSeconds.toString(),
    );
    _timerCubit = sl<ArcheryAlternateGameTimerCubit>();
    _controllerCubit = sl<ArcheryAlternateGameControllerCubit>();
  }

  @override
  void dispose() {
    _greenTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _timerCubit),
        BlocProvider.value(value: _controllerCubit),
      ],
      child: AdaptiveScaffold(
        title: 'Alternate Config',
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Round Type'),
              const SizedBox(height: 8),
              _buildRoundTypeSelection(),

              const SizedBox(height: 24),

              _buildSectionTitle('Start Side'),
              const SizedBox(height: 8),
              _buildStartSideSelection(),

              const SizedBox(height: 24),

              _buildSectionTitle('Select Rounds'),
              const SizedBox(height: 8),
              _buildNumberSelector(
                value: _totalRounds,
                min: _minRounds,
                max: _maxRounds,
                step: 1,
                onChanged: (value) => setState(() => _totalRounds = value),
              ),

              const SizedBox(height: 24),

              _buildSectionTitle('Total Duration (seconds)'),
              const SizedBox(height: 8),
              _buildDurationInput(),

              const SizedBox(height: 32),

              Center(
                child: ElevatedButton(
                  onPressed: _validateAndSave,
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

  Widget _buildRoundTypeSelection() {
    return DropdownButtonFormField<String>(
      initialValue: _roundType,
      items: _roundTypes
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _roundType = value);
        // final mode = value == 'Team Round'
        //     ? ArcheryGameMode.alternatingFinals
        //     : ArcheryGameMode.simple;
        // _controllerCubit.setGameMode(mode);
        // _timerCubit.setGameMode(mode);
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildStartSideSelection() {
    return DropdownButtonFormField<ArcheryAlternateSide>(
      initialValue: _startSide,
      items: const [
        DropdownMenuItem(value: ArcheryAlternateSide.left, child: Text('Left')),
        DropdownMenuItem(
          value: ArcheryAlternateSide.right,
          child: Text('Right'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _startSide = value);
        // _controllerCubit.setActiveSide(value);
        //_timerCubit.setActiveSide(value);
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildNumberSelector({
    required int value,
    required int min,
    required int max,
    required int step,
    required ValueChanged<int> onChanged,
    String? suffix,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - step) : null,
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
            suffix == null ? '$value' : '$value $suffix',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 32,
        ),
      ],
    );
  }

  Widget _buildDurationInput() {
    return Row(
      children: [
        IconButton(
          onPressed: _totalDurationSeconds > _minDurationSeconds
              ? () => _setDuration(_totalDurationSeconds - 1)
              : null,
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 32,
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: _durationController,
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
              _setDuration(parsed, updateText: false);
            },
            onEditingComplete: () {
              final parsed = int.tryParse(_durationController.text);
              _setDuration(parsed ?? _totalDurationSeconds);
              FocusScope.of(context).unfocus();
            },
          ),
        ),
        IconButton(
          onPressed: _totalDurationSeconds < _maxDurationSeconds
              ? () => _setDuration(_totalDurationSeconds + 1)
              : null,
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 32,
        ),
      ],
    );
  }

  void _setDuration(int value, {bool updateText = true}) {
    final clamped = value.clamp(_minDurationSeconds, _maxDurationSeconds);
    setState(() => _totalDurationSeconds = clamped);
    if (updateText) {
      _durationController.text = clamped.toString();
      _durationController.selection = TextSelection.collapsed(
        offset: _durationController.text.length,
      );
    }
  }

  void _validateAndSave() {
    if (_totalRounds < _minRounds || _totalRounds > _maxRounds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid rounds (1-99).')),
      );
      return;
    }

    if (_totalDurationSeconds < _minDurationSeconds ||
        _totalDurationSeconds > _maxDurationSeconds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total duration must be between 20 and 900 seconds.'),
        ),
      );
      return;
    }
    final mode = _roundType == 'Team Round'
        ? ArcheryGameMode.alternatingFinals
        : ArcheryGameMode.simple;

    _controllerCubit.setGameMode(mode);
    _timerCubit.setGameMode(mode);
    _timerCubit.setTime(_totalDurationSeconds, mode);
    _controllerCubit.setTotalRounds(_totalRounds, mode);
    _controllerCubit.setActiveSide(_startSide);
    _timerCubit.switchSide(_startSide);
    context.pushReplacement(AppPaths.archeryAlternateScreen);
  }
}
