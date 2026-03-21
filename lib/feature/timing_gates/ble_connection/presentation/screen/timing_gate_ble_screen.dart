import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/presentation/cubit/timing_gate_bluetooth_cubit.dart';
import 'package:xelex_esp/feature/timing_gates/ble_connection/presentation/layout/timing_gate_ble_mobile.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class TimingGateBleScreen extends StatelessWidget {
  const TimingGateBleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<TimingGateBleCubit>(),
      child: const TimingGateBleMobile(),
    );
  }
}
