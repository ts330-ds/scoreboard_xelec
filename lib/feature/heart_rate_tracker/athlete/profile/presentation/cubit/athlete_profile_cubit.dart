import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecase/get_athlete_profile_usecase.dart';
import '../../domain/usecase/update_athlete_profile_usecase.dart';
import 'athlete_profile_state.dart';

class AthleteProfileCubit extends Cubit<AthleteProfileState> {
  final GetAthleteProfileUseCase _getProfile;
  final UpdateAthleteProfileUseCase _updateProfile;

  AthleteProfileCubit({
    required GetAthleteProfileUseCase getProfile,
    required UpdateAthleteProfileUseCase updateProfile,
  })  : _getProfile = getProfile,
        _updateProfile = updateProfile,
        super(const AthleteProfileState());

  Future<void> fetchProfile() async {
    emit(state.copyWith(status: AthleteProfileStatus.loading));
    final result = await _getProfile().run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: AthleteProfileStatus.error,
        errorMessage: failure.message,
      )),
      (profile) => emit(state.copyWith(
        status: AthleteProfileStatus.loaded,
        profile: profile,
      )),
    );
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    int? age,
    String? gender,
    int? sportId,
  }) async {
    emit(state.copyWith(status: AthleteProfileStatus.updating));
    final result = await _updateProfile(
      name: name,
      phone: phone,
      age: age,
      gender: gender,
      sportId: sportId,
    ).run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: AthleteProfileStatus.error,
        errorMessage: failure.message,
      )),
      (profile) => emit(state.copyWith(
        status: AthleteProfileStatus.updated,
        profile: profile,
      )),
    );
  }
}
