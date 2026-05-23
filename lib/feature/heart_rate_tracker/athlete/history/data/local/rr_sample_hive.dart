import 'package:hive/hive.dart';

class RrSampleHive {
  final int stamp;
  final int value;

  const RrSampleHive({required this.stamp, required this.value});

  Map<String, dynamic> toMap() => {'stamp': stamp, 'value': value};

  factory RrSampleHive.fromMap(Map<dynamic, dynamic> m) => RrSampleHive(
        stamp: (m['stamp'] as num?)?.toInt() ?? 0,
        value: (m['value'] as num?)?.toInt() ?? 0,
      );
}

class RrSampleHiveAdapter extends TypeAdapter<RrSampleHive> {
  @override
  final int typeId = 11;

  @override
  RrSampleHive read(BinaryReader reader) {
    return RrSampleHive(
      stamp: reader.readInt(),
      value: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, RrSampleHive obj) {
    writer.writeInt(obj.stamp);
    writer.writeInt(obj.value);
  }
}
