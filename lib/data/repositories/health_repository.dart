import 'package:sqflite/sqflite.dart';

import '../models/health_data.dart';

class HealthRepository {
  HealthRepository(this._db);

  final Database _db;
  static const String _table = 'health_data';

  Future<List<HealthData>> getByDateRange(int startMs, int endMs) async {
    final rows = await _db.query(
      _table,
      where: 'start_time < ? AND end_time > ?',
      whereArgs: [endMs, startMs],
      orderBy: 'start_time ASC',
    );
    return rows.map(HealthData.fromMap).toList();
  }

  Future<List<HealthData>> getToday() async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final dayEnd = dayStart + (24 * 60 * 60 * 1000);
    return getByDateRange(dayStart, dayEnd);
  }

  Future<int> insert(HealthData data) async {
    return _db.insert(_table, data.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Bulk insert — used by sync.
  Future<void> bulkInsert(List<HealthData> records) async {
    final batch = _db.batch();
    for (final r in records) {
      batch.insert(_table, r.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Delete all records that overlap [startMs]..[endMs] (millisecond epoch).
  Future<void> deleteByDateRange(int startMs, int endMs) async {
    await _db.delete(
      _table,
      where: 'start_time < ? AND end_time > ?',
      whereArgs: [endMs, startMs],
    );
  }

  Future<void> deleteAll() => _db.delete(_table);
}
