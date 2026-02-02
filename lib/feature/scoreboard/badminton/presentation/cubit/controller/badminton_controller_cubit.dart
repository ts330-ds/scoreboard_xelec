import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../error/cubit/error_cubit.dart';
import '../../../../../../utility/universal_method.dart';
import '../../../../../bluetooth/mapper/badminton_ble_mapper.dart';
import '../../../../../bluetooth/service/ble_service.dart';
import 'badminton_controller_state.dart';

import 'package:flutter/material.dart';

class BadmintonControllerCubit
    extends Cubit<BadmintonControllerState> {
  final BleService bleService;
  final BadmintonBleMapper badmintonBleMapper;
  final GlobalErrorCubit globalErrorCubit;

  BadmintonControllerCubit({
    required this.bleService,
    required this.badmintonBleMapper,
    required this.globalErrorCubit,
  }) : super(BadmintonControllerState.initial());



  void setTeam1Name(String name) {
    emit(state.copyWith(team1Name: name));
    bleService.send(badmintonBleMapper.setTeam1Name(name));
  }

  void setTeam2Name(String name) {
    emit(state.copyWith(team2Name: name));
    bleService.send(badmintonBleMapper.setTeam2Name(name));
  }

  // Team colors
  void setTeam1Color(Color color) {
    emit(state.copyWith(team1Color: color));
    bleService.send(badmintonBleMapper.setTeam1Name(toRgb565(color).toRadixString(16).padLeft(4, '0')
        .toUpperCase()));
  }

  void setTeam2Color(Color color) {
    emit(state.copyWith(team2Color: color));
    bleService.send(badmintonBleMapper.setTeam2Color(toRgb565(color).toRadixString(16).padLeft(4, '0')
        .toUpperCase()));
  }


  void toggleServe() {
    emit(
      state.copyWith(
        serveTeam: state.serveTeam == ServeTeam.team1
            ? ServeTeam.team2
            : ServeTeam.team1,
      ),
    );
  }
  // ---------------- HELPERS ----------------

  int _t1(int set) =>
      set == 1 ? state.t1s1 : set == 2 ? state.t1s2 : state.t1s3;

  int _t2(int set) =>
      set == 1 ? state.t2s1 : set == 2 ? state.t2s2 : state.t2s3;

  void _emitT1(int set, int val) {
    emit(
      set == 1
          ? state.copyWith(t1s1: val)
          : set == 2
          ? state.copyWith(t1s2: val)
          : state.copyWith(t1s3: val),
    );
    bleService.send(
        badmintonBleMapper.setTeam1Score(set, val));
  }

  void _emitT2(int set, int val) {
    emit(
      set == 1
          ? state.copyWith(t2s1: val)
          : set == 2
          ? state.copyWith(t2s2: val)
          : state.copyWith(t2s3: val),
    );
    bleService.send(
        badmintonBleMapper.setTeam2Score(set, val));
  }

  int? _checkWinner(int a, int b) {
    if (a >= 21 || b >= 21) {
      if ((a - b).abs() >= 2) return a > b ? 1 : 2;
      if (a == 30) return 1;
      if (b == 30) return 2;
    }
    return null;
  }

  void _setWinner(int set, int winner) {
    emit(
      set == 1
          ? state.copyWith(set1Winner: winner)
          : set == 2
          ? state.copyWith(set2Winner: winner)
          : state.copyWith(set3Winner: winner),
    );
    bleService.send(
        badmintonBleMapper.setSetWinner(set, winner));
  }

  void _clearWinner(int set) => _setWinner(set, 0);

  void _autoNextSet(int set) {
    if (set >= 3) return;
    selectSet(set + 1);
  }

  void _handleError(String fn, Object e, StackTrace s) {
    globalErrorCubit.showError("$fn failed");
  }

  // ---------------- SET SELECT ----------------

  void selectSet(int set) {
    try {
      emit(state.copyWith(selectedSet: set));
      bleService.send(set == 1
          ? badmintonBleMapper.selectSet1()
          : set == 2
          ? badmintonBleMapper.selectSet2()
          : badmintonBleMapper.selectSet3());
    } catch (e, s) {
      _handleError("selectSet", e, s);
    }
  }

  // ---------------- SCORE INC ----------------

  void incrementTeam1() {
    try {
      final s = state.selectedSet;
      final v = _t1(s) + 1;
      _emitT1(s, v);

      final winner = _checkWinner(v, _t2(s));
      if (winner != null) {
        _setWinner(s, winner);
        _autoNextSet(s);
      }
    } catch (e, s) {
      _handleError("incrementTeam1", e, s);
    }
  }

  void incrementTeam2() {
    try {
      final s = state.selectedSet;
      final v = _t2(s) + 1;
      _emitT2(s, v);

      final winner = _checkWinner(_t1(s), v);
      if (winner != null) {
        _setWinner(s, winner);
        _autoNextSet(s);
      }
    } catch (e, s) {
      _handleError("incrementTeam2", e, s);
    }
  }

  // ---------------- SCORE DEC ----------------

  void decrementTeam1() {
    try {
      final s = state.selectedSet;
      if (_t1(s) <= 0) return;
      _emitT1(s, _t1(s) - 1);
      _clearWinner(s);
    } catch (e, s) {
      _handleError("decrementTeam1", e, s);
    }
  }

  void decrementTeam2() {
    try {
      final s = state.selectedSet;
      if (_t2(s) <= 0) return;
      _emitT2(s, _t2(s) - 1);
      _clearWinner(s);
    } catch (e, s) {
      _handleError("decrementTeam2", e, s);
    }
  }

  // Brightness (0 - 255)
  void setBrightness(int value) {
    emit(state.copyWith(brightness: value.clamp(0, 255)));
    bleService.send(badmintonBleMapper.setBrightness(value));
  }

  void setTempBrightness(int value) {
    emit(state.copyWith(tempBrightness: value.clamp(0, 255)));
  }

  // Buzzer toggle
  void toggleBuzzer() {
    emit(state.copyWith(buzzerOn: !state.buzzerOn));
    bleService.send(state.buzzerOn ? "BBBUZZERON" : "BBBUZZEROFF");
  }

}
