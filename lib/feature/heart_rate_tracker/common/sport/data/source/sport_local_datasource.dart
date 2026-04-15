import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelex_esp/core/pref_keys.dart';
import '../model/sport_model.dart';

abstract interface class SportLocalDataSource {
  Future<List<SportModel>?> getSports();
  Future<void> saveSports(List<SportModel> sports);
  Future<bool> isCacheValid();
}

class SportLocalDataSourceImpl implements SportLocalDataSource {
  final SharedPreferences _prefs;

  static const _cacheValidHours = 24;

  const SportLocalDataSourceImpl(this._prefs);

  @override
  Future<List<SportModel>?> getSports() async {
    final jsonString = _prefs.getString(PrefKeys.sportsData);
    if (jsonString == null) return null;
    final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
    return data
        .map((e) => SportModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveSports(List<SportModel> sports) async {
    final jsonString = jsonEncode(sports.map((e) => e.toJson()).toList());
    await _prefs.setString(PrefKeys.sportsData, jsonString);
    await _prefs.setInt(PrefKeys.sportsTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<bool> isCacheValid() async {
    final timestamp = _prefs.getInt(PrefKeys.sportsTimestamp);
    if (timestamp == null) return false;
    final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = DateTime.now().difference(savedTime);
    return difference.inHours < _cacheValidHours;
  }
}
