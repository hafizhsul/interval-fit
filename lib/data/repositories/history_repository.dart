import 'package:sqflite/sqflite.dart';

import '../models/workout_session.dart';

/// Riwayat sesi latihan. DB diinjeksi lewat konstruktor supaya testable.
class HistoryRepository {
  HistoryRepository(this._db);

  final Database _db;
  static const String _table = 'workout_session';

  Future<WorkoutSession> insertSession(WorkoutSession s) async {
    final id = await _db.insert(_table, s.toMap());
    return s.copyWith(id: id);
  }

  /// Riwayat terbaru dulu.
  Future<List<WorkoutSession>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'started_at DESC');
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<int> deleteAll() => _db.delete(_table);
}
