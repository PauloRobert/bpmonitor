import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/measurement_model.dart';

class DatabaseService {
  // Singleton real
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

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
      await db.execute('''
        CREATE TABLE ${AppConstants.usersTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          birth_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

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
    // Futuras migrações de banco aqui
  }

  // =================== AUXILIAR CENTRAL DE ERROS ===================

  Future<T> _execute<T>(Future<T> Function(Database db) operation, String errorMessage) async {
    try {
      final db = await database;
      return await operation(db);
    } catch (e, stackTrace) {
      AppConstants.logError(errorMessage, e, stackTrace);
      rethrow;
    }
  }

  // =================== USUÁRIO ===================

  Future<int> insertUser(UserModel user) =>
      _execute((db) => db.insert(AppConstants.usersTable, user.toMap()), 'Erro ao inserir usuário');

  Future<UserModel?> getUser() =>
      _execute((db) async {
        final maps = await db.query(
          AppConstants.usersTable,
          orderBy: 'created_at DESC',
          limit: 1,
        );
        return maps.isEmpty ? null : UserModel.fromMap(maps.first);
      }, 'Erro ao buscar usuário');

  Future<int> updateUser(UserModel user) =>
      _execute((db) => db.update(AppConstants.usersTable, user.toMap(), where: 'id = ?', whereArgs: [user.id]),
          'Erro ao atualizar usuário');

  // =================== MEDIÇÕES ===================

  Future<int> insertMeasurement(MeasurementModel measurement) =>
      _execute((db) => db.insert(AppConstants.measurementsTable, measurement.toMap()), 'Erro ao inserir medição');

  Future<List<MeasurementModel>> getAllMeasurements() =>
      _execute((db) async {
        final maps = await db.query(AppConstants.measurementsTable, orderBy: 'measured_at DESC');
        return maps.map(MeasurementModel.fromMap).toList();
      }, 'Erro ao buscar medições');

  Future<List<MeasurementModel>> getRecentMeasurements({int limit = 10}) =>
      _execute((db) async {
        final maps = await db.query(AppConstants.measurementsTable, orderBy: 'measured_at DESC', limit: limit);
        return maps.map(MeasurementModel.fromMap).toList();
      }, 'Erro ao buscar medições recentes');

  Future<List<MeasurementModel>> getMeasurementsInRange(DateTime start, DateTime end) =>
      _execute((db) async {
        final maps = await db.query(
          AppConstants.measurementsTable,
          where: 'measured_at BETWEEN ? AND ?',
          whereArgs: [start.toIso8601String(), end.toIso8601String()],
          orderBy: 'measured_at DESC',
        );
        return maps.map(MeasurementModel.fromMap).toList();
      }, 'Erro ao buscar medições por período');

  Future<int> updateMeasurement(MeasurementModel measurement) =>
      _execute((db) => db.update(AppConstants.measurementsTable, measurement.toMap(),
          where: 'id = ?', whereArgs: [measurement.id]), 'Erro ao atualizar medição');

  Future<int> deleteMeasurement(int id) =>
      _execute((db) => db.delete(AppConstants.measurementsTable, where: 'id = ?', whereArgs: [id]),
          'Erro ao deletar medição');

  Future<void> clearAllData() =>
      _execute((db) async {
        await db.delete(AppConstants.measurementsTable);
        await db.delete(AppConstants.usersTable);
      }, 'Erro ao limpar dados');

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