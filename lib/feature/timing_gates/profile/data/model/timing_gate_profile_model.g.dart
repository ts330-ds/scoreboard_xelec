// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timing_gate_profile_model.dart';

// ── ProfileRole Adapter ───────────────────────────────────────────────────────
class ProfileRoleAdapter extends TypeAdapter<ProfileRole> {
  @override
  final int typeId = 5;

  @override
  ProfileRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:  return ProfileRole.coach;
      case 1:  return ProfileRole.athlete;
      default: return ProfileRole.coach;
    }
  }

  @override
  void write(BinaryWriter writer, ProfileRole obj) {
    switch (obj) {
      case ProfileRole.coach:   writer.writeByte(0); break;
      case ProfileRole.athlete: writer.writeByte(1); break;
    }
  }
}

// ── TimingGateProfileModel Adapter ───────────────────────────────────────────
class TimingGateProfileModelAdapter extends TypeAdapter<TimingGateProfileModel> {
  @override
  final int typeId = 4;

  @override
  TimingGateProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimingGateProfileModel(
      name:         fields[0] as String,
      role:         fields[1] as ProfileRole,
      organization: fields[2] as String?,
      sport:        fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TimingGateProfileModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)..write(obj.name)
      ..writeByte(1)..write(obj.role)
      ..writeByte(2)..write(obj.organization)
      ..writeByte(3)..write(obj.sport);
  }
}
