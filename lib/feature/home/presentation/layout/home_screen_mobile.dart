import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/home/presentation/widget/game_card.dart';
import '../../../../responsive/adaptive_scaffold.dart';
import '../../../../router/app_path.dart';
import '../../../bluetooth/presentation/cubit/ble/ble_cubit.dart';
import '../../../bluetooth/presentation/cubit/ble/ble_state.dart';

class HomeScreenMobile extends StatelessWidget {
  const HomeScreenMobile({super.key});

  int _crossAxisCount(double width) {
    if (width >= 1200) return 4; // Desktop
    if (width >= 800) return 3;  // Tablet
    return 2;                    // Mobile
  }

  @override
  Widget build(BuildContext context) {
    final ble_cubit = context.read<BleCubit>();
    final games = [
       GameCard(
        title: 'Basketball',
        icon: Icons.sports_basketball,
        onTap: (){
          context.push(AppPaths.basketball);
          //ble_cubit.setGame("BB");
        },
      ),
       GameCard(
        title: 'HandBall',
        icon: Icons.sports_handball,
       onTap: (){
          context.push(AppPaths.handball);
         // ble_cubit.setGame("HB");
       },
      ),
       GameCard(
        title: 'Hockey',
        icon: Icons.sports_hockey,
        onTap: (){
          context.push(AppPaths.hockey);
          //ble_cubit.setGame("HO");
        },
      ),
       GameCard(
        title: 'Table Tennis',
        icon: Icons.sports_tennis,
        onTap: (){
          context.push(AppPaths.table_tennis);
          //ble_cubit.setGame("TT");
        },
      ),
       GameCard(
        title: 'Kho Kho',
        icon: Icons.sports_gymnastics,
        onTap: (){
          context.push(AppPaths.kho_kho);
          //ble_cubit.setGame("KK");
        },
      ),
      GameCard(
        title: 'Football',
        icon: Icons.sports_soccer,
        onTap: (){
          context.push(AppPaths.football);
          //ble_cubit.setGame("FB");
        },
      ),
    ];

    return AdaptiveScaffold(
      title: 'Home Screen',
      body: Column(
        children: [
          BlocBuilder<BleCubit, BleState>(
      builder: (context, state) {
        if (state.status != BleStatus.connected) {
          return const Text(
            "Bluetooth not connected",
            style: TextStyle(color: Colors.red),
          );
        }

        final rssi = state.rssi ?? -100;

        return Row(
          children: [
            const Icon(Icons.bluetooth_connected,
                color: Colors.green),
            const SizedBox(width: 8),
            Text(
              "${state.deviceName}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            _SignalIcon(rssi),
            const SizedBox(width: 4),
            Text("$rssi dBm"),
          ],
        );
      },
      ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount(constraints.maxWidth),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: games.length,
                  itemBuilder: (_, index) {
                    final game = games[index];
                    return GameCard(
                      title: game.title,
                      icon: game.icon,
                      onTap: game.onTap,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
class _SignalIcon extends StatelessWidget {
  final int rssi;
  const _SignalIcon(this.rssi);

  @override
  Widget build(BuildContext context) {
    if (rssi >= -60) {
      return const Icon(Icons.signal_wifi_4_bar,
          color: Colors.green);
    } else if (rssi >= -75) {
      return const Icon(Icons.signal_wifi_0_bar,
          color: Colors.orange);
    } else {
      return const Icon(Icons.signal_wifi_4_bar,
          color: Colors.red);
    }
  }
}
