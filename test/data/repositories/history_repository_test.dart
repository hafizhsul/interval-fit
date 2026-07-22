import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/data/models/workout_session.dart';
import 'package:interval_fit/data/repositories/app_database.dart';
import 'package:interval_fit/data/repositories/history_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late HistoryRepository repo;

  setUp(() async {
    db = await AppDatabase.open(inMemoryDatabasePath);
    repo = HistoryRepository(db);
  });

  tearDown(() async => db.close());

  WorkoutSession session({
    required int startedAt,
    bool completed = true,
    int setsCompleted = 8,
  }) => WorkoutSession(
    templateName: 'Lari Interval',
    exerciseType: 'run',
    startedAt: startedAt,
    durationSeconds: 900,
    setsPlanned: 8,
    setsCompleted: setsCompleted,
    completed: completed,
  );

  test('insertSession assigns id and getAll returns newest first', () async {
    final older = await repo.insertSession(session(startedAt: 1000));
    final newer = await repo.insertSession(session(startedAt: 2000));
    expect(older.id, isNotNull);
    expect(newer.id, isNotNull);

    final all = await repo.getAll();
    expect(all.length, 2);
    expect(all.first.startedAt, 2000); // newest first
    expect(all.last.startedAt, 1000);
  });

  test('partial session (completed=0) stored and read back correctly', () async {
    await repo.insertSession(
      session(startedAt: 1500, completed: false, setsCompleted: 3),
    );
    final all = await repo.getAll();
    expect(all.length, 1);
    expect(all.first.completed, false);
    expect(all.first.setsCompleted, 3);
    expect(all.first.setsPlanned, 8);
  });
}
