import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/controlPanal/controlPanalCubit.dart';
import 'package:xelex_esp/feature/scoreboard/basketball/presentation/cubit/timer/basketball_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/game_config/presentation/widget/timer_text_field.dart';
import 'package:xelex_esp/feature/scoreboard/game_config/presentation/widget/two_textfield_widget.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import '../../../../../service/dependency_injection/di_service.dart';

class BasketBallConfigScreen extends StatefulWidget {
  const BasketBallConfigScreen({super.key});

  @override
  State<BasketBallConfigScreen> createState() => _BasketBallConfigScreenState();
}

class _BasketBallConfigScreenState extends State<BasketBallConfigScreen> {
  late final TextEditingController team1Controller;
  late final TextEditingController team2Controller;
  late final TextEditingController timerController;

  Color? team1Color;
  Color? team2Color;

  @override
  void initState() {
    super.initState();
    // 1. Get current state from Cubits
    final controlState = sl<BasketControlPanelCubit>().state;
    final timerState = sl<BasketBallTimerCubit>().state;

    // 2. Initialize controllers with current values
    team1Controller = TextEditingController(text: controlState.team1Name);
    team2Controller = TextEditingController(text: controlState.team2Name);
    timerController = TextEditingController(
      text: (timerState.seconds ~/ 60).toString(),
    );

    // 3. Initialize colors
    team1Color = controlState.team1Color;
    team2Color = controlState.team2Color;
  }

  bool _isValid() {
    return team1Controller.text.trim().isNotEmpty &&
        team2Controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    team1Controller.dispose();
    team2Controller.dispose();
    timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<BasketControlPanelCubit>()),
        BlocProvider.value(value: sl<BasketBallTimerCubit>()),
      ],
      child: AdaptiveScaffold(
        title: 'Basketball Config',
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TwoTextFieldWidget(
                team1Controller: team1Controller,
                team2Controller: team2Controller,
                team1Color: team1Color,
                team2Color: team2Color,
                onTeam1ColorChanged: (color) {
                  setState(() => team1Color = color);
                },
                onTeam2ColorChanged: (color) {
                  setState(() => team2Color = color);
                },
              ),

              const SizedBox(height: 24),

              TimerTextFieldWidget(timerController: timerController),

              const SizedBox(height: 24),
              // SAVE BUTTON
              Builder(
                builder: (BuildContext context) {
                  final controlCubit = context.read<BasketControlPanelCubit>();
                  final timerCubit = context.read<BasketBallTimerCubit>();
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
                      if (timerController.text.isEmpty ||
                          int.tryParse(timerController.text) == null ||
                          int.parse(timerController.text) <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid timer'),
                          ),
                        );
                        return;
                      }

                      // Save to Cubits
                      controlCubit.setTeam1Name(team1Controller.text);
                      controlCubit.setTeam2Name(team2Controller.text);
                      controlCubit.setTeam1Color(team1Color ?? Colors.blue);
                      controlCubit.setTeam2Color(team2Color ?? Colors.red);
                      timerCubit.setTime(int.parse(timerController.text));
                      timerCubit.setQuarter(1);

                      // Navigate to Basketball Screen
                      context.pushReplacement(AppPaths.basketball);
                    },
                    child: const Text('SAVE'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
