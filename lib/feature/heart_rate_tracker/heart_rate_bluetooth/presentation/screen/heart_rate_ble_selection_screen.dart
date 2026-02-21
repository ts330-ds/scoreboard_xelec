import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/presentation/layout/heart_rate_ble_selection_mobile.dart';
import 'package:xelex_esp/responsive/responsive_layout_wrapper.dart';
import 'package:xelex_esp/service/dependency_injection/di_service.dart';

class HeartRateBleSelectionScreen extends StatelessWidget {
  const HeartRateBleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<HeartBleCubit>()),
      ],
      child: ResponsiveLayout(
        mobile: HeartBleSelectionMobile(),
        tablet: HeartBleSelectionMobile(),
        desktop: HeartBleSelectionMobile(),
      ),
    );
  }
}
