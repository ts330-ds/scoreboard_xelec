import '../../domain/entity/athlete_profile_entity.dart';

class AthleteProfileModel extends AthleteProfileEntity {
  const AthleteProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.profileImage,
    super.age,
    super.gender,
    super.sportId,
    super.sportName,
  });

  factory AthleteProfileModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AthleteProfileModel(
      id: data['id'] as int,
      name: data['name'] as String,
      email: data['email'] as String,
      phone: data['phone'] as String?,
      profileImage: data['profile_image'] as String?,
      age: data['age'] as int?,
      gender: data['gender'] as String?,
      sportId: data['sport_id'] as int?,
      sportName: data['sport_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'age': age,
        'gender': gender,
        'sport_id': sportId,
      };
}
