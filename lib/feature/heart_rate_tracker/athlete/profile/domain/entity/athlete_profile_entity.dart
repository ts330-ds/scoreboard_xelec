class AthleteProfileEntity {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final int? age;
  final String? gender;
  final int? sportId;
  final String? sportName;

  const AthleteProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.age,
    this.gender,
    this.sportId,
    this.sportName,
  });
}
