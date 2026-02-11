import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

import '../../../../../utility/universal_method.dart';
import '../cubit/controller/hockey_controller_cubit.dart';
import '../cubit/controller/hockey_controller_state.dart';

class HockeyTeamPanel extends StatelessWidget {
  bool isTeam1;
  HockeyTeamPanel({required this.isTeam1,super.key});


  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BlocSelector<
            HockeyControllerCubit,
            HockeyControllerState,
            (String, Color)>(
          selector: (state) =>
          isTeam1
              ? (state.team1Name, state.team1Color)
              : (state.team2Name, state.team2Color),
          builder: (context, team) {
            final (name, color) = team;

            return Text(
              name,
              style: context.text.titleLarge!.copyWith(color: color),
            );
          },
        ),

        const SizedBox(height: 6),

        // SCORE
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF2F2F2F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueGrey),
          ),
          child: BlocSelector<HockeyControllerCubit, HockeyControllerState, int>(
            selector: (state) => isTeam1?state.team1Score:state.team2Score,
            builder: (context,score) {
              return Text(
                formatScore(score),
                  textAlign: TextAlign.center,
                  style: context.text.titleLarge!.copyWith(color: context.colors.surface),
              );
            }
          ),
        ),

        const SizedBox(height: 10),

        BlocSelector<HockeyControllerCubit, HockeyControllerState, int>(
          selector: (state) => isTeam1? state.team1PenaltyCorner:state.team2PenaltyCorner,
          builder: (context, pc) {
            return _counterRow(label: "PC",value: pc.toString(), color: const Color(0xFFFFE082));
          }
        ),
        const SizedBox(height: 12),
        BlocSelector<HockeyControllerCubit, HockeyControllerState, int>(
          selector: (state) => isTeam1? state.team1Shootout:state.team2Shootout,
          builder: (context,so) {
            return _counterRow(label: "SO",value:so.toString(), color: const Color(0xFFED6C02));
          }
        ),
      ],
    );
  }

  Widget _counterRow({required String label, required Color color, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "$label -",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 48,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child:  Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
