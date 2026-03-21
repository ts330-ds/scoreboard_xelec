// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'athlete_result_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AthleteResultModelAdapter extends TypeAdapter<AthleteResultModel> {
  @override
  final int typeId = 2;

  @override
  AthleteResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AthleteResultModel(
      athleteId: fields[0] as String,
      fullName: fields[1] as String,
      bib: fields[2] as String,
      team: fields[3] as String,
      discipline: fields[4] as String,
      trials: (fields[5] as List).cast<TrialResultModel>(),
      shuttleLane: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, AthleteResultModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.athleteId)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.bib)
      ..writeByte(3)
      ..write(obj.team)
      ..writeByte(4)
      ..write(obj.discipline)
      ..writeByte(5)
      ..write(obj.trials)
      ..writeByte(6)
      ..write(obj.shuttleLane);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AthleteResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
