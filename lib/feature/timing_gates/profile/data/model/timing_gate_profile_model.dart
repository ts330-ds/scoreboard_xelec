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

  const TimingGateProfileModel({
    required this.name,
    required this.role,
    this.organization,
    this.sport,
  });

  bool get isCoach   => role == ProfileRole.coach;
  bool get isAthlete => role == ProfileRole.athlete;

  String get roleLabel => isCoach ? 'Coach' : 'Athlete';

  /// Session mein save hone wala short string
  /// e.g. "Rahul Sharma (Coach)"
  String get conductorTag => '$name ($roleLabel)';

  TimingGateProfileModel copyWith({
    String? name,
    ProfileRole? role,
    String? organization,
    String? sport,
  }) {
    return TimingGateProfileModel(
      name:         name         ?? this.name,
      role:         role         ?? this.role,
      organization: organization ?? this.organization,
      sport:        sport        ?? this.sport,
    );
  }
}
