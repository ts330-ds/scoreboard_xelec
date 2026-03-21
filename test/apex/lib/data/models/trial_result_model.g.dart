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
      athleteId: fields[0] as String,
      athleteName: fields[1] as String,
      trialNumber: fields[2] as int,
      timeSeconds: fields[3] as double,
      isManualStop: fields[4] as bool,
      recordedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TrialResultModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.athleteId)
      ..writeByte(1)
      ..write(obj.athleteName)
      ..writeByte(2)
      ..write(obj.trialNumber)
      ..writeByte(3)
      ..write(obj.timeSeconds)
      ..writeByte(4)
      ..write(obj.isManualStop)
      ..writeByte(5)
      ..write(obj.recordedAt);
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
