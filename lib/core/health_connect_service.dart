import '../data/models/health_data.dart';
import '../data/repositories/health_repository.dart';

/// Health Connect sync service. READ-only — never writes to Health Connect.
/// Currently uses stubbed values; replace with real HC calls when ready.
class HealthConnectService {
  HealthConnectService(this._repository);

  final HealthRepository _repository;

  /// Fetch latest health data from device (stubbed for v2).
  Future<List<HealthData>> fetchToday() async {
    // ponytail: no HC package yet -> return empty until package selected.
    return [];
  }

  /// Sync today's data into local DB.
  Future<void> syncToday() async {
    final records = await fetchToday();
    if (records.isEmpty) return;
    await _repository.bulkInsert(records);
  }

  /// Get today's aggregated stats from local DB.
  Future<Map<String, double>> getTodayAggregated() async {
    try {
      final today = await _repository.getToday();
      final map = <String, double>{};
      for (final r in today) {
        map[r.type.name] = r.value;
      }
      return map;
    } catch (_) {
      return const {};
    }
  }
}
