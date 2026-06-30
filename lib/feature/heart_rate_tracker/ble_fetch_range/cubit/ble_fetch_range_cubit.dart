import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/ble_fetch_range/cubit/ble_fetch_range_state.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_cubit.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/heart_rate_bluetooth/cubit/heart_ble_state.dart';

class BleFetchRangeCubit extends Cubit<BleFetchRangeState> {
  final HeartBleCubit _bleCubit;

  StreamSubscription<HeartBleState>? _bleSub;

  // Idle timer: device se jab tak naya data aata rahe, ye reset hota rahega.
  // Sirf tab fire hoga jab device 60s tak kuch na bheje (stall/disconnect).
  Timer? _idleTimer;

  // Absolute safety cap: last-resort backstop taaki fetch kabhi anant tak na
  // atke. Ye PRIMARY completion mechanism NAHI hai — wo kaam idle timer karta
  // hai (60s tak naya data na aaye to finalize). Pehle ye 10 min tha jo bade
  // (e.g. 24-ghante) session ka transfer beech me hi kaat deta tha — chahe data
  // abhi aa raha ho. Ab itna lamba hai ki real transfer kabhi na kate; sirf tab
  // fire hoga jab data lagataar 2 ghante tak aata rahe (practically asambhav).
  Timer? _maxTimer;

  static const _idleTimeout = Duration(seconds: 60);
  static const _maxTimeout = Duration(hours: 2);

  DateTime? _fromDate;
  DateTime? _toDate;

  BleFetchRangeCubit({required HeartBleCubit bleCubit})
      : _bleCubit = bleCubit,
        super(const BleFetchRangeState());

  Future<void> fetchRange({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!_bleCubit.state.isConnected) {
      emit(state.copyWith(
        status: FetchRangeStatus.error,
        message: 'Device not connected',
      ));
      return;
    }

    _fromDate = from.isBefore(to) ? from : to;
    _toDate = from.isBefore(to) ? to : from;

    _cancelAll();
    emit(const BleFetchRangeState(status: FetchRangeStatus.syncing));

    int lastHrLen = 0;
    int lastRrLen = 0;

    _bleSub = _bleCubit.stream.listen((bleState) {
      if (state.status != FetchRangeStatus.syncing) return;

      final hrNow = bleState.historyHrData.length;
      final rrNow = bleState.historyRrData.length;

      if (hrNow != lastHrLen || rrNow != lastRrLen) {
        lastHrLen = hrNow;
        lastRrLen = rrNow;
        // Naya data aaya — idle timer reset karo taaki transfer chalte rehne
        // tak fetch timeout na ho.
        _resetIdleTimer();
        emit(state.copyWith(
          hrCount: hrNow,
          rrCount: rrNow,
          message: 'Receiving... HR: $hrNow, RR: $rrNow',
        ));
      }

      // Only finalize on SYNC_COMPLETE (all streams done), not HR_DATA_DONE
      if (bleState.status == 'Sync complete') {
        debugPrint('[FETCH-RANGE] Sync complete received');
        _finalize();
      }

      // Detect sync failure — status contains error keywords
      final st = bleState.status.toLowerCase();
      if (st.contains('not connected') ||
          st.contains('sync failed') ||
          st.contains('disconnected')) {
        debugPrint('[FETCH-RANGE] Error detected: ${bleState.status}');
        _cancelAll();
        emit(state.copyWith(
          status: FetchRangeStatus.error,
          message: bleState.status,
        ));
      }
    });

    debugPrint('[FETCH-RANGE] from=$from to=$to');

    // Idle timer abhi se arm kar do — agar device pehla record hi 60s tak na
    // bheje (e.g. connect to hua par sync start na hua) tab bhi clean fail ho.
    _resetIdleTimer();

    // Absolute safety cap — last-resort anti-hang backstop (2h). Normal case me
    // idle timer (60s no-data) pehle hi finalize kar deta hai; ye yahan tak
    // pahunchta hi nahi jab tak data 2 ghante lagataar na aaye.
    _maxTimer = Timer(_maxTimeout, () {
      if (state.status == FetchRangeStatus.syncing) {
        debugPrint('[FETCH-RANGE] absolute max timeout hit (${_maxTimeout.inMinutes}min) '
            '— transfer abhi bhi chal raha tha, force finalize');
        _finalize(timedOut: true);
      }
    });

    await _bleCubit.syncHistoryRange(from: from, to: to);
  }

  /// Idle timer ko cancel karke dobara start karta hai. Jab tak device naya
  /// data bhejta rahega, ye baar-baar reset hota rahega aur fire nahi karega.
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, () {
      if (state.status == FetchRangeStatus.syncing) {
        debugPrint('[FETCH-RANGE] idle timeout — ${_idleTimeout.inSeconds}s '
            'tak koi naya data nahi aaya, finalize kar rahe hain');
        _finalize(timedOut: true);
      }
    });
  }

  void _finalize({bool timedOut = false}) {
    if (state.status != FetchRangeStatus.syncing) return;

    _bleSub?.cancel();
    _idleTimer?.cancel();
    _maxTimer?.cancel();

    final from = _fromDate;
    final to = _toDate;
    if (from == null || to == null) {
      debugPrint('[FETCH-RANGE] _finalize aborted — dates are null');
      emit(state.copyWith(
        status: FetchRangeStatus.error,
        message: 'Internal error: date range was cleared',
      ));
      return;
    }

    final hrAll = _bleCubit.state.historyHrData;
    final rrAll = _bleCubit.state.historyRrData;

    // BLE device clock can drift vs phone — allow 30s buffer on each side
    const driftMs = 30 * 1000;
    final fromMs = from.millisecondsSinceEpoch - driftMs;
    final toMs = to.millisecondsSinceEpoch + driftMs;

    final hrFiltered = hrAll.where((m) {
      final stamp = (m['stamp'] as num?)?.toInt() ?? 0;
      final stampMs = stamp > 9999999999 ? stamp : stamp * 1000;
      return stampMs >= fromMs && stampMs <= toMs;
    }).toList();

    final rrFiltered = rrAll.where((m) {
      final stamp = (m['stamp'] as num?)?.toInt() ?? 0;
      final stampMs = stamp > 9999999999 ? stamp : stamp * 1000;
      return stampMs >= fromMs && stampMs <= toMs;
    }).toList();

    debugPrint(
        '[FETCH-RANGE] done — HR: ${hrFiltered.length}, RR: ${rrFiltered.length}, timeout: $timedOut');

    emit(BleFetchRangeState(
      status: FetchRangeStatus.complete,
      hrData: hrFiltered,
      rrData: rrFiltered,
      hrCount: hrFiltered.length,
      rrCount: rrFiltered.length,
      message: timedOut
          ? 'Timeout! HR: ${hrFiltered.length}, RR: ${rrFiltered.length}'
          : 'Done! HR: ${hrFiltered.length}, RR: ${rrFiltered.length}',
    ));
  }

  void reset() {
    _cancelAll();
    emit(const BleFetchRangeState());
  }

  void _cancelAll() {
    _bleSub?.cancel();
    _idleTimer?.cancel();
    _maxTimer?.cancel();
  }

  @override
  Future<void> close() {
    _cancelAll();
    return super.close();
  }
}
