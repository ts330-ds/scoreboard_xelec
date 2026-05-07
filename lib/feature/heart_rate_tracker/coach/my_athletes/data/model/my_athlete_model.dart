import '../../domain/entity/my_athlete_entity.dart';

class MyAthleteModel extends MyAthleteEntity {
  const MyAthleteModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.profileImage,
    super.dob,
    super.gender,
    super.dominantHand,
    super.heightInFeet,
    super.heightInInches,
    super.weightInKg,
    super.weightInLbs,
    super.sportId,
    super.sportName,
    super.aadhar,
    super.deviceModel,
    super.deviceSerial,
    super.status,
    super.createdAt,
  });

  // Used by GET /coach/my_athletes list response
  // Fields: athlete_id, athlete_name, athlete_email
  factory MyAthleteModel.fromJson(Map<String, dynamic> json) {
    return MyAthleteModel(
      id: _toInt(json['athlete_id']) ?? 0,
      name: json['athlete_name']?.toString() ?? '',
      email: json['athlete_email']?.toString() ?? '',
      phone: json['phone_no']?.toString(),
      profileImage: json['profile_image']?.toString(),
      dob: _parseDate(json['dob']?.toString()),
      gender: _capitalize(json['sex']?.toString()),
      dominantHand: _capitalize(json['dominant_hand']?.toString()),
      heightInFeet: _toDouble(json['height_in_feet']),
      heightInInches: _toDouble(json['height_in_inches']),
      weightInKg: _toDouble(json['weight_in_kg']),
      weightInLbs: _toDouble(json['weight_in_lbs']),
      sportId: _toInt(json['sport_id']),
      sportName: _capitalize(json['sport_name']?.toString()),
      aadhar: json['aadhar']?.toString(),
      deviceModel: json['device_model']?.toString(),
      deviceSerial: json['device_serial']?.toString(),
    );
  }

  // Used by GET /coach/get_athlete/:id detail response
  // Fields: id, name, email, sport (not sport_id), heights as strings
  factory MyAthleteModel.fromDetailJson(Map<String, dynamic> json) {
    return MyAthleteModel(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone_no']?.toString(),
      profileImage: json['profile_image']?.toString(),
      dob: _parseDate(json['dob']?.toString()),
      gender: _capitalize(json['sex']?.toString()),
      dominantHand: _capitalize(json['dominant_hand']?.toString()),
      heightInFeet: _toDouble(json['height_in_feet']),    // comes as "5.00" string
      heightInInches: _toDouble(json['height_in_inches']), // comes as "9.00" string
      weightInKg: _toDouble(json['weight_in_kg']),         // comes as "78.00" string
      weightInLbs: _toDouble(json['weight_in_lbs']),       // comes as "172.00" string
      sportId: _toInt(json['sport']),                      // key is "sport" not "sport_id"
      aadhar: json['aadhar']?.toString(),
      deviceModel: json['device_model']?.toString(),
      deviceSerial: json['device_serial']?.toString(),
      status: json['status']?.toString(),
      createdAt: _parseDate(json['created_at']?.toString()),
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

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
