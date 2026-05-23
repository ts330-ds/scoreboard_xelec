class AthleteHourRawEntity {
  final Map<String, dynamic> raw;
  const AthleteHourRawEntity({required this.raw});

  String? get date => raw['date'] as String?;
  int? get hour => (raw['hour'] as num?)?.toInt();

  List<Map<String, dynamic>> get healthRaw {
    final list = raw['health_raw'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> get sleepRaw {
    final list = raw['sleep_raw'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
