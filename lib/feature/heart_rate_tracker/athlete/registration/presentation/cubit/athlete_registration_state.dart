class AthleteRegistrationState {
  final String fullName;
  final String athleteId;
  final String email;
  final String mobile;
  final String aadhar;
  final DateTime? dob;
  final String sex;
  final String? dominantHand;
  final String unit;
  final String height;
  final String heightFeet;
  final String heightInches;
  final String weight;
  final String? sportType;
  final String deviceModel;
  final String deviceSerial;
  final bool isSubmitted;

  const AthleteRegistrationState({
    this.fullName = '',
    this.athleteId = '',
    this.email = '',
    this.mobile = '',
    this.aadhar = '',
    this.dob,
    this.sex = '',
    this.dominantHand,
    this.unit = 'Metric',
    this.height = '',
    this.heightFeet = '',
    this.heightInches = '',
    this.weight = '',
    this.sportType,
    this.deviceModel = '',
    this.deviceSerial = '',
    this.isSubmitted = false,
  });

  AthleteRegistrationState copyWith({
    String? fullName,
    String? athleteId,
    String? email,
    String? mobile,
    String? aadhar,
    DateTime? dob,
    String? sex,
    String? dominantHand,
    String? unit,
    String? height,
    String? heightFeet,
    String? heightInches,
    String? weight,
    String? sportType,
    String? deviceModel,
    String? deviceSerial,
    bool? isSubmitted,
  }) {
    return AthleteRegistrationState(
      fullName:       fullName       ?? this.fullName,
      athleteId:      athleteId      ?? this.athleteId,
      email:          email          ?? this.email,
      mobile:         mobile         ?? this.mobile,
      aadhar:         aadhar         ?? this.aadhar,
      dob:            dob            ?? this.dob,
      sex:            sex            ?? this.sex,
      dominantHand:   dominantHand   ?? this.dominantHand,
      unit:           unit           ?? this.unit,
      height:         height         ?? this.height,
      heightFeet:     heightFeet     ?? this.heightFeet,
      heightInches:   heightInches   ?? this.heightInches,
      weight:         weight         ?? this.weight,
      sportType:      sportType      ?? this.sportType,
      deviceModel:    deviceModel    ?? this.deviceModel,
      deviceSerial:   deviceSerial   ?? this.deviceSerial,
      isSubmitted:    isSubmitted    ?? this.isSubmitted,
    );
  }
}
