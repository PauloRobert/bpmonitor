import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  MeasurementsNotifier() : super(const AsyncValue.loading()) {
    loadMeasurements();
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> loadMeasurements() async {
    try {
      AppConstants.logInfo('Carregando todas as medições via provider');
      state = const AsyncValue.loading();
      final measurements = await _dbHelper.getAllMeasurements();
      state = AsyncValue.data(measurements);
      AppConstants.logInfo('Medições carregadas no provider: ${measurements.length}');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar medições no provider', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addMeasurement(MeasurementModel measurement) async {
    try {
      AppConstants.logInfo('Adicionando medição via provider: ${measurement.systolic}/${measurement.diastolic}');
      await _dbHelper.insertMeasurement(measurement);
      await loadMeasurements();
      AppConstants.logInfo('Medição adicionada com sucesso via provider');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao adicionar medição via provider', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateMeasurement(MeasurementModel measurement) async {
    try {
      AppConstants.logInfo('Atualizando medição via provider: ID ${measurement.id}');
      await _dbHelper.updateMeasurement(measurement);
      await loadMeasurements();
      AppConstants.logInfo('Medição atualizada com sucesso via provider');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao atualizar medição via provider', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteMeasurement(int id) async {
    try {
      AppConstants.logInfo('Removendo medição via provider: ID $id');
      await _dbHelper.deleteMeasurement(id);
      await loadMeasurements();
      AppConstants.logInfo('Medição removida com sucesso via provider');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao remover medição via provider', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

class RecentMeasurementsNotifier extends StateNotifier<AsyncValue<List<MeasurementModel>>> {
  RecentMeasurementsNotifier() : super(const AsyncValue.loading()) {
    loadRecentMeasurements();
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> loadRecentMeasurements({int limit = 3}) async {
    try {
      AppConstants.logInfo('Carregando medições recentes via provider (limit: $limit)');
      state = const AsyncValue.loading();
      final measurements = await _dbHelper.getRecentMeasurements(limit: limit);
      state = AsyncValue.data(measurements);
      AppConstants.logInfo('Medições recentes carregadas no provider: ${measurements.length}');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar medições recentes no provider', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void refresh() {
    AppConstants.logInfo('Atualizando medições recentes no provider');
    loadRecentMeasurements();
  }
}

class WeeklyAverageNotifier extends StateNotifier<AsyncValue<Map<String, double>>> {
  WeeklyAverageNotifier() : super(const AsyncValue.loading()) {
    calculateWeeklyAverage();
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> calculateWeeklyAverage() async {
    try {
      AppConstants.logInfo('Calculando média semanal via provider');
      state = const AsyncValue.loading();

      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      final measurements = await _dbHelper.getMeasurementsInRange(startDate, endDate);

      if (measurements.isEmpty) {
        state = const AsyncValue.data({});
        AppConstants.logInfo('Nenhuma medição encontrada para média semanal');
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
      AppConstants.logInfo('Média semanal calculada no provider: ${averageData['systolic']?.toStringAsFixed(0)}/${averageData['diastolic']?.toStringAsFixed(0)}');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao calcular média semanal no provider', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void refresh() {
    AppConstants.logInfo('Atualizando média semanal no provider');
    calculateWeeklyAverage();
  }
}