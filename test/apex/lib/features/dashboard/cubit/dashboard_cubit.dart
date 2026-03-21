import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/session_model.dart';
import '../../../data/repositories/session_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final SessionRepository _repository;

  DashboardCubit(this._repository) : super(DashboardInitial());

  void loadDashboard() {
    final sessions = _repository.getRecentSessions(limit: 5);
    emit(DashboardLoaded(
      recentSessions: sessions,
      masterConnected: false, // will be updated by BleCubit
      slaveConnected: false,
    ));
  }

  void updateGateStatus({required bool master, required bool slave}) {
    if (state is DashboardLoaded) {
      final current = state as DashboardLoaded;
      emit(current.copyWith(masterConnected: master, slaveConnected: slave));
    }
  }

  void refresh() => loadDashboard();
}
