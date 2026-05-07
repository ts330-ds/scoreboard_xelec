import '../../domain/entity/coach_profile_entity.dart';

class CoachProfileModel extends CoachProfileEntity {
  const CoachProfileModel({
    required super.name,
    required super.email,
    super.phone,
    super.aadhar,
    super.dob,
    super.gender,
    super.dominantHand,
    super.heightInFeet,
    super.heightInInches,
    super.weightInKg,
    super.weightInLbs,
    super.sportName,
    super.organization,
  });

  factory CoachProfileModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final Map<String, dynamic> data;
    if (rawData is List && rawData.isNotEmpty) {
      data = rawData.first as Map<String, dynamic>;
    } else if (rawData is Map<String, dynamic>) {
      data = rawData;
    } else {
      data = json;
    }

    return CoachProfileModel(
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone_no']?.toString(),
      aadhar: data['aadhar']?.toString(),
      dob: _parseDate(data['dob']?.toString()),
      gender: _capitalize(data['sex']?.toString()),
      dominantHand: _capitalize(data['dominant_hand']?.toString()),
      heightInFeet: _toDouble(data['height_in_feet']),
      heightInInches: _toDouble(data['height_in_inches']),
      weightInKg: _toDouble(data['weight_in_kg']),
      weightInLbs: _toDouble(data['weight_in_lbs']),
      sportName: _capitalize(data['sport_name']?.toString()),
      organization: data['organization']?.toString(),
    );
  }

  static String? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw.contains('T') ? raw.split('T').first : raw;
  }

  static String? _capitalize(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

}
