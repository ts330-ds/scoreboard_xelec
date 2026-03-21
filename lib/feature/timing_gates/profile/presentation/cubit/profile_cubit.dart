import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/timing_gates/profile/data/model/timing_gate_profile_model.dart';
import 'package:xelex_esp/feature/timing_gates/profile/data/repository/profile_repository.dart';
import 'package:xelex_esp/feature/timing_gates/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repository;

  ProfileCubit({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileLoading());

  /// App start ya profile tab open hone pe call karo
  void loadProfile() {
    final profile = _repository.getProfile();
    if (profile == null) {
      emit(const ProfileNotSet());
    } else {
      emit(ProfileLoaded(profile));
    }
  }

  /// Setup form submit hone pe call karo
  Future<void> saveProfile(TimingGateProfileModel profile) async {
    emit(const ProfileSaving());
    await _repository.saveProfile(profile);
    emit(ProfileLoaded(profile));
  }

  /// "Change Profile" button — wapas setup form pe
  Future<void> deleteProfile() async {
    await _repository.deleteProfile();
    emit(const ProfileNotSet());
  }
}
