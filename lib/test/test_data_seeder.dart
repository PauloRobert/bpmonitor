import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/measurement_model.dart';
import '../../core/constants/app_constants.dart';

/// ============================================================================
/// Classe de teste para popular o banco com medições aleatórias
/// Totalmente isolada, não depende de telas ou widgets.
/// ============================================================================

class TestDataSeeder {
  final DatabaseService _dbService;

  TestDataSeeder() : _dbService = DatabaseService.instance;

  /// Insere [count] medições aleatórias no banco
  Future<void> populateMeasurements({int count = 50000}) async {
    final random = Random();
    final now = DateTime.now();

    // Obtenha o DAO de forma assíncrona
    final measurementDao = await _dbService.measurementDao;

    List<MeasurementModel> measurements = [];

    for (int i = 0; i < count; i++) {
      final systolic = AppConstants.minSystolic +
          random.nextInt(AppConstants.maxSystolic - AppConstants.minSystolic + 1);
      final diastolic = AppConstants.minDiastolic +
          random.nextInt(AppConstants.maxDiastolic - AppConstants.minDiastolic + 1);
      final heartRate = AppConstants.minHeartRate +
          random.nextInt(AppConstants.maxHeartRate - AppConstants.minHeartRate + 1);

      final measurement = MeasurementModel(
        systolic: systolic,
        diastolic: diastolic,
        heartRate: heartRate,
        measuredAt: now.subtract(Duration(days: i)), // datas diferentes
        createdAt: now.subtract(Duration(days: i)),
      );

      measurements.add(measurement);
    }

    await measurementDao.insertBatch(measurements);

    AppConstants.logInfo('Inseridas ${measurements.length} medições de teste.');
  }

  /// Limpa todas as medições do banco
  Future<void> clearAllMeasurements() async {
    final measurementDao = await _dbService.measurementDao;
    final userDao = await _dbService.userDao;

    await measurementDao.clearAll(userDao);

    AppConstants.logInfo('Banco de medições limpo.');
  }
}