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
    required String name,
    String? phone,
    String? aadhar,
    String? dob,
    String? sex,
    String? dominantHand,
    double? heightInFeet,
    double? heightInInches,
    double? weightInKg,
    double? weightInLbs,
    int? sportId,
    String? deviceModel,
    String? deviceSerial,
  }) async {
    emit(state.copyWith(status: AthleteProfileStatus.updating));
    final result = await _updateProfile(
      name: name,
      phone: phone,
      aadhar: aadhar,
      dob: dob,
      sex: sex,
      dominantHand: dominantHand,
      heightInFeet: heightInFeet,
      heightInInches: heightInInches,
      weightInKg: weightInKg,
      weightInLbs: weightInLbs,
      sportId: sportId,
      deviceModel: deviceModel,
      deviceSerial: deviceSerial,
    ).run();
    result.fold(
      (failure) => emit(state.copyWith(
        status: AthleteProfileStatus.error,
        errorMessage: failure.message,
      )),
      (_) async {
        emit(state.copyWith(status: AthleteProfileStatus.updated));
        await fetchProfile();
      },
    );
  }
}
