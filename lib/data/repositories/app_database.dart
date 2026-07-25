import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Helper init/open DB sqflite. Skema & seed default dibuat di [onCreate].
/// Repository menerima [Database] lewat konstruktor (injeksi ala ElapsedClock
/// di timer_engine) supaya test bisa memberi DB in-memory/ffi.
class AppDatabase {
  AppDatabase._();

  static const String dbName = 'interval_fit.db';
  static const int dbVersion = 2;

  static Database? _instance;

  /// Buka/ambil DB app (singleton). Untuk test, pakai [open] dengan factory ffi.
  static Future<Database> instance() async {
    if (_instance != null) return _instance!;
    final dir = await getDatabasesPath();
    _instance = await open(p.join(dir, dbName));
    return _instance!;
  }

  /// Buka DB di [path] ('' atau [inMemoryDatabasePath] untuk test).
  /// Memakai [databaseFactory] aktif — test bisa set databaseFactoryFfi.
  static Future<Database> open(String path) => openDatabase(
        path,
        version: dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS health_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          record_type TEXT NOT NULL,
          value REAL NOT NULL,
          unit TEXT NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER NOT NULL,
          synced_at INTEGER NOT NULL,
          source TEXT
        )
      ''');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workout_template (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        exercise_type TEXT NOT NULL,
        sets INTEGER NOT NULL,
        work_seconds INTEGER NOT NULL,
        rest_seconds INTEGER NOT NULL,
        warmup_seconds INTEGER NOT NULL DEFAULT 0,
        cooldown_seconds INTEGER NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER,
        template_name TEXT NOT NULL,
        exercise_type TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        sets_planned INTEGER NOT NULL,
        sets_completed INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(template_id) REFERENCES workout_template(id) ON DELETE SET NULL
      )
    ''');

    await _seedDefaults(db);
  }

  /// Seed HANYA di onCreate → tidak duplikat saat reopen.
  static Future<void> _seedDefaults(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaults = <Map<String, Object?>>[
      {
        'name': 'Skipping Beginner',
        'exercise_type': 'skipping',
        'sets': 10,
        'work_seconds': 30,
        'rest_seconds': 30,
        'warmup_seconds': 0,
        'cooldown_seconds': 0,
        'is_default': 1,
        'created_at': now,
      },
      {
        'name': 'Interval Run',
        'exercise_type': 'run',
        'sets': 8,
        'work_seconds': 60,
        'rest_seconds': 60,
        'warmup_seconds': 0,
        'cooldown_seconds': 0,
        'is_default': 1,
        'created_at': now,
      },
    ];
    final batch = db.batch();
    for (final t in defaults) {
      batch.insert('workout_template', t);
    }
    await batch.commit(noResult: true);
  }
}
