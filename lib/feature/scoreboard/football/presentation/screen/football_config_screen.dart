import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/football/presentation/cubit/controller/football_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/football/presentation/cubit/timer/football_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/game_config/presentation/widget/timer_text_field.dart';
import 'package:xelex_esp/feature/scoreboard/game_config/presentation/widget/two_textfield_widget.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import '../../../../../service/dependency_injection/di_service.dart';

class FootballConfigScreen extends StatefulWidget {
  const FootballConfigScreen({super.key});

  @override
  State<FootballConfigScreen> createState() => _FootballConfigScreenState();
}

class _FootballConfigScreenState extends State<FootballConfigScreen> {
  TextEditingController? team1Controller;
  TextEditingController? team2Controller;
  TextEditingController? timerController;

  Color? team1Color;
  Color? team2Color;

  @override
  void initState() {
    super.initState();
    final controlState = sl<FootballControllerCubit>().state;
    final timerState = sl<FootballTimerCubit>().state;

    team1Controller = TextEditingController(text: controlState.team1Name);
    team2Controller = TextEditingController(text: controlState.team2Name);
    // Football timer duration is in seconds, convert to minutes for display
    // Default to 45 if duration is 0
    final minutes = timerState.duration > 0 ? (timerState.duration ~/ 60) : 45;
    timerController = TextEditingController(text: minutes.toString());

    team1Color = controlState.team1Color;
    team2Color = controlState.team2Color;
  }

  bool _isValid() {
    return team1Controller?.text.trim().isNotEmpty == true &&
        team2Controller?.text.trim().isNotEmpty == true;
  }

  @override
  void dispose() {
    team1Controller?.dispose();
    team2Controller?.dispose();
    timerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<FootballControllerCubit>()),
        BlocProvider.value(value: sl<FootballTimerCubit>()),
      ],
      child: AdaptiveScaffold(
        title: 'Football Config',
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (team1Controller != null &&
                  team2Controller != null &&
                  timerController != null) ...[
                TwoTextFieldWidget(
                  team1Controller: team1Controller!,
                  team2Controller: team2Controller!,
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

                TimerTextFieldWidget(timerController: timerController!),
              ],

              const SizedBox(height: 24),
              Builder(
                builder: (BuildContext context) {
                  final controlCubit = context.read<FootballControllerCubit>();
                  final timerCubit = context.read<FootballTimerCubit>();

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

                      controlCubit.updateTeam1Name(team1Controller!.text);
                      controlCubit.updateTeam2Name(team2Controller!.text);
                      controlCubit.updateTeam1Color(team1Color ?? Colors.red);
                      controlCubit.updateTeam2Color(team2Color ?? Colors.blue);

                      // Set timer duration from minutes to seconds
                      final minutes = int.tryParse(timerController!.text) ?? 45;
                      final durationInSeconds = minutes * 60;
                      timerCubit.setDuration(durationInSeconds);

                      context.pushReplacement(AppPaths.football);
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
