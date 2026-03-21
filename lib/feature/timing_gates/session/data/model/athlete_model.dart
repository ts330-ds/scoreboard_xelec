import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'athlete_model.g.dart';

@HiveType(typeId: 0)
class AthleteModel extends Equatable {
  @HiveField(0)
  final String id; // internal UUID — Hive box key

  @HiveField(1)
  final String fullName;

  @HiveField(2)
  final String athleteId; // optional external/official athlete ID

  @HiveField(3)
  final String bib; // optional bib number

  @HiveField(4)
  final String dob; // DD/MM/YYYY or similar

  @HiveField(5)
  final int? age; // optional; can be computed from DOB or entered manually

  @HiveField(6)
  final String sex; // 'Male' | 'Female' | 'Other' | ''

  @HiveField(7)
  final String discipline; // e.g. 'Sprint', '100m', 'Long Jump'

  @HiveField(8)
  final String team; // team / group name

  @HiveField(9)
  final int trials; // number of trials planned

  @HiveField(10)
  final int completedTrials; // number of trials actually performed during testing

  const AthleteModel({
    required this.id,
    required this.fullName,
    this.athleteId = '',
    this.bib = '',
    this.dob = '',
    this.age,
    this.sex = '',
    this.discipline = '',
    this.team = '',
    this.trials = 3,
    this.completedTrials = 0,
  });

  AthleteModel copyWith({
    String? id,
    String? fullName,
    String? athleteId,
    String? bib,
    String? dob,
    int? age,
    bool clearAge = false,
    String? sex,
    String? discipline,
    String? team,
    int? trials,
    int? completedTrials,
  }) {
    return AthleteModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      athleteId: athleteId ?? this.athleteId,
      bib: bib ?? this.bib,
      dob: dob ?? this.dob,
      age: clearAge ? null : (age ?? this.age),
      sex: sex ?? this.sex,
      discipline: discipline ?? this.discipline,
      team: team ?? this.team,
      trials: trials ?? this.trials,
      completedTrials: completedTrials ?? this.completedTrials,
    );
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        athleteId,
        bib,
        dob,
        age,
        sex,
        discipline,
        team,
        trials,
        completedTrials,
      ];
}
