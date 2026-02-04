import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/scoreboard/universal/presentation/widgets/winner_set_selector.dart';
import 'package:xelex_esp/utility/universal_method.dart';

import '../../../../../common_widget/brightness_slider_widget.dart';
import '../../../../../common_widget/buzzerWidget.dart';
import '../../../../../service/dependency_injection/di_service.dart';
import '../../../../bluetooth/service/ble_service.dart';
import '../cubit/controller/universal_game_controller_cubit.dart';
import '../cubit/controller/universal_game_controller_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UniversalGameControllerPanel extends StatelessWidget {
  const UniversalGameControllerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [

          _setSelector(),
          const SizedBox(height: 16),
          _scoreControls(),

          widgetGap(),
          SetWinnerSelector(),
          widgetGap(),
          BlocSelector<UniversalGameControllerCubit, UniversalGameControllerState, int>(
            selector: (state) => state.tempBrightness,
            builder: (context, brightness) {
              return BrightnessSliderMinimal(
                value: brightness.toDouble(),
                onChanged: (value) {
                  context.read<UniversalGameControllerCubit>().setTempBrightness(value.toInt());
                },
                onChangedEnd: (double value) {
                  context.read<UniversalGameControllerCubit>().setBrightness(value.toInt());
                },
              );
            },
          ),
          widgetGap(),
          Align(
            alignment: Alignment.centerRight,
            child: BuzzerButton(bleService: sl<BleService>()),
          ),
        ],
      ),
    );
  }


Widget _playerSelector() {
  return BlocBuilder<UniversalGameControllerCubit, UniversalGameControllerState>(
    buildWhen: (p, c) => p.activePlayer != c.activePlayer,
    builder: (context, state) {
      return Row(
        children: PlayerType.values.map((player) {
          final selected = state.activePlayer == player;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                context.read<UniversalGameControllerCubit>().selectPlayer(player);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: selected ? Colors.orange : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text(
                  player == PlayerType.player1 ? 'PLAYER 1' : 'PLAYER 2',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

Widget _setSelector() {
  return BlocBuilder<UniversalGameControllerCubit, UniversalGameControllerState>(
    buildWhen: (p, c) =>
    p.selectedSet != c.selectedSet ||
        p.totalSets != c.totalSets,
    builder: (context, state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Sets",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(state.maxSets, (index) {
              final setNo = index + 1;
              final selected = state.selectedSet == setNo;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.read<UniversalGameControllerCubit>().selectSet(setNo);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Text(
                      'S$setNo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );
    },
  );
}

  Widget _scoreControls() {
    return BlocBuilder<UniversalGameControllerCubit, UniversalGameControllerState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 PLAYER 1
            const Text(
              "PLAYER 1",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: "-",
                    backgroundColor: Colors.red,
                    onPressed: () {
                      context.read<UniversalGameControllerCubit>()
                        ..selectPlayer(PlayerType.player1)
                        ..decrementScore();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: "+",
                    backgroundColor: Colors.green,
                    onPressed: () {
                      context.read<UniversalGameControllerCubit>()
                        ..selectPlayer(PlayerType.player1)
                        ..incrementScore();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// 🔹 PLAYER 2
            const Text(
              "PLAYER 2",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: "-",
                    backgroundColor: Colors.red,
                    onPressed: () {
                      context.read<UniversalGameControllerCubit>()
                        ..selectPlayer(PlayerType.player2)
                        ..decrementScore();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    label: "+",
                    backgroundColor: Colors.green,
                    onPressed: () {
                      context.read<UniversalGameControllerCubit>()
                        ..selectPlayer(PlayerType.player2)
                        ..incrementScore();
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }




  Widget _controlButton({
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
}

