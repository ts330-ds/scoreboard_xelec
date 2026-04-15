// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trial_result_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrialResultModelAdapter extends TypeAdapter<TrialResultModel> {
  @override
  final int typeId = 1;

  @override
  TrialResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrialResultModel(
      trialNumber: fields[0] as int,
      totalTime: fields[1] as double?,
      splits: (fields[2] as List).cast<double>(),
      lane: fields[3] as int?,
      status: fields[4] as String,
      timestamp: fields[5] as DateTime?,
      speeds: fields[6] == null ? const [] : (fields[6] as List).cast<double>(),
      accelerations: fields[7] == null ? const [] : (fields[7] as List).cast<double>(),
      firstStrikeLevel: fields[8] as String?,
      secondStrikeLevel: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TrialResultModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.trialNumber)
      ..writeByte(1)
      ..write(obj.totalTime)
      ..writeByte(2)
      ..write(obj.splits)
      ..writeByte(3)
      ..write(obj.lane)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.speeds)
      ..writeByte(7)
      ..write(obj.accelerations)
      ..writeByte(8)
      ..write(obj.firstStrikeLevel)
      ..writeByte(9)
      ..write(obj.secondStrikeLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrialResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
