// lib/features/home/services/home_service.dart
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/measurement_model.dart';

class HomeService {
  final DatabaseService _db = DatabaseService.instance;

  // Cache interno (métrica semanal / medições recentes)
  Map<String, double>? _cachedWeeklyAverage;
  DateTime? _lastWeeklyAverageCalculation;
  List<MeasurementModel>? _cachedRecentMeasurements;
  DateTime? _lastRecentMeasurementsFetch;

  // Configurações de validade de cache
  static const Duration weeklyAverageCacheDuration = Duration(minutes: 0);
  static const Duration recentMeasurementsCacheDuration = Duration(minutes: 0);

  // ---------------------------
  // API pública
  // ---------------------------

  /// Carrega o perfil do usuário (delegando ao DatabaseService).
  Future<UserModel?> loadUserProfile() async {
    try {
      AppConstants.logInfo('[HomeService] loadUserProfile:start');
      final user = await _db.getUser();
      AppConstants.logInfo('[HomeService] loadUserProfile:success user=${user?.id}');
      return user;
    } catch (e, st) {
      AppConstants.logError('[HomeService] loadUserProfile:error', e, st);
      return null; // evita rethrow para não quebrar callers que esperam null
    }
  }

  /// Carrega medições recentes (usa cache curto).
  /// Mantém compatibilidade com getRecentMeasurements(limit).
  Future<List<MeasurementModel>> loadRecentMeasurements({int limit = 10}) async {
    try {
      final now = DateTime.now();
      final isCacheValid = _cachedRecentMeasurements != null &&
          _lastRecentMeasurementsFetch != null &&
          now.difference(_lastRecentMeasurementsFetch!).compareTo(recentMeasurementsCacheDuration) < 0;

      if (isCacheValid && _cachedRecentMeasurements!.length <= limit) {
        AppConstants.logInfo('[HomeService] loadRecentMeasurements:using cache (${_cachedRecentMeasurements!.length})');
        return List<MeasurementModel>.from(_cachedRecentMeasurements!);
      }

      AppConstants.logInfo('[HomeService] loadRecentMeasurements:fetching from db');
      final measurements = await _db.getRecentMeasurements(limit: limit);

      _cachedRecentMeasurements = measurements;
      _lastRecentMeasurementsFetch = now;

      AppConstants.logInfo('[HomeService] loadRecentMeasurements:success count=${measurements.length}');
      return measurements;
    } catch (e, st) {
      AppConstants.logError('[HomeService] loadRecentMeasurements:error', e, st);
      return <MeasurementModel>[];
    }
  }

  /// Calcula média semanal otimizada:
  /// - usa cache se válida;
  /// - tenta usar `recentMeasurements` se fornecida;
  /// - se insuficiente, busca no DB intervalo necessário.
  Future<Map<String, double>> computeWeeklyAverageOptimized({
    List<MeasurementModel>? recentMeasurements,
  }) async {
    final now = DateTime.now();

    try {
      // Retorna cache se válido
      if (_cachedWeeklyAverage != null &&
          _lastWeeklyAverageCalculation != null &&
          now.difference(_lastWeeklyAverageCalculation!).compareTo(weeklyAverageCacheDuration) < 0) {
        AppConstants.logInfo('[HomeService] computeWeeklyAverageOptimized:using cache');
        return Map<String, double>.from(_cachedWeeklyAverage!);
      }

      AppConstants.logInfo('[HomeService] computeWeeklyAverageOptimized:calculating');

      final endDate = now;
      final startDate = endDate.subtract(const Duration(days: 7));

      // Usa recentMeasurements informado (preferível)
      List<MeasurementModel> measurements = recentMeasurements ?? _cachedRecentMeasurements ?? <MeasurementModel>[];

      // Filtra para a semana
      measurements = measurements.where((m) => m.measuredAt.isAfter(startDate) && m.measuredAt.isBefore(endDate)).toList();

      // Se não for suficiente, busca no banco
      if (measurements.length < 3) {
        AppConstants.logInfo('[HomeService] computeWeeklyAverageOptimized:fetching range from db (insufficient cached items)');
        try {
          measurements = await _db.getMeasurementsInRange(startDate, endDate);
        } catch (e, st) {
          AppConstants.logError('[HomeService] computeWeeklyAverageOptimized:error fetching range', e, st);
          // se falhar, continuar com o que temos (possivelmente vazio)
        }
      }

      final result = _calculateAverageFromMeasurements(measurements);

      // Atualiza cache
      _cachedWeeklyAverage = result.isNotEmpty ? Map<String, double>.from(result) : null;
      _lastWeeklyAverageCalculation = result.isNotEmpty ? now : null;

      AppConstants.logInfo('[HomeService] computeWeeklyAverageOptimized:done count=${measurements.length}');
      return result;
    } catch (e, st) {
      AppConstants.logError('[HomeService] computeWeeklyAverageOptimized:error', e, st);
      return <String, double>{};
    }
  }

  /// Invalida caches (chame quando dados mudarem).
  void invalidateCache() {
    AppConstants.logInfo('[HomeService] invalidateCache');
    _cachedWeeklyAverage = null;
    _lastWeeklyAverageCalculation = null;
    _cachedRecentMeasurements = null;
    _lastRecentMeasurementsFetch = null;
  }

  // ---------------------------
  // HELPERS privados
  // ---------------------------

  Map<String, double> _calculateAverageFromMeasurements(List<MeasurementModel> measurements) {
    if (measurements.isEmpty) return {};

    double totalSystolic = 0;
    double totalDiastolic = 0;
    double totalHeartRate = 0;

    for (final m in measurements) {
      totalSystolic += m.systolic;
      totalDiastolic += m.diastolic;
      totalHeartRate += m.heartRate;
    }

    final count = measurements.length.toDouble();
    return {
      'systolic': totalSystolic / count,
      'diastolic': totalDiastolic / count,
      'heartRate': totalHeartRate / count,
    };
  }
}