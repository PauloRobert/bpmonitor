/// ============================================================================
/// DatabaseService
/// ============================================================================
/// - Fachada principal para acesso ao banco SQLite.
/// - Responsável por:
///   • Inicializar e manter o Singleton da conexão com o banco.
///   • Rodar migrations de criação/atualização de schema.
///   • Expor métodos de CRUD existentes (retrocompatibilidade).
///   • Expor instâncias de DAOs (`UserDao`, `MeasurementDao`) para uso futuro.
/// - Mantém todos os métodos antigos para que o código já existente
///   no app continue funcionando sem precisar de alterações.
/// ============================================================================
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/measurement_model.dart';
import 'migrations.dart';
import 'helpers.dart';
import 'user_dao.dart';
import 'measurement_dao.dart';

class DatabaseService {
  // Singleton real
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  static Database? _database;
  static final _initLock = Object();

  Future<Database> get database async {
    if (_database != null) return _database!;
    return await synchronized(_initLock, () async {
      _database ??= await _initDatabase();
      return _database!;
    });
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.databaseName);

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: (db, version) => runMigrations(db, version),
        onUpgrade: (db, oldV, newV) => upgradeMigrations(db, oldV, newV),
      );
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao inicializar database', e, stackTrace);
      rethrow;
    }
  }

  // =================== Fachada para DAOs ===================

  Future<UserDao> get userDao async => UserDao(await database);
  Future<MeasurementDao> get measurementDao async => MeasurementDao(await database);

  // =================== Métodos legados (retrocompatibilidade) ===================

  Future<int> insertUser(UserModel user) async =>
      (await userDao).insert(user);

  Future<UserModel?> getUser() async =>
      (await userDao).getLastUser();

  Future<int> updateUser(UserModel user) async =>
      (await userDao).update(user);

  Future<int> insertMeasurement(MeasurementModel measurement) async =>
      (await measurementDao).insert(measurement);

  Future<List<MeasurementModel>> getAllMeasurements() async =>
      (await measurementDao).getAll();

  Future<List<MeasurementModel>> getRecentMeasurements({int limit = 10}) async =>
      (await measurementDao).getRecent(limit: limit);

  Future<List<MeasurementModel>> getMeasurementsInRange(DateTime start, DateTime end) async =>
      (await measurementDao).getInRange(start, end);

  Future<int> updateMeasurement(MeasurementModel measurement) async =>
      (await measurementDao).update(measurement);

  Future<int> deleteMeasurement(int id) async =>
      (await measurementDao).delete(id);

  Future<void> clearAllData() async =>
      (await measurementDao).clearAll(await userDao);

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