import 'package:hive_flutter/hive_flutter.dart';
import 'package:xelex_esp/feature/timing_gates/session/data/model/athlete_model.dart';

class AthleteRepository {
  static const _boxName = 'athletes';
  static const int pageSize = 20;

  Box<AthleteModel> get _box => Hive.box<AthleteModel>(_boxName);

  // ── Write ───────────────────────────────────────────────────────────────────

  Future<void> save(AthleteModel athlete) async {
    await _box.put(athlete.id, athlete);
  }

  Future<void> saveAll(List<AthleteModel> athletes) async {
    final map = {for (final a in athletes) a.id: a};
    await _box.putAll(map);
  }

  Future<void> update(AthleteModel athlete) async {
    await _box.put(athlete.id, athlete);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  List<AthleteModel> getAll() => _box.values.toList();

  AthleteModel? getById(String id) => _box.get(id);

  bool exists(String id) => _box.containsKey(id);

  int count({String search = '', String team = ''}) =>
      _filtered(search: search, team: team).length;

  List<String> getAllTeams() {
    return _box.values
        .map((a) => a.team)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  /// Returns one page of athletes (filtered). Page is 0-indexed.
  List<AthleteModel> getPaged({
    int page = 0,
    String search = '',
    String team = '',
  }) {
    final filtered = _filtered(search: search, team: team);
    final start = page * pageSize;
    if (start >= filtered.length) return [];
    return filtered.skip(start).take(pageSize).toList();
  }

  bool hasMore({
    required int page,
    String search = '',
    String team = '',
  }) {
    final total = count(search: search, team: team);
    return total > (page + 1) * pageSize;
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  List<AthleteModel> _filtered({String search = '', String team = ''}) {
    return _box.values.where((a) {
      final q = search.toLowerCase();
      final matchSearch = search.isEmpty ||
          a.fullName.toLowerCase().contains(q) ||
          a.athleteId.toLowerCase().contains(q) ||
          a.bib.toLowerCase().contains(q) ||
          a.discipline.toLowerCase().contains(q);
      final matchTeam = team.isEmpty || a.team == team;
      return matchSearch && matchTeam;
    }).toList();
  }
}
