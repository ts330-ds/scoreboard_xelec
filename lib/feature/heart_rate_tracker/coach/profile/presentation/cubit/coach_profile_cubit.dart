import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/core/failure.dart';
import '../../domain/usecase/get_coach_profile_usecase.dart';
import '../../domain/usecase/update_coach_profile_usecase.dart';
import 'coach_profile_state.dart';

class CoachProfileCubit extends Cubit<CoachProfileState> {
  final GetCoachProfileUseCase _getProfile;
  final UpdateCoachProfileUseCase _updateProfile;

  CoachProfileCubit({
    required GetCoachProfileUseCase getProfile,
    required UpdateCoachProfileUseCase updateProfile,
  })  : _getProfile = getProfile,
        _updateProfile = updateProfile,
        super(const CoachProfileState());

  Future<void> fetchProfile() async {
    emit(state.copyWith(status: CoachProfileStatus.loading));
    final result = await _getProfile().run();
    result.fold(
      (failure) {
        if (failure is AuthFailure) {
          emit(state.copyWith(status: CoachProfileStatus.tokenExpired));
        } else {
          emit(state.copyWith(
            status: CoachProfileStatus.error,
            errorMessage: failure.message,
          ));
        }
      },
      (profile) => emit(state.copyWith(
        status: CoachProfileStatus.loaded,
        profile: profile,
      )),
    );
  }

  Future<void> updateProfile({
    required String name,
    required String organization,
    required int sport,
    String? phone,
    String? aadhar,
    String? dob,
    String? sex,
    String? dominantHand,
    double? heightInFeet,
    double? heightInInches,
    double? weightInKg,
    double? weightInLbs,
  }) async {
    emit(state.copyWith(status: CoachProfileStatus.updating));
    final result = await _updateProfile(
      name: name,
      organization: organization,
      sport: sport,
      phone: phone,
      aadhar: aadhar,
      dob: dob,
      sex: sex,
      dominantHand: dominantHand,
      heightInFeet: heightInFeet,
      heightInInches: heightInInches,
      weightInKg: weightInKg,
      weightInLbs: weightInLbs,
    ).run();
    result.fold(
      (failure) {
        if (failure is AuthFailure) {
          emit(state.copyWith(status: CoachProfileStatus.tokenExpired));
        } else {
          emit(state.copyWith(
            status: CoachProfileStatus.error,
            errorMessage: failure.message,
          ));
        }
      },
      (_) async {
        emit(state.copyWith(status: CoachProfileStatus.updated));
        await fetchProfile();
      },
    );
  }
}
