import 'package:hive/hive.dart';

part 'timing_gate_profile_model.g.dart';

// ── Profile Role ──────────────────────────────────────────────────────────────
@HiveType(typeId: 5)
enum ProfileRole {
  @HiveField(0)
  coach,
  @HiveField(1)
  athlete,
}

// ── Profile Model ─────────────────────────────────────────────────────────────
@HiveType(typeId: 4)
class TimingGateProfileModel {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final ProfileRole role;

  /// Coach ke liye: club/school/organization name
  @HiveField(2)
  final String? organization;

  /// Athlete ke liye: sport/discipline
  @HiveField(3)
  final String? sport;

  /// Height value (stored in the unit the user chose)
  @HiveField(4)
  final double? height;

  /// 'cm' | 'in'
  @HiveField(7)
  final String heightUnit;

  /// Weight value (stored in the unit the user chose)
  @HiveField(5)
  final double? weight;

  /// 'kg' | 'lb'
  @HiveField(8)
  final String weightUnit;

  /// Date of birth
  @HiveField(6)
  final DateTime? dateOfBirth;

  const TimingGateProfileModel({
    required this.name,
    required this.role,
    this.organization,
    this.sport,
    this.height,
    this.heightUnit = 'cm',
    this.weight,
    this.weightUnit = 'kg',
    this.dateOfBirth,
  });

  bool get isCoach   => role == ProfileRole.coach;
  bool get isAthlete => role == ProfileRole.athlete;

  String get roleLabel => isCoach ? 'Coach' : 'Athlete';

  /// Session mein save hone wala short string
  /// e.g. "Rahul Sharma (Coach)"
  String get conductorTag => '$name ($roleLabel)';

  /// Age calculated from dateOfBirth
  int? get age {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Height displayed with its unit, e.g. "175.0 cm" or "5'9\""
  String get heightDisplay {
    if (height == null) return '';
    if (heightUnit == 'in') {
      final totalIn = height!;
      final ft = totalIn ~/ 12;
      final inches = (totalIn % 12).toStringAsFixed(1);
      return "$ft'$inches\"";
    }
    return '${height!.toStringAsFixed(1)} cm';
  }

  /// Weight displayed with its unit, e.g. "70.0 kg" or "154.3 lb"
  String get weightDisplay {
    if (weight == null) return '';
    return '${weight!.toStringAsFixed(1)} $weightUnit';
  }

  TimingGateProfileModel copyWith({
    String? name,
    ProfileRole? role,
    String? organization,
    String? sport,
    double? height,
    String? heightUnit,
    double? weight,
    String? weightUnit,
    DateTime? dateOfBirth,
  }) {
    return TimingGateProfileModel(
      name:         name         ?? this.name,
      role:         role         ?? this.role,
      organization: organization ?? this.organization,
      sport:        sport        ?? this.sport,
      height:       height       ?? this.height,
      heightUnit:   heightUnit   ?? this.heightUnit,
      weight:       weight       ?? this.weight,
      weightUnit:   weightUnit   ?? this.weightUnit,
      dateOfBirth:  dateOfBirth  ?? this.dateOfBirth,
    );
  }
}
