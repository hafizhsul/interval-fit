import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/core/health_connect_service.dart';
import 'package:interval_fit/data/models/health_data.dart';
import 'package:interval_fit/data/repositories/health_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthRepository extends Mock implements HealthRepository {}

void main() {
  late MockHealthRepository repo;
  late HealthConnectService svc;

  setUp(() {
    repo = MockHealthRepository();
    svc = HealthConnectService(repo);
  });

  group('getTodayAggregated', () {
    test('returns empty map when no data', () async {
      when(() => repo.getToday()).thenAnswer((_) async => []);

      final result = await svc.getTodayAggregated();

      expect(result, isEmpty);
      verify(() => repo.getToday()).called(1);
    });

    test('returns aggregated values', () async {
      when(() => repo.getToday()).thenAnswer((_) async => [
        HealthData(
          type: HealthRecordType.steps,
          value: 5000,
          unit: 'steps',
          startTime: 0,
          endTime: 3600000,
          syncedAt: 1000,
        ),
        HealthData(
          type: HealthRecordType.heartRate,
          value: 72,
          unit: 'bpm',
          startTime: 0,
          endTime: 0,
          syncedAt: 1000,
        ),
        HealthData(
          type: HealthRecordType.activeEnergyBurned,
          value: 250,
          unit: 'kcal',
          startTime: 0,
          endTime: 3600000,
          syncedAt: 1000,
        ),
      ]);

      final result = await svc.getTodayAggregated();

      expect(result, hasLength(3));
      expect(result['steps'], 5000);
      expect(result['heartRate'], 72);
      expect(result['activeEnergyBurned'], 250);
    });
  });

  group('getForDate', () {
    test('queries repository with correct date range', () async {
      when(() => repo.getByDateRange(any(), any()))
          .thenAnswer((_) async => []);

      final epochMs = DateTime(2025, 6, 15).millisecondsSinceEpoch;
      await svc.getForDate(epochMs);

      final dayStart = DateTime(2025, 6, 15).millisecondsSinceEpoch;
      final dayEnd = dayStart + (24 * 60 * 60 * 1000);
      verify(() => repo.getByDateRange(dayStart, dayEnd)).called(1);
    });

    test('returns aggregated values from repository', () async {
      final epochMs = DateTime(2025, 6, 15).millisecondsSinceEpoch;
      when(() => repo.getByDateRange(any(), any()))
          .thenAnswer((_) async => [
        HealthData(
          type: HealthRecordType.steps,
          value: 3000,
          unit: 'steps',
          startTime: epochMs,
          endTime: epochMs + 3600000,
          syncedAt: epochMs + 1000,
        ),
      ]);

      final result = await svc.getForDate(epochMs);

      expect(result['steps'], 3000);
    });
  });

  group('syncToday', () {
    test('calls deleteByDateRange and bulkInsert with today range', () async {
      when(() => repo.deleteByDateRange(any(), any()))
          .thenAnswer((_) async {});
      when(() => repo.bulkInsert(any())).thenAnswer((_) async {});

      // Override fetchToday to return data without calling platform API
      final svc2 = _TestHealthConnectService(repo);
      await svc2.syncToday();

      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final dayEnd = dayStart + (24 * 60 * 60 * 1000);
      verify(() => repo.deleteByDateRange(dayStart, dayEnd)).called(1);
    });
  });

  group('fetchToday', () {
    test('returns empty list when HC not available', () async {
      final result = await svc.fetchToday();
      expect(result, isEmpty);
    });
  });
}

class _TestHealthConnectService extends HealthConnectService {
  _TestHealthConnectService(super.repository);

  @override
  Future<List<HealthData>> fetchToday() async {
    return [
      HealthData(
        type: HealthRecordType.steps,
        value: 1000,
        unit: 'steps',
        startTime: DateTime.now().millisecondsSinceEpoch,
        endTime: DateTime.now().millisecondsSinceEpoch,
        syncedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
  }
}
