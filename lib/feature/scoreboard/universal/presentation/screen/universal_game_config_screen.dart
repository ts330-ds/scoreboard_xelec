import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../../../../../responsive/adaptive_scaffold.dart';
import '../../../../../service/dependency_injection/di_service.dart';
import '../../../game_config/presentation/widget/two_textfield_widget.dart';
import '../cubit/controller/universal_game_controller_cubit.dart';
import '../cubit/controller/universal_game_controller_state.dart';


class UniversalGameConfigScreen extends StatefulWidget {
  const UniversalGameConfigScreen({super.key});

  @override
  State<UniversalGameConfigScreen> createState() =>
      _UniversalGameConfigScreenState();
}

class _UniversalGameConfigScreenState
    extends State<UniversalGameConfigScreen> {
  late final TextEditingController team1Controller;
  late final TextEditingController team2Controller;

  Color? team1Color;
  Color? team2Color;
  TotalSets selectedTotalSets = TotalSets.five;

  @override
  void initState() {
    super.initState();

    final state = sl<UniversalGameControllerCubit>().state;

    team1Controller = TextEditingController(text: state.team1Name);
    team2Controller = TextEditingController(text: state.team2Name);

    team1Color = state.team1Color;
    team2Color = state.team2Color;

    selectedTotalSets = state.totalSets;
  }

  bool _isValid() {
    return team1Controller.text.trim().isNotEmpty &&
        team2Controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    team1Controller.dispose();
    team2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<UniversalGameControllerCubit>()),
      ],
      child: AdaptiveScaffold(
        title: 'Game Config',
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// TEAM NAMES + COLORS
              TwoTextFieldWidget(
                team1Controller: team1Controller,
                team2Controller: team2Controller,
                team1Color: team1Color,
                team2Color: team2Color,
                onTeam1ColorChanged: (c) => setState(() => team1Color = c),
                onTeam2ColorChanged: (c) => setState(() => team2Color = c),
              ),

              const SizedBox(height: 24),

              /// TOTAL SETS SELECTION
              const Text(
                "Total Sets",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Row(
                children: TotalSets.values.map((sets) {
                  final isSelected = selectedTotalSets == sets;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => selectedTotalSets = sets);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                          isSelected ? Colors.black : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sets == TotalSets.three ? '3 SETS' : '5 SETS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                            isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              widgetGap(),

              /// SAVE BUTTON
              Builder(
                builder: (context) {
                  final cubit = context.read<UniversalGameControllerCubit>();

                  return ElevatedButton(
                    onPressed: () {
                      if (!_isValid()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter both team names'),
                          ),
                        );
                        return;
                      }


                      cubit.setTotalSets(selectedTotalSets);
                      cubit.setTeam1Name(team1Controller.text);
                      cubit.setTeam2Name(team2Controller.text);
                      cubit.setTeam1Color(team1Color ?? Colors.red);
                      cubit.setTeam2Color(team2Color ?? Colors.blue);

                      // (future) yahin team name / color state me add ho sakta hai

                      context.pop();
                    },
                    child: const Text('SAVE'),
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
