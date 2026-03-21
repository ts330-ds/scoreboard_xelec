import 'package:equatable/equatable.dart';
import 'package:xelex_esp/feature/timing_gates/profile/data/model/timing_gate_profile_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

/// App start pe — box se load ho raha hai
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile set nahi hai — setup form dikhao
class ProfileNotSet extends ProfileState {
  const ProfileNotSet();
}

/// Profile loaded — card dikhao
class ProfileLoaded extends ProfileState {
  final TimingGateProfileModel profile;
  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile.name, profile.role];
}

/// Save ho raha hai
class ProfileSaving extends ProfileState {
  const ProfileSaving();
}
