// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionModelAdapter extends TypeAdapter<SessionModel> {
  @override
  final int typeId = 2;

  @override
  SessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionModel(
      id: fields[0] as String,
      testName: fields[1] as String,
      protocol: fields[2] as String,
      distanceMeters: fields[3] as double,
      location: fields[4] as String,
      date: fields[5] as DateTime,
      layoutDiagram: fields[6] as String,
      triggerMode: fields[7] as String,
      falseStartThresholdMs: fields[8] as int,
      resetDelaySeconds: fields[9] as int,
      athletes: (fields[10] as List).cast<AthleteModel>(),
      results: (fields[11] as List).cast<TrialResultModel>(),
      createdAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SessionModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.testName)
      ..writeByte(2)
      ..write(obj.protocol)
      ..writeByte(3)
      ..write(obj.distanceMeters)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.layoutDiagram)
      ..writeByte(7)
      ..write(obj.triggerMode)
      ..writeByte(8)
      ..write(obj.falseStartThresholdMs)
      ..writeByte(9)
      ..write(obj.resetDelaySeconds)
      ..writeByte(10)
      ..write(obj.athletes)
      ..writeByte(11)
      ..write(obj.results)
      ..writeByte(12)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
