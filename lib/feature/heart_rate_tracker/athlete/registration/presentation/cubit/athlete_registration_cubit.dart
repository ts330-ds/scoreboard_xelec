import 'package:flutter_bloc/flutter_bloc.dart';
import 'athlete_registration_state.dart';

class AthleteRegistrationCubit extends Cubit<AthleteRegistrationState> {
  AthleteRegistrationCubit() : super(const AthleteRegistrationState());

  void updateFullName(String v)       => emit(state.copyWith(fullName: v));
  void updateAthleteId(String v)      => emit(state.copyWith(athleteId: v));
  void updateEmail(String v)          => emit(state.copyWith(email: v));
  void updateMobile(String v)         => emit(state.copyWith(mobile: v));
  void updateAadhar(String v)         => emit(state.copyWith(aadhar: v));
  void updateDob(DateTime v)          => emit(state.copyWith(dob: v));
  void updateSex(String v)            => emit(state.copyWith(sex: v));
  void updateDominantHand(String? v)  => emit(state.copyWith(dominantHand: v));
  void updateSportType(String? v)     => emit(state.copyWith(sportType: v));
  void updateDeviceModel(String v)    => emit(state.copyWith(deviceModel: v));
  void updateDeviceSerial(String v)   => emit(state.copyWith(deviceSerial: v));
  void updateHeight(String v)         => emit(state.copyWith(height: v));
  void updateWeight(String v)         => emit(state.copyWith(weight: v));
  void updateHeightFeet(String v)     => emit(state.copyWith(heightFeet: v));
  void updateHeightInches(String v)   => emit(state.copyWith(heightInches: v));

  void updateUnit(String v) {
    emit(state.copyWith(
      unit: v,
      height: '',
      heightFeet: '',
      heightInches: '',
      weight: '',
    ));
  }

  void submit() => emit(state.copyWith(isSubmitted: true));
}
