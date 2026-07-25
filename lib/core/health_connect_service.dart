import 'package:health/health.dart';

import '../data/models/health_data.dart';
import '../data/repositories/health_repository.dart';

class HealthConnectService {
  HealthConnectService(this._repository);

  final HealthRepository _repository;
  final Health _health = Health();
  bool _configured = false;
  bool _permissionGranted = false;

  Future<bool> _ensureConfigured() async {
    if (_configured) return true;
    try {
      await _health.configure();
      _configured = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isAvailable() async {
    if (!await _ensureConfigured()) return false;
    try {
      return await _health.isHealthConnectAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermission() async => _permissionGranted;

  Future<bool> requestPermissions() async {
    if (!await _ensureConfigured()) return false;
    try {
      await _health.requestAuthorization([
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ]);
      _permissionGranted = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<HealthData>> fetchToday() async {
    if (!await _ensureConfigured()) return [];

    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      final records = <HealthData>[];
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];

      for (final type in types) {
        try {
          final result = await _health.getHealthDataFromTypes(
            startTime: start,
            endTime: end,
            types: [type],
          );
          for (final r in result) {
            final value = (r.value as NumericHealthValue).numericValue.toDouble();
            records.add(HealthData(
              type: _mapType(type),
              value: value,
              unit: _unitFor(type),
              startTime: r.dateFrom.millisecondsSinceEpoch,
              endTime: r.dateTo.millisecondsSinceEpoch,
              syncedAt: DateTime.now().millisecondsSinceEpoch,
            ));
          }
        } catch (_) {
          // Record type not available on this device — skip
        }
      }
      return records;
    } catch (_) {
      return [];
    }
  }

  Future<void> syncToday() async {
    final records = await fetchToday();
    if (records.isEmpty) return;
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final dayEnd = dayStart + (24 * 60 * 60 * 1000);
    await _repository.deleteByDateRange(dayStart, dayEnd);
    await _repository.bulkInsert(records);
  }

  Future<Map<String, double>> getTodayAggregated() async {
    final today = await _repository.getToday();
    return _aggregate(today);
  }

  Future<Map<String, double>> getForDate(int epochMs) async {
    final start = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final dayStart = DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;
    final dayEnd = dayStart + (24 * 60 * 60 * 1000);
    final records = await _repository.getByDateRange(dayStart, dayEnd);
    return _aggregate(records);
  }

  static Map<String, double> _aggregate(List<HealthData> records) {
    final map = <String, double>{};
    final counts = <String, int>{};
    for (final r in records) {
      if (r.type == HealthRecordType.steps ||
          r.type == HealthRecordType.activeEnergyBurned) {
        map[r.type.name] = (map[r.type.name] ?? 0) + r.value;
      } else {
        map[r.type.name] = (map[r.type.name] ?? 0) + r.value;
        counts[r.type.name] = (counts[r.type.name] ?? 0) + 1;
      }
    }
    for (final key in counts.keys) {
      map[key] = map[key]! / counts[key]!;
    }
    return map;
  }

  HealthRecordType _mapType(HealthDataType t) {
    if (t == HealthDataType.STEPS) return HealthRecordType.steps;
    if (t == HealthDataType.HEART_RATE) return HealthRecordType.heartRate;
    return HealthRecordType.activeEnergyBurned;
  }

  String _unitFor(HealthDataType t) {
    if (t == HealthDataType.STEPS) return 'steps';
    if (t == HealthDataType.HEART_RATE) return 'bpm';
    return 'kcal';
  }
}
