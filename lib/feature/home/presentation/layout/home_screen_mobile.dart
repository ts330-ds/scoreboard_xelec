import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/home/presentation/widget/game_card.dart';
import 'package:xelex_esp/utility/appColor.dart';
import '../../../../responsive/adaptive_scaffold.dart';
import '../../../../router/app_path.dart';
import '../../../bluetooth/presentation/cubit/ble/ble_cubit.dart';
import '../../../bluetooth/presentation/cubit/ble/ble_state.dart';

class HomeScreenMobile extends StatelessWidget {
  const HomeScreenMobile({super.key});

  int _crossAxisCount(double width) {
    if (width >= 1200) return 4; // Desktop
    if (width >= 800) return 3; // Tablet
    return 2; // Mobile
  }

  @override
  Widget build(BuildContext context) {
    final bleCubit = context.read<BleCubit>();
    final games = [

      GameCard(
        name: 'Basketball',
        iconPath: "images/svg_icon/basketball.svg",
        onTap: () {
          context.push(AppPaths.basketball);
          bleCubit.setGame("BB");
        },
      ),
      GameCard(
        name: 'HandBall',
        iconPath: "images/svg_icon/handball.svg",
        onTap: () {
          context.push(AppPaths.handball);
          bleCubit.setGame("HB");
        },
      ),
      GameCard(
        name: 'Hockey',
        iconPath: "images/svg_icon/ice-hockey.svg",
        onTap: () {
          context.push(AppPaths.hockey);
          bleCubit.setGame("HO");
        },
      ),
      GameCard(
        name: 'Table Tennis',
        iconPath: "images/svg_icon/table-tennis.svg",
        onTap: () {
          context.push(AppPaths.table_tennis);
          bleCubit.setGame("TT");
        },
      ),
      GameCard(
        name: 'Kho Kho',
        iconPath: "images/svg_icon/kho-kho.svg",
        onTap: () {
          context.push(AppPaths.kho_kho);
          bleCubit.setGame("KK");
        },
      ),
      GameCard(
        name: 'Football',
        iconPath: "images/svg_icon/shoot.svg",
        onTap: () {
          context.push(AppPaths.football);
          bleCubit.setGame("FO");
        },
      ),
      GameCard(
        name: 'Kabaddi',
        iconPath: "images/svg_icon/kabaddi.svg",
        onTap: () {
          context.push(AppPaths.khabaddi);
          bleCubit.setGame("FB");
        },
      ),
      GameCard(
        name: 'Badminton',
        iconPath: "images/svg_icon/badminton.svg",
        onTap: () {
          context.push(AppPaths.badminton);
          bleCubit.setGame("BD");
        },
      ),
      GameCard(
        name: 'Universal Game',
        iconPath: "images/svg_icon/universal_game.svg",
        onTap: () {
          context.push(AppPaths.universal);
          bleCubit.setGame("UG");
        },
      ),

      GameCard(
        name: 'Archery',
        iconPath: "images/svg_icon/archery.svg",
        onTap: () {
          context.push(AppPaths.archery);
          bleCubit.setGame("UG");
        },
      ),
    ];

    return AdaptiveScaffold(
      title: 'Games',
      appBarBackground: Colors.transparent,
      textColor: Colors.black,
      body: Column(
        children: [
          BlocBuilder<BleCubit, BleState>(
            builder: (context, state) {
              if (state.status != BleStatus.connected) {
                return const Text("Bluetooth not connected", style: TextStyle(color: Colors.red));
              }

              final rssi = state.rssi ?? -100;

              return Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bluetooth_connected, color: Colors.green),
                      const SizedBox(width: 8),
                      Text("${state.deviceName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      _SignalIcon(rssi),
                      const SizedBox(width: 4),
                      Text("$rssi dBm"),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.read<BleCubit>().disconnectBluetooth();
                    },
                    icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
                    label: const Text("Disconnect", style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          ),
          Expanded(
            child: ListView.separated(
              itemCount: games.length,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemBuilder: (context, index) {
                final game = games[index];
                final isEven = index % 2 == 0;

                return GameCard(name: game.name, iconPath: game.iconPath, onTap: game.onTap, iconRight: isEven);
              }, separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 32);
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
      return const Icon(Icons.signal_wifi_4_bar, color: Colors.green);
    } else if (rssi >= -75) {
      return const Icon(Icons.signal_wifi_0_bar, color: Colors.orange);
    } else {
      return const Icon(Icons.signal_wifi_4_bar, color: Colors.red);
    }
  }
}
