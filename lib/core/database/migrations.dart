/// ============================================================================
/// Migrations - ATUALIZADO COM NOVOS CAMPOS
/// ============================================================================
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import 'helpers.dart';

typedef Migration = Future<void> Function(DatabaseExecutor db);

final Map<int, Migration> _migrations = {
  1: (db) async {
    // Tabela de usuários COM NOVOS CAMPOS
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.usersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birth_date TEXT NOT NULL,
        gender TEXT NOT NULL,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabela de medições (mantida igual)
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

  // Migration para adicionar os novos campos em bancos existentes
  2: (db) async {
    // Verifica se os campos já existem antes de adicionar
    final genderExists = await columnExists(db, AppConstants.usersTable, 'gender');
    final weightExists = await columnExists(db, AppConstants.usersTable, 'weight');
    final heightExists = await columnExists(db, AppConstants.usersTable, 'height');

    if (!genderExists) {
      await db.execute('ALTER TABLE ${AppConstants.usersTable} ADD COLUMN gender TEXT NOT NULL DEFAULT "M"');
    }

    if (!weightExists) {
      await db.execute('ALTER TABLE ${AppConstants.usersTable} ADD COLUMN weight REAL NOT NULL DEFAULT 70.0');
    }

    if (!heightExists) {
      await db.execute('ALTER TABLE ${AppConstants.usersTable} ADD COLUMN height REAL NOT NULL DEFAULT 1.70');
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