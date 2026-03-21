// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'athlete_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AthleteModelAdapter extends TypeAdapter<AthleteModel> {
  @override
  final int typeId = 0;

  @override
  AthleteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AthleteModel(
      id: fields[0] as String,
      fullName: fields[1] as String,
      athleteId: fields[2] as String,
      bib: fields[3] as String,
      dob: fields[4] as String,
      age: fields[5] as int?,
      sex: fields[6] as String,
      discipline: fields[7] as String,
      team: fields[8] as String,
      trials: fields[9] as int,
      completedTrials: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AthleteModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.athleteId)
      ..writeByte(3)
      ..write(obj.bib)
      ..writeByte(4)
      ..write(obj.dob)
      ..writeByte(5)
      ..write(obj.age)
      ..writeByte(6)
      ..write(obj.sex)
      ..writeByte(7)
      ..write(obj.discipline)
      ..writeByte(8)
      ..write(obj.team)
      ..writeByte(9)
      ..write(obj.trials)
      ..writeByte(10)
      ..write(obj.completedTrials);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AthleteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
