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
    );
  }

  @override
  void write(BinaryWriter writer, TrialResultModel obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.timestamp);
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
