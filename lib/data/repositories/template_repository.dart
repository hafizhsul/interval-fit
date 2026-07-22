import 'package:sqflite/sqflite.dart';

import '../models/workout_template.dart';

/// CRUD workout_template. DB diinjeksi lewat konstruktor supaya testable.
class TemplateRepository {
  TemplateRepository(this._db);

  final Database _db;
  static const String _table = 'workout_template';

  /// Insert baru, return template dengan id terisi.
  Future<WorkoutTemplate> create(WorkoutTemplate t) async {
    final id = await _db.insert(_table, t.toMap());
    return t.copyWith(id: id);
  }

  Future<List<WorkoutTemplate>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'created_at DESC');
    return rows.map(WorkoutTemplate.fromMap).toList();
  }

  Future<WorkoutTemplate?> getById(int id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkoutTemplate.fromMap(rows.first);
  }

  /// Update by id. Return jumlah baris terpengaruh.
  Future<int> update(WorkoutTemplate t) async {
    assert(t.id != null, 'update butuh id non-null');
    return _db.update(
      _table,
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<int> delete(int id) =>
      _db.delete(_table, where: 'id = ?', whereArgs: [id]);
}
