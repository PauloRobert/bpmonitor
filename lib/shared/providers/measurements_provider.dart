// measurements_provider.dart - CORRIGIDO
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_service.dart';
import '../models/measurement_model.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/app_constants.dart';

final measurementsProvider = StateNotifierProvider<MeasurementsNotifier, AsyncValue<List<MeasurementModel>>>((ref) {
  return MeasurementsNotifier();
});

final recentMeasurementsProvider = StateNotifierProvider<RecentMeasurementsNotifier, AsyncValue<List<MeasurementModel>>>((ref) {
  return RecentMeasurementsNotifier();
});

final weeklyAverageProvider = StateNotifierProvider<WeeklyAverageNotifier, AsyncValue<Map<String, double>>>((ref) {
  return WeeklyAverageNotifier();
});

class MeasurementsNotifier extends StateNotifier<AsyncValue<List<MeasurementModel>>> {
  // CORREÇÃO: Não carrega automaticamente
  MeasurementsNotifier() : super(const AsyncValue.data([]));

  final db = DatabaseService.instance;

  Future<void> loadMeasurements() async {
    try {
      state = const AsyncValue.loading();
      final measurements = await db.getAllMeasurements();
      state = AsyncValue.data(measurements);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addMeasurement(MeasurementModel measurement) async {
    try {
      await db.insertMeasurement(measurement);
      await loadMeasurements();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateMeasurement(MeasurementModel measurement) async {
    try {
      await db.updateMeasurement(measurement);
      await loadMeasurements();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteMeasurement(int id) async {
    try {
      await db.deleteMeasurement(id);
      await loadMeasurements();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

class RecentMeasurementsNotifier extends StateNotifier<AsyncValue<List<MeasurementModel>>> {
  // CORREÇÃO: Não carrega automaticamente
  RecentMeasurementsNotifier() : super(const AsyncValue.data([]));

  final db = DatabaseService.instance;

  Future<void> loadRecentMeasurements({int limit = 3}) async {
    try {
      state = const AsyncValue.loading();
      final measurements = await db.getRecentMeasurements(limit: limit);
      state = AsyncValue.data(measurements);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void refresh() {
    loadRecentMeasurements();
  }
}

class WeeklyAverageNotifier extends StateNotifier<AsyncValue<Map<String, double>>> {
  // CORREÇÃO: Não carrega automaticamente
  WeeklyAverageNotifier() : super(const AsyncValue.data({}));

  final db = DatabaseService.instance;

  Future<void> calculateWeeklyAverage() async {
    try {
      state = const AsyncValue.loading();

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      final measurements = await db.getMeasurementsInRange(startDate, endDate);

      if (measurements.isEmpty) {
        state = const AsyncValue.data({});
        return;
      }

      double totalSystolic = 0;
      double totalDiastolic = 0;
      double totalHeartRate = 0;

      for (final measurement in measurements) {
        totalSystolic += measurement.systolic;
        totalDiastolic += measurement.diastolic;
        totalHeartRate += measurement.heartRate;
      }

      final count = measurements.length;
      final averageData = {
        'systolic': totalSystolic / count,
        'diastolic': totalDiastolic / count,
        'heartRate': totalHeartRate / count,
      };

      state = AsyncValue.data(averageData);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void refresh() {
    calculateWeeklyAverage();
  }
}