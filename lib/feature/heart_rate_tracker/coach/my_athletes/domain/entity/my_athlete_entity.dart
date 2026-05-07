class MyAthleteEntity {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String? dob;
  final String? gender;
  final String? dominantHand;
  final double? heightInFeet;
  final double? heightInInches;
  final double? weightInKg;
  final double? weightInLbs;
  final int? sportId;
  final String? sportName;
  final String? aadhar;
  final String? deviceModel;
  final String? deviceSerial;
  final String? status;
  final String? createdAt;

  const MyAthleteEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.dob,
    this.gender,
    this.dominantHand,
    this.heightInFeet,
    this.heightInInches,
    this.weightInKg,
    this.weightInLbs,
    this.sportId,
    this.sportName,
    this.aadhar,
    this.deviceModel,
    this.deviceSerial,
    this.status,
    this.createdAt,
  });
}
