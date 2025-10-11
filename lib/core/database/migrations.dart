/// ============================================================================
/// Migrations
/// ============================================================================
/// - Define as versões do schema do banco de dados.
/// - Cada entrada no mapa `_migrations` representa uma versão do DB
///   com as alterações necessárias (CREATE TABLE, ALTER TABLE, índices, etc).
/// - `runMigrations`: executado em `onCreate` (primeira vez).
/// - `upgradeMigrations`: executado em `onUpgrade` (quando versão do app aumenta).
/// - Mantém o banco evolutivo, seguro e retrocompatível.
/// ============================================================================
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import 'helpers.dart';

typedef Migration = Future<void> Function(DatabaseExecutor db);

final Map<int, Migration> _migrations = {
  1: (db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.usersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birth_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.measurementsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        heart_rate INTEGER NOT NULL,
        measured_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_created_at ON ${AppConstants.usersTable}(created_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_measurements_measured_at ON ${AppConstants.measurementsTable}(measured_at)');
  },

  // Exemplo de migration futura
  2: (db) async {
    final exists = await columnExists(db, AppConstants.measurementsTable, 'user_id');
    if (!exists) {
      await db.execute('ALTER TABLE ${AppConstants.measurementsTable} ADD COLUMN user_id INTEGER');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_measurements_user_id ON ${AppConstants.measurementsTable}(user_id)');
    }
  },
};

Future<void> runMigrations(Database db, int targetVersion) async {
  final versions = _migrations.keys.toList()..sort();
  await db.transaction((txn) async {
    for (final v in versions) {
      if (v <= targetVersion) {
        final migration = _migrations[v];
        if (migration != null) await migration(txn);
      }
    }
  });
}

Future<void> upgradeMigrations(Database db, int oldVersion, int newVersion) async {
  if (oldVersion >= newVersion) return;
  final versions = _migrations.keys.toList()..sort();
  await db.transaction((txn) async {
    for (final v in versions) {
      if (v > oldVersion && v <= newVersion) {
        final migration = _migrations[v];
        if (migration != null) await migration(txn);
      }
    }
  });
}