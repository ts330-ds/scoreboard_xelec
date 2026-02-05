import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/scoreboard/table_tennis/presentation/cubit/controller/table_tennis_controller_cubit.dart';
import 'package:xelex_esp/feature/scoreboard/game_config/presentation/widget/two_textfield_widget.dart';
import 'package:xelex_esp/responsive/adaptive_scaffold.dart';
import 'package:xelex_esp/router/app_path.dart';
import '../../../../../service/dependency_injection/di_service.dart';


class TableTennisConfigScreen extends StatefulWidget {
  const TableTennisConfigScreen({super.key});

  @override
  State<TableTennisConfigScreen> createState() => _TableTennisConfigScreenState();
}

class _TableTennisConfigScreenState extends State<TableTennisConfigScreen> {
  late final TextEditingController team1Controller;
  late final TextEditingController team2Controller;

  Color? team1Color;
  Color? team2Color;

  @override
  void initState() {
    super.initState();
    final controlState = sl<TableTennisControllerCubit>().state;

    team1Controller = TextEditingController(text: controlState.team1Name);
    team2Controller = TextEditingController(text: controlState.team2Name);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<TableTennisControllerCubit>(),
      child: AdaptiveScaffold(
        title: 'Table Tennis Config',
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
              Builder(
                builder: (BuildContext context) {
                  final controlCubit = context.read<TableTennisControllerCubit>();
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
                      
                      controlCubit.setTeam1Name(team1Controller.text);
                      controlCubit.setTeam2Name(team2Controller.text);
                      controlCubit.setTeam1Color(team1Color!);
                      controlCubit.setTeam2Color(team2Color!);

                      context.pushReplacement(AppPaths.table_tennis);
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
