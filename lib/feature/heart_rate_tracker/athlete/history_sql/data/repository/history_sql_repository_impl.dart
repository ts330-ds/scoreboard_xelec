import '../../domain/entity/daily_hr_summary.dart';
import '../../domain/entity/hr_reading.dart';
import '../../domain/repository/history_sql_repository.dart';
import '../datasource/history_sql_datasource.dart';

class HistorySqlRepositoryImpl implements HistorySqlRepository {
  HistorySqlRepositoryImpl._();
  static final HistorySqlRepositoryImpl instance =
      HistorySqlRepositoryImpl._();

  final _ds = HistorySqlDatasource.instance;

  @override
  Future<int> ingestHr(List<Map<dynamic, dynamic>> chunk) =>
      _ds.upsertHr(chunk);

  @override
  Future<int> ingestRr(List<Map<dynamic, dynamic>> chunk) =>
      _ds.upsertRr(chunk);

  @override
  Future<int> ingestSleep(List<Map<dynamic, dynamic>> list) =>
      _ds.upsertSleep(list);

  @override
  Future<List<DailyHrSummary>> dailySummaries() => _ds.dailySummaries();

  @override
  Future<List<HrReading>> readingsInRange(int fromSec, int toSec) =>
      _ds.readingsInRange(fromSec, toSec);

  @override
  Future<int> hrCount() => _ds.hrCount();

  @override
  Future<void> clear() => _ds.clear();
}
