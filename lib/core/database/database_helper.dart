import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/measurement_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      AppConstants.logInfo('Inicializando database...');

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.databaseName);

      AppConstants.logDatabase('init', 'database', 'Path: $path');

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao inicializar database', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      AppConstants.logDatabase('onCreate', 'all_tables', 'Version: $version');

      // Tabela de usuários
      await db.execute('''
        CREATE TABLE ${AppConstants.usersTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          birth_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Tabela de medições
      await db.execute('''
        CREATE TABLE ${AppConstants.measurementsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          systolic INTEGER NOT NULL,
          diastolic INTEGER NOT NULL,
          heart_rate INTEGER NOT NULL,
          measured_at TEXT NOT NULL,
          created_at TEXT NOT NULL,
          notes TEXT
        )
      ''');

      AppConstants.logDatabase('onCreate', 'all_tables', 'Tabelas criadas com sucesso');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao criar tabelas', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppConstants.logDatabase('onUpgrade', 'database', 'From v$oldVersion to v$newVersion');
    // Futuras migrações aqui
  }

  // ========== OPERAÇÕES DE USUÁRIO ==========

  Future<int> insertUser(UserModel user) async {
    try {
      final db = await database;
      final id = await db.insert(AppConstants.usersTable, user.toMap());
      AppConstants.logDatabase('insert', AppConstants.usersTable, 'ID: $id, Name: ${user.name}');
      return id;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao inserir usuário', e, stackTrace);
      rethrow;
    }
  }

  Future<UserModel?> getUser() async {
    try {
      final db = await database;
      final maps = await db.query(
        AppConstants.usersTable,
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) {
        AppConstants.logDatabase('select', AppConstants.usersTable, 'Nenhum usuário encontrado');
        return null;
      }

      final user = UserModel.fromMap(maps.first);
      AppConstants.logDatabase('select', AppConstants.usersTable, 'User: ${user.name}');
      return user;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao buscar usuário', e, stackTrace);
      return null;
    }
  }

  Future<int> updateUser(UserModel user) async {
    try {
      final db = await database;
      final updatedRows = await db.update(
        AppConstants.usersTable,
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      AppConstants.logDatabase('update', AppConstants.usersTable, 'Rows affected: $updatedRows');
      return updatedRows;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao atualizar usuário', e, stackTrace);
      rethrow;
    }
  }

  // ========== OPERAÇÕES DE MEDIÇÕES ==========

  Future<int> insertMeasurement(MeasurementModel measurement) async {
    try {
      final db = await database;
      final id = await db.insert(AppConstants.measurementsTable, measurement.toMap());
      AppConstants.logDatabase('insert', AppConstants.measurementsTable, 'ID: $id, BP: ${measurement.systolic}/${measurement.diastolic}');
      return id;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao inserir medição', e, stackTrace);
      rethrow;
    }
  }

  Future<List<MeasurementModel>> getAllMeasurements() async {
    try {
      final db = await database;
      final maps = await db.query(
        AppConstants.measurementsTable,
        orderBy: 'measured_at DESC',
      );

      final measurements = maps.map((map) => MeasurementModel.fromMap(map)).toList();
      AppConstants.logDatabase('select', AppConstants.measurementsTable, 'Count: ${measurements.length}');
      return measurements;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao buscar medições', e, stackTrace);
      return [];
    }
  }

  Future<List<MeasurementModel>> getRecentMeasurements({int limit = 10}) async {
    try {
      final db = await database;
      final maps = await db.query(
        AppConstants.measurementsTable,
        orderBy: 'measured_at DESC',
        limit: limit,
      );

      final measurements = maps.map((map) => MeasurementModel.fromMap(map)).toList();
      AppConstants.logDatabase('select', AppConstants.measurementsTable, 'Recent count: ${measurements.length}');
      return measurements;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao buscar medições recentes', e, stackTrace);
      return [];
    }
  }

  Future<List<MeasurementModel>> getMeasurementsInRange(DateTime start, DateTime end) async {
    try {
      final db = await database;
      final maps = await db.query(
        AppConstants.measurementsTable,
        where: 'measured_at BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'measured_at DESC',
      );

      final measurements = maps.map((map) => MeasurementModel.fromMap(map)).toList();
      AppConstants.logDatabase('select', AppConstants.measurementsTable, 'Range count: ${measurements.length}');
      return measurements;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao buscar medições por período', e, stackTrace);
      return [];
    }
  }

  Future<int> updateMeasurement(MeasurementModel measurement) async {
    try {
      final db = await database;
      final updatedRows = await db.update(
        AppConstants.measurementsTable,
        measurement.toMap(),
        where: 'id = ?',
        whereArgs: [measurement.id],
      );
      AppConstants.logDatabase('update', AppConstants.measurementsTable, 'Rows affected: $updatedRows');
      return updatedRows;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao atualizar medição', e, stackTrace);
      rethrow;
    }
  }

  Future<int> deleteMeasurement(int id) async {
    try {
      final db = await database;
      final deletedRows = await db.delete(
        AppConstants.measurementsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      AppConstants.logDatabase('delete', AppConstants.measurementsTable, 'ID: $id, Rows affected: $deletedRows');
      return deletedRows;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao deletar medição', e, stackTrace);
      rethrow;
    }
  }

  // ========== OPERAÇÕES DE LIMPEZA ==========

  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete(AppConstants.measurementsTable);
      await db.delete(AppConstants.usersTable);
      AppConstants.logDatabase('delete', 'all_tables', 'Todos os dados removidos');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao limpar dados', e, stackTrace);
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      final db = _database;
      if (db != null) {
        await db.close();
        _database = null;
        AppConstants.logDatabase('close', 'database', 'Conexão fechada');
      }
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao fechar database', e, stackTrace);
    }
  }
}