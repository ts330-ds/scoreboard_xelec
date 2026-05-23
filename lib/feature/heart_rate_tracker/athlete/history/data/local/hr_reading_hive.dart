import 'package:hive/hive.dart';

class HrReadingHive {
  final int stamp;
  final int heartRate;

  const HrReadingHive({required this.stamp, required this.heartRate});

  Map<String, dynamic> toMap() => {'stamp': stamp, 'heartRate': heartRate};

  factory HrReadingHive.fromMap(Map<dynamic, dynamic> m) => HrReadingHive(
        stamp: (m['stamp'] as num?)?.toInt() ?? 0,
        heartRate: (m['heartRate'] as num?)?.toInt() ?? 0,
      );
}

class HrReadingHiveAdapter extends TypeAdapter<HrReadingHive> {
  @override
  final int typeId = 10;

  @override
  HrReadingHive read(BinaryReader reader) {
    return HrReadingHive(
      stamp: reader.readInt(),
      heartRate: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, HrReadingHive obj) {
    writer.writeInt(obj.stamp);
    writer.writeInt(obj.heartRate);
  }
}
