class CoachProfileEntity {
  final String name;
  final String email;
  final String? phone;
  final String? aadhar;
  final String? dob;
  final String? gender;
  final String? dominantHand;
  final double? heightInFeet;
  final double? heightInInches;
  final double? weightInKg;
  final double? weightInLbs;
  final String? sportName;
  final String? organization;

  const CoachProfileEntity({
    required this.name,
    required this.email,
    this.phone,
    this.aadhar,
    this.dob,
    this.gender,
    this.dominantHand,
    this.heightInFeet,
    this.heightInInches,
    this.weightInKg,
    this.weightInLbs,
    this.sportName,
    this.organization,
  });
}
