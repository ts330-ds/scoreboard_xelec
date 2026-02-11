import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:xelex_esp/feature/home/presentation/widget/game_card.dart';
import '../../../../responsive/adaptive_scaffold.dart';
import '../../../../router/app_path.dart';
import '../../../bluetooth/presentation/cubit/ble/ble_cubit.dart';
import '../../../bluetooth/presentation/cubit/ble/ble_state.dart';

class HomeScreenMobile extends StatelessWidget {
  const HomeScreenMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final bleCubit = context.read<BleCubit>();
    final games = [
      GameCard(
        name: 'Archery',
        iconPath: "images/svg_icon/archery.svg",
        onTap: () {
          bleCubit.setGame("AR");
          context.push(AppPaths.archery);
        },
      ),
      GameCard(
        name: 'Badminton',
        iconPath: "images/svg_icon/badminton.svg",
        onTap: () {
          bleCubit.setGame("BD");
          context.push(AppPaths.badmintonConfig);
        },
      ),
      GameCard(
        name: 'Basketball',
        iconPath: "images/svg_icon/basketball.svg",
        onTap: () {
          bleCubit.setGame("BB");
          context.push(AppPaths.basketballConfig);
        },
      ),
      GameCard(
        name: 'Football',
        iconPath: "images/svg_icon/shoot.svg",
        onTap: () {
          bleCubit.setGame("FO");
          context.push(AppPaths.footballConfig);
        },
      ),
      GameCard(
        name: 'HandBall',
        iconPath: "images/svg_icon/handball.svg",
        onTap: () {
          bleCubit.setGame("HB");
          context.push(AppPaths.handballConfig);
        },
      ),
      GameCard(
        name: 'Hockey',
        iconPath: "images/svg_icon/ice-hockey.svg",
        onTap: () {
          bleCubit.setGame("HO");
          context.push(AppPaths.hockeyConfig);
        },
      ),
      GameCard(
        name: 'Kho Kho',
        iconPath: "images/svg_icon/kho-kho.svg",
        onTap: () {
          bleCubit.setGame("KK");
          context.push(AppPaths.khoKhoConfig);
        },
      ),
      GameCard(
        name: 'Kabaddi',
        iconPath: "images/svg_icon/kabaddi.svg",
        onTap: () {
          bleCubit.setGame("KA");
          context.push(AppPaths.khabaddisConfig);
        },
      ),
      GameCard(
        name: 'Table Tennis',
        iconPath: "images/svg_icon/table-tennis.svg",
        onTap: () {
          bleCubit.setGame("TT");
          context.push(AppPaths.tableTennisConfig);
        },
      ),
      GameCard(
        name: 'Universal Game',
        iconPath: "images/svg_icon/universal_game.svg",
        onTap: () {
          bleCubit.setGame("UG");
          context.push(AppPaths.universalConfig);
        },
      ),
    ];

    return AdaptiveScaffold(
      title: 'Select Games',
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: BlocBuilder<BleCubit, BleState>(
              builder: (context, state) {
                final isConnected = state.status == BleStatus.connected;
                final rssi = state.rssi ?? -100;

                return Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.w),
                    border: Border.all(color: Colors.black12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12.w,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_disabled,
                            color: isConnected ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              isConnected
                                  ? (state.deviceName ?? 'Connected')
                                  : 'Bluetooth not connected',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          if (isConnected) ...[
                            SizedBox(width: 8.w),
                            _SignalIcon(rssi),
                            SizedBox(width: 4.w),
                            Text(
                              "$rssi dBm",
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ],
                        ],
                      ),
                      if (isConnected) ...[
                        SizedBox(height: 8.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              context.read<BleCubit>().disconnectBluetooth();
                            },
                            icon: const Icon(Icons.link_off, color: Colors.red),
                            label: const Text(
                              "Disconnect",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: ListView.separated(
              itemCount: games.length,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              itemBuilder: (context, index) {
                final game = games[index];
                final isEven = index % 2 == 0;

                return GameCard(
                  name: game.name,
                  iconPath: game.iconPath,
                  onTap: game.onTap,
                  iconRight: isEven,
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(height: 32.h);
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
