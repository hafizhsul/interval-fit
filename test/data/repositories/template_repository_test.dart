import 'package:flutter_test/flutter_test.dart';
import 'package:interval_fit/data/models/workout_template.dart';
import 'package:interval_fit/data/repositories/app_database.dart';
import 'package:interval_fit/data/repositories/template_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late TemplateRepository repo;

  setUp(() async {
    db = await AppDatabase.open(inMemoryDatabasePath);
    repo = TemplateRepository(db);
  });

  tearDown(() async => db.close());

  WorkoutTemplate sample() => WorkoutTemplate(
    name: 'HIIT',
    exerciseType: 'custom',
    sets: 5,
    workSeconds: 40,
    restSeconds: 20,
    warmupSeconds: 15,
    cooldownSeconds: 10,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );

  test('CRUD round-trip', () async {
    // create
    final created = await repo.create(sample());
    expect(created.id, isNotNull);

    // read back
    final fetched = await repo.getById(created.id!);
    expect(fetched, isNotNull);
    expect(fetched!.name, 'HIIT');
    expect(fetched.exerciseType, 'custom');
    expect(fetched.sets, 5);
    expect(fetched.workSeconds, 40);
    expect(fetched.restSeconds, 20);
    expect(fetched.warmupSeconds, 15);
    expect(fetched.cooldownSeconds, 10);
    expect(fetched.isDefault, false);

    // update
    final updated = fetched.copyWith(name: 'HIIT v2', sets: 8);
    final n = await repo.update(updated);
    expect(n, 1);
    final afterUpdate = await repo.getById(created.id!);
    expect(afterUpdate!.name, 'HIIT v2');
    expect(afterUpdate.sets, 8);

    // delete
    final deleted = await repo.delete(created.id!);
    expect(deleted, 1);
    expect(await repo.getById(created.id!), isNull);
  });

  test('seeds exactly 2 defaults with correct values on fresh DB', () async {
    final all = await repo.getAll();
    expect(all.length, 2);
    expect(all.every((t) => t.isDefault), true);

    final skipping = all.firstWhere((t) => t.name == 'Skipping Beginner');
    expect(skipping.exerciseType, 'skipping');
    expect(skipping.sets, 10);
    expect(skipping.workSeconds, 30);
    expect(skipping.restSeconds, 30);

    final run = all.firstWhere((t) => t.name == 'Interval Run');
    expect(run.exerciseType, 'run');
    expect(run.sets, 8);
    expect(run.workSeconds, 60);
    expect(run.restSeconds, 60);
  });

  test('reopening DB does not re-seed', () async {
    // Fresh in-memory DB per open would reset, so use a shared temp file.
    final dir = await databaseFactory.getDatabasesPath();
    final path = '$dir/reopen_test_${DateTime.now().microsecondsSinceEpoch}.db';

    var d = await AppDatabase.open(path);
    expect((await TemplateRepository(d).getAll()).length, 2);
    await d.close();

    d = await AppDatabase.open(path);
    expect((await TemplateRepository(d).getAll()).length, 2);
    await d.close();

    await databaseFactory.deleteDatabase(path);
  });
}
