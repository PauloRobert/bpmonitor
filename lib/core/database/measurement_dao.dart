/// ============================================================================
/// MeasurementDao
/// ============================================================================
/// - Responsável pelas operações de CRUD relacionadas à tabela `measurements`.
/// - Inclui queries comuns: todas medições, recentes, por intervalo de datas.
/// - Fornece métodos para inserção em batch e exclusão.
/// ============================================================================
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../../shared/models/measurement_model.dart';
import 'helpers.dart';
import 'user_dao.dart';

class MeasurementDao {
  final Database db;
  MeasurementDao(this.db);

  Future<int> insert(MeasurementModel measurement) async {
    return await db.insert(AppConstants.measurementsTable, measurement.toMap());
  }

  Future<List<MeasurementModel>> getAll() async {
    final maps = await db.query(AppConstants.measurementsTable, orderBy: 'measured_at DESC');
    return maps.map(MeasurementModel.fromMap).toList();
  }

  Future<List<MeasurementModel>> getRecent({int limit = 10}) async {
    final maps = await db.query(
      AppConstants.measurementsTable,
      orderBy: 'measured_at DESC',
      limit: limit,
    );
    return maps.map(MeasurementModel.fromMap).toList();
  }

  Future<List<MeasurementModel>> getInRange(DateTime start, DateTime end) async {
    final maps = await db.query(
      AppConstants.measurementsTable,
      where: 'measured_at BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'measured_at DESC',
    );
    return maps.map(MeasurementModel.fromMap).toList();
  }

  Future<int> update(MeasurementModel measurement) async {
    return await db.update(
      AppConstants.measurementsTable,
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  Future<int> delete(int id) async {
    return await db.delete(AppConstants.measurementsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertBatch(List<MeasurementModel> measurements) async {
    final maps = measurements.map((m) => m.toMap());
    await batchInsert(db, AppConstants.measurementsTable, maps);
  }

  Future<void> clearAll(UserDao userDao) async {
    await db.transaction((txn) async {
      await txn.delete(AppConstants.measurementsTable);
      await txn.delete(AppConstants.usersTable);
    });
  }
}