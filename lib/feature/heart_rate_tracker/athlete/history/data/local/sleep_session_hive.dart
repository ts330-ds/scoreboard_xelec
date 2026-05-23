import 'package:hive/hive.dart';

class SleepSessionHive {
  final int utc;
  final List<int> actions;

  const SleepSessionHive({required this.utc, required this.actions});

  Map<String, dynamic> toMap() => {'utc': utc, 'actions': actions};

  factory SleepSessionHive.fromMap(Map<dynamic, dynamic> m) {
    final raw = m['actions'];
    final actions = raw is List
        ? raw.whereType<num>().map((e) => e.toInt()).toList()
        : <int>[];
    return SleepSessionHive(
      utc: (m['utc'] as num?)?.toInt() ?? 0,
      actions: actions,
    );
  }
}

class SleepSessionHiveAdapter extends TypeAdapter<SleepSessionHive> {
  @override
  final int typeId = 12;

  @override
  SleepSessionHive read(BinaryReader reader) {
    final utc = reader.readInt();
    final len = reader.readInt();
    final actions = <int>[];
    for (var i = 0; i < len; i++) {
      actions.add(reader.readInt());
    }
    return SleepSessionHive(utc: utc, actions: actions);
  }

  @override
  void write(BinaryWriter writer, SleepSessionHive obj) {
    writer.writeInt(obj.utc);
    writer.writeInt(obj.actions.length);
    for (final a in obj.actions) {
      writer.writeInt(a);
    }
  }
}
