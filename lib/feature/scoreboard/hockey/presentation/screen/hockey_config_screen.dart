import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/cubit/controller/hockey_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/hockey/presentation/cubit/timer/hockey_timer_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/game_config/presentation/widget/timer_text_field.dart';
import 'package:xelex_esp/feature/scoreboard/game_config/presentation/widget/two_textfield_widget.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import '../../../../../service/dependency_injection/di_service.dart';


class HockeyConfigScreen extends StatefulWidget {
  const HockeyConfigScreen({super.key});

  @override
  State<HockeyConfigScreen> createState() => _HockeyConfigScreenState();
}

class _HockeyConfigScreenState extends State<HockeyConfigScreen> {
  late final TextEditingController team1Controller;
  late final TextEditingController team2Controller;
  late final TextEditingController timerController;

  Color? team1Color;
  Color? team2Color;

  @override
  void initState() {
    super.initState();
    final controlState = sl<HockeyControllerCubit>().state;
    final timerState = sl<HockeyTimerCubit>().state;

    team1Controller = TextEditingController(text: controlState.team1Name);
    team2Controller = TextEditingController(text: controlState.team2Name);
    timerController = TextEditingController(text: (timerState.seconds ~/ 60).toString());

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
        BlocProvider.value(value: sl<HockeyControllerCubit>()),
        BlocProvider.value(value: sl<HockeyTimerCubit>())
      ],
      child: AdaptiveScaffold(
        title: 'Hockey Config',
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

              TimerTextFieldWidget(
                  timerController: timerController
              ),

              const SizedBox(height: 24),
              Builder(
                builder: (BuildContext context) {
                  final controlCubit = context.read<HockeyControllerCubit>();
                  final timerCubit = context.read<HockeyTimerCubit>();
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
                      if(timerController.text.isEmpty || int.tryParse(timerController.text) == null || int.parse(timerController.text) <= 0){
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid timer'),
                          ),
                        );
                        return;
                      }

                      controlCubit.setTeam1Name(team1Controller.text);
                      controlCubit.setTeam2Name(team2Controller.text);
                      controlCubit.setTeam1Color(team1Color ?? Colors.red);
                      controlCubit.setTeam2Color(team2Color ?? Colors.blue);
                      timerCubit.setTime(int.parse(timerController.text) * 60);

                      context.pushReplacement(AppPaths.hockey);
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
