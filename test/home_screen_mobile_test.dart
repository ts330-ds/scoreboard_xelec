import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:xelex_esp/feature/bluetooth/presentation/cubit/ble/ble_cubit.dart';
import 'package:xelex_esp/feature/bluetooth/presentation/cubit/ble/ble_state.dart';
import 'package:xelex_esp/feature/home/presentation/layout/home_screen_mobile.dart';

class MockBleCubit extends MockCubit<BleState> implements BleCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(BleState.idle());
  });

  Widget _wrapWithApp(Widget child, BleCubit cubit) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return MaterialApp(
          home: BlocProvider.value(value: cubit, child: child),
        );
      },
    );
  }

  testWidgets('shows bluetooth not connected when idle', (tester) async {
    final cubit = MockBleCubit();
    when(() => cubit.state).thenReturn(BleState.idle());
    whenListen(
      cubit,
      const Stream<BleState>.empty(),
      initialState: BleState.idle(),
    );

    await tester.pumpWidget(_wrapWithApp(const HomeScreenMobile(), cubit));
    await tester.pumpAndSettle();

    expect(find.text('Bluetooth not connected'), findsOneWidget);
  });

  testWidgets('shows device info and disconnect when connected', (
    tester,
  ) async {
    final cubit = MockBleCubit();
    final connectedState = BleState.connected(
      deviceName: 'Test Device',
      deviceId: 'id-123',
      rssi: -55,
    );

    when(() => cubit.state).thenReturn(connectedState);
    whenListen(
      cubit,
      const Stream<BleState>.empty(),
      initialState: connectedState,
    );

    await tester.pumpWidget(_wrapWithApp(const HomeScreenMobile(), cubit));
    await tester.pumpAndSettle();

    expect(find.text('Test Device'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);
  });
}
