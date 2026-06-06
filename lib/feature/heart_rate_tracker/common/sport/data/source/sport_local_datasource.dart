import 'dart:convert';
import 'package:hive/hive.dart';
import '../model/sport_model.dart';

abstract interface class SportLocalDataSource {
  Future<List<SportModel>?> getSports();
  Future<void> saveSports(List<SportModel> sports);
  Future<bool> isCacheValid();
}

class SportLocalDataSourceImpl implements SportLocalDataSource {
  final Box _box;

  static const _cacheValidHours = 4;
  static const _keyData = 'sports_data';
  static const _keyTimestamp = 'sports_timestamp';

  const SportLocalDataSourceImpl(this._box);

  @override
  Future<List<SportModel>?> getSports() async {
    final jsonString = _box.get(_keyData) as String?;
    if (jsonString == null) return null;
    final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
    return data
        .map((e) => SportModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveSports(List<SportModel> sports) async {
    final jsonString = jsonEncode(sports.map((e) => e.toJson()).toList());
    await _box.put(_keyData, jsonString);
    await _box.put(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<bool> isCacheValid() async {
    final timestamp = _box.get(_keyTimestamp) as int?;
    if (timestamp == null) return false;
    final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = DateTime.now().difference(savedTime);
    return difference.inHours < _cacheValidHours;
  }
}
