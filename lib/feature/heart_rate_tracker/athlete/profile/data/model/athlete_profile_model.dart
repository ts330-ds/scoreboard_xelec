import '../../domain/entity/athlete_profile_entity.dart';

class AthleteProfileModel extends AthleteProfileEntity {
  const AthleteProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.profileImage,
    super.aadhar,
    super.dob,
    super.gender,
    super.dominantHand,
    super.heightInFeet,
    super.heightInInches,
    super.weightInKg,
    super.weightInLbs,
    super.sportId,
    super.sportName,
    super.deviceModel,
    super.deviceSerial,
  });

  factory AthleteProfileModel.fromJson(Map<String, dynamic> json) {
    // API returns data as a List — take first element
    final rawData = json['data'];
    final Map<String, dynamic> data;
    if (rawData is List && rawData.isNotEmpty) {
      data = rawData.first as Map<String, dynamic>;
    } else if (rawData is Map<String, dynamic>) {
      data = rawData;
    } else {
      data = json;
    }

    return AthleteProfileModel(
      id: _toInt(data['id']) ?? 0,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone_no']?.toString(),
      profileImage: data['profile_image']?.toString(),
      aadhar: data['aadhar']?.toString(),
      dob: _parseDate(data['dob']?.toString()),
      gender: _capitalize(data['sex']?.toString()),
      dominantHand: _capitalize(data['dominant_hand']?.toString()),
      heightInFeet: _toDouble(data['height_in_feet']),
      heightInInches: _toDouble(data['height_in_inches']),
      weightInKg: _toDouble(data['weight_in_kg']),
      weightInLbs: _toDouble(data['weight_in_lbs']),
      sportId: _toInt(data['sport_id']),
      sportName: data['sport_name']?.toString(),
      deviceModel: data['device_model']?.toString(),
      deviceSerial: data['device_serial']?.toString(),
    );
  }

  // "2002-04-02T00:00:00.000Z" → "2002-04-02"
  static String? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw.contains('T') ? raw.split('T').first : raw;
  }

  // "female" → "Female", "right" → "Right"
  static String? _capitalize(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone_no': phone,
        'dob': dob,
        'sex': gender,
        'dominant_hand': dominantHand,
        'height_in_feet': heightInFeet,
        'height_in_inches': heightInInches,
        'weight_in_kg': weightInKg,
        'weight_in_lbs': weightInLbs,
        'sport_id': sportId,
      };
}
