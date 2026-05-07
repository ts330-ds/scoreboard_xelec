import '../../domain/entity/athlete_search_entity.dart';

class AthleteSearchModel extends AthleteSearchEntity {
  const AthleteSearchModel({
    required super.id,
    required super.name,
    required super.email,
    super.sport,
    super.avatarUrl,
  });

  factory AthleteSearchModel.fromJson(Map<String, dynamic> json) {
    return AthleteSearchModel(
      id: _toInt(json['id'] ?? json['athlete_id']) ?? 0,
      name: json['name']?.toString() ?? json['athlete_name']?.toString() ?? '',
      email: json['email']?.toString() ?? json['athlete_email']?.toString() ?? '',
      sport: json['sport_name']?.toString() ?? json['sport']?.toString(),
      avatarUrl: json['profile_image']?.toString(),
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
