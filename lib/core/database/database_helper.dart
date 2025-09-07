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
  Completer<Database>? _dbCompleter;

  // CORREÇÃO: Lazy initialization com Completer
  Future<Database> get database async {
    if (_database != null) return _database!;

    if (_dbCompleter != null) {
      return _dbCompleter!.future;
    }

    _dbCompleter = Completer<Database>();

    try {
      _database = await _initDatabase();
      _dbCompleter!.complete(_database!);
      return _database!;
    } catch (e) {
      _dbCompleter!.completeError(e);
      _dbCompleter = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.databaseName);

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
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao criar tabelas', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Futuras migrações aqui
  }

  // ========== OPERAÇÕES DE USUÁRIO ==========

  Future<int> insertUser(UserModel user) async {
    try {
      final db = await database;
      final id = await db.insert(AppConstants.usersTable, user.toMap());
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

      if (maps.isEmpty) return null;
      return UserModel.fromMap(maps.first);
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

      return maps.map((map) => MeasurementModel.fromMap(map)).toList();
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

      return maps.map((map) => MeasurementModel.fromMap(map)).toList();
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

      return maps.map((map) => MeasurementModel.fromMap(map)).toList();
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
      return deletedRows;
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao deletar medição', e, stackTrace);
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete(AppConstants.measurementsTable);
      await db.delete(AppConstants.usersTable);
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
      }
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao fechar database', e, stackTrace);
    }
  }
}