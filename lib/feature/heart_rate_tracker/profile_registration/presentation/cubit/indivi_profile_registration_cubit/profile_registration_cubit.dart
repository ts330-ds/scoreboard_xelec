import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xelex_esp/feature/heart_rate_tracker/profile_registration/presentation/cubit/indivi_profile_registration_cubit/profile_registration_state.dart';



class IndiviProfileRegistrationCubit
    extends Cubit<IndiviProfileRegistrationState> {
  IndiviProfileRegistrationCubit()
      : super(const IndiviProfileRegistrationState());

  void updateFullName(String value) =>
      emit(state.copyWith(fullName: value));

  void updateAthleteId(String value) =>
      emit(state.copyWith(athleteId: value));

  void updateEmail(String value) =>
      emit(state.copyWith(email: value));

  void updateMobile(String value) =>
      emit(state.copyWith(mobile: value));

  void updateAadhar(String value) =>
      emit(state.copyWith(aadhar: value));

  void updateDob(DateTime value) =>
      emit(state.copyWith(dob: value));

  void updateSex(String value) =>
      emit(state.copyWith(sex: value));

  void updateDominantHand(String? value) =>
      emit(state.copyWith(dominantHand: value));

  void updateSportType(String? value) =>
      emit(state.copyWith(sportType: value));

  void updateDeviceModel(String value) =>
      emit(state.copyWith(deviceModel: value));

  void updateDeviceSerial(String value) =>
      emit(state.copyWith(deviceSerial: value));

  void updateHeight(String value) =>
      emit(state.copyWith(height: value));

  void updateWeight(String value) =>
      emit(state.copyWith(weight: value));

  void updateHeightFeet(String value) =>
      emit(state.copyWith(heightFeet: value));

  void updateHeightInches(String value) =>
      emit(state.copyWith(heightInches: value));

  void updateUnit(String value) {
    emit(state.copyWith(
      unit: value,
      height: '',
      heightFeet: '',
      heightInches: '',
      weight: '',
    ));
  }

  void submit() => emit(state.copyWith(isSubmitted: true));
}