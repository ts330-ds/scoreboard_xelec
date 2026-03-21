// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TestSessionModelAdapter extends TypeAdapter<TestSessionModel> {
  @override
  final int typeId = 3;

  @override
  TestSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestSessionModel(
      id: fields[0] as String,
      sessionName: fields[1] as String,
      date: fields[2] as DateTime,
      mode: fields[3] as String,
      subMode: fields[4] as String,
      protocol: fields[5] as String,
      customDistance: fields[6] as double?,
      trialMode: fields[7] as String,
      trialsCount: fields[8] as int,
      status: fields[9] as String,
      currentQueueIndex: fields[10] as int,
      athletes: (fields[11] as List).cast<AthleteModel>(),
      results: (fields[12] as List).cast<AthleteResultModel>(),
      location: fields[13] as String,
      notes: fields[14] as String,
      completedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TestSessionModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionName)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.mode)
      ..writeByte(4)
      ..write(obj.subMode)
      ..writeByte(5)
      ..write(obj.protocol)
      ..writeByte(6)
      ..write(obj.customDistance)
      ..writeByte(7)
      ..write(obj.trialMode)
      ..writeByte(8)
      ..write(obj.trialsCount)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.currentQueueIndex)
      ..writeByte(11)
      ..write(obj.athletes)
      ..writeByte(12)
      ..write(obj.results)
      ..writeByte(13)
      ..write(obj.location)
      ..writeByte(14)
      ..write(obj.notes)
      ..writeByte(15)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
