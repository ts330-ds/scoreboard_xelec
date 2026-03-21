part of 'dashboard_cubit.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<SessionModel> recentSessions;
  final bool masterConnected;
  final bool slaveConnected;

  const DashboardLoaded({
    required this.recentSessions,
    required this.masterConnected,
    required this.slaveConnected,
  });

  bool get anyGateConnected => masterConnected || slaveConnected;
  bool get allGatesConnected => masterConnected && slaveConnected;

  DashboardLoaded copyWith({
    List<SessionModel>? recentSessions,
    bool? masterConnected,
    bool? slaveConnected,
  }) {
    return DashboardLoaded(
      recentSessions: recentSessions ?? this.recentSessions,
      masterConnected: masterConnected ?? this.masterConnected,
      slaveConnected: slaveConnected ?? this.slaveConnected,
    );
  }

  @override
  List<Object?> get props => [recentSessions, masterConnected, slaveConnected];
}
