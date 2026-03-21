import 'package:hive/hive.dart';

part 'athlete_model.g.dart';

@HiveType(typeId: 0)
class AthleteModel extends HiveObject {
  @HiveField(0)
  String id; // "ATH-001"

  @HiveField(1)
  String name; // "Jordan Smith"

  @HiveField(2)
  String team; // "Sprint Group A"

  @HiveField(3)
  String dob; // "2000-03-15"

  @HiveField(4)
  int trials; // 3

  AthleteModel({
    required this.id,
    required this.name,
    required this.team,
    this.dob = '',
    this.trials = 3,
  });

  // Initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  AthleteModel copyWith({
    String? id,
    String? name,
    String? team,
    String? dob,
    int? trials,
  }) {
    return AthleteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      team: team ?? this.team,
      dob: dob ?? this.dob,
      trials: trials ?? this.trials,
    );
  }

  @override
  String toString() => 'AthleteModel(id: $id, name: $name, team: $team, trials: $trials)';
}
