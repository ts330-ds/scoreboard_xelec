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
      name: fields[1] as String,
      team: fields[2] as String,
      dob: fields[3] as String,
      trials: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AthleteModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.team)
      ..writeByte(3)
      ..write(obj.dob)
      ..writeByte(4)
      ..write(obj.trials);
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
