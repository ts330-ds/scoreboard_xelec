class AthleteProfileEntity {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String? aadhar;
  final String? dob;
  final String? gender;
  final String? dominantHand;
  final double? heightInFeet;
  final double? heightInInches;
  final double? weightInKg;
  final double? weightInLbs;
  final int? sportId;
  final String? sportName;
  final String? deviceModel;
  final String? deviceSerial;

  const AthleteProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.aadhar,
    this.dob,
    this.gender,
    this.dominantHand,
    this.heightInFeet,
    this.heightInInches,
    this.weightInKg,
    this.weightInLbs,
    this.sportId,
    this.sportName,
    this.deviceModel,
    this.deviceSerial,
  });
}
