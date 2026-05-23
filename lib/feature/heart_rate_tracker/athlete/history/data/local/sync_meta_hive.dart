import 'package:hive/hive.dart';

class SyncMetaHive {
  final int lastSyncMs;
  final int oldestStamp;
  final int newestStamp;
  final int count;

  const SyncMetaHive({
    required this.lastSyncMs,
    required this.oldestStamp,
    required this.newestStamp,
    required this.count,
  });

  factory SyncMetaHive.empty() => const SyncMetaHive(
        lastSyncMs: 0,
        oldestStamp: 0,
        newestStamp: 0,
        count: 0,
      );

  SyncMetaHive copyWith({
    int? lastSyncMs,
    int? oldestStamp,
    int? newestStamp,
    int? count,
  }) =>
      SyncMetaHive(
        lastSyncMs: lastSyncMs ?? this.lastSyncMs,
        oldestStamp: oldestStamp ?? this.oldestStamp,
        newestStamp: newestStamp ?? this.newestStamp,
        count: count ?? this.count,
      );
}

class SyncMetaHiveAdapter extends TypeAdapter<SyncMetaHive> {
  @override
  final int typeId = 13;

  @override
  SyncMetaHive read(BinaryReader reader) {
    return SyncMetaHive(
      lastSyncMs: reader.readInt(),
      oldestStamp: reader.readInt(),
      newestStamp: reader.readInt(),
      count: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, SyncMetaHive obj) {
    writer.writeInt(obj.lastSyncMs);
    writer.writeInt(obj.oldestStamp);
    writer.writeInt(obj.newestStamp);
    writer.writeInt(obj.count);
  }
}
