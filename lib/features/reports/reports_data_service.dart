/// ============================================================================
/// ReportsDataService
/// ============================================================================
/// - Responsável por toda a lógica de dados e cálculos dos relatórios
/// - Inclui cache inteligente, filtros e processamento otimizado
/// - Isolado da UI para melhor testabilidade e reutilização
/// ============================================================================

import 'dart:math' as math;
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/measurement_model.dart';
import '../../shared/models/user_model.dart';

class ReportsDataService {
  static final ReportsDataService _instance = ReportsDataService._internal();
  factory ReportsDataService() => _instance;
  ReportsDataService._internal();

  final DatabaseService _db = DatabaseService.instance;

  // Cache de dados processados
  final Map<String, Map<String, dynamic>> _reportCache = {};
  List<MeasurementModel> _measurements = [];
  UserModel? _user;

  /// Carrega dados do banco de forma otimizada
  Future<Map<String, dynamic>> loadData() async {
    try {
      // Carregamento paralelo
      final results = await Future.wait([
        _db.getAllMeasurements(),
        _db.getUser(),
      ]);

      _measurements = results[0] as List<MeasurementModel>;
      _user = results[1] as UserModel?;

      return {
        'measurements': _measurements,
        'user': _user,
        'success': true,
      };
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar dados dos relatórios', e, stackTrace);
      return {
        'measurements': <MeasurementModel>[],
        'user': null,
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Gera dados do relatório com cache inteligente
  Map<String, dynamic> generateReportData(String selectedPeriod) {
    // Verifica cache primeiro
    if (_reportCache.containsKey(selectedPeriod)) {
      AppConstants.logInfo('Usando cache para relatório: $selectedPeriod');
      return _reportCache[selectedPeriod]!;
    }

    AppConstants.logInfo('Measurements carregadas: ${_measurements.length}');

    if (_measurements.isEmpty) {
      AppConstants.logInfo('Nenhuma medição encontrada para o relatório');
      return {};
    }

    final filteredMeasurements = _getFilteredMeasurements(selectedPeriod);

    if (filteredMeasurements.isEmpty) {
      return {};
    }

    // Processamento otimizado em uma passada
    final stats = _calculateStatsOptimized(filteredMeasurements);

    // Distribuição por categorias
    final categoryDistribution = <String, int>{};
    for (final measurement in filteredMeasurements) {
      final category = measurement.category;
      categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;
    }

    // Tendência otimizada
    final trend = _calculateTrendOptimized(filteredMeasurements);

    // Horários mais comuns
    final hourDistribution = <int, int>{};
    for (final measurement in filteredMeasurements) {
      final hour = measurement.measuredAt.hour;
      hourDistribution[hour] = (hourDistribution[hour] ?? 0) + 1;
    }

    final mostCommonHour = hourDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final reportData = {
      'totalMeasurements': filteredMeasurements.length,
      'period': selectedPeriod,
      'averages': stats['averages'],
      'extremes': stats['extremes'],
      'categoryDistribution': categoryDistribution,
      'trend': trend,
      'mostCommonHour': mostCommonHour,
      'measurements': filteredMeasurements,
    };

    // Armazena no cache (máximo 10 períodos)
    if (_reportCache.length >= 10) {
      _reportCache.clear();
    }
    _reportCache[selectedPeriod] = reportData;

    return reportData;
  }

  /// Filtra medições por período
  List<MeasurementModel> _getFilteredMeasurements(String selectedPeriod) {
    if (selectedPeriod == 'all') return _measurements;

    final now = DateTime.now();
    DateTime startDate;

    switch (selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '3months':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case 'year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        return _measurements;
    }

    return _measurements.where((m) => m.measuredAt.isAfter(startDate)).toList();
  }

  /// Cálculo de estatísticas em uma única passada
  Map<String, dynamic> _calculateStatsOptimized(List<MeasurementModel> measurements) {
    if (measurements.isEmpty) {
      return {'averages': {}, 'extremes': {}};
    }

    double systolicSum = 0;
    double diastolicSum = 0;
    double heartRateSum = 0;

    int maxSystolic = measurements.first.systolic;
    int minSystolic = measurements.first.systolic;
    int maxDiastolic = measurements.first.diastolic;
    int minDiastolic = measurements.first.diastolic;
    int maxHeartRate = measurements.first.heartRate;
    int minHeartRate = measurements.first.heartRate;

    // Uma única passada para calcular tudo
    for (final measurement in measurements) {
      systolicSum += measurement.systolic;
      diastolicSum += measurement.diastolic;
      heartRateSum += measurement.heartRate;

      maxSystolic = math.max(maxSystolic, measurement.systolic);
      minSystolic = math.min(minSystolic, measurement.systolic);
      maxDiastolic = math.max(maxDiastolic, measurement.diastolic);
      minDiastolic = math.min(minDiastolic, measurement.diastolic);
      maxHeartRate = math.max(maxHeartRate, measurement.heartRate);
      minHeartRate = math.min(minHeartRate, measurement.heartRate);
    }

    final count = measurements.length;

    return {
      'averages': {
        'systolic': systolicSum / count,
        'diastolic': diastolicSum / count,
        'heartRate': heartRateSum / count,
      },
      'extremes': {
        'maxSystolic': maxSystolic,
        'minSystolic': minSystolic,
        'maxDiastolic': maxDiastolic,
        'minDiastolic': minDiastolic,
        'maxHeartRate': maxHeartRate,
        'minHeartRate': minHeartRate,
      },
    };
  }

  /// Cálculo de tendência otimizado
  String _calculateTrendOptimized(List<MeasurementModel> measurements) {
    if (measurements.length < 10) return 'stable';

    final sampleSize = math.min(5, measurements.length ~/ 2);

    double recentSum = 0;
    double olderSum = 0;

    for (int i = 0; i < sampleSize; i++) {
      recentSum += measurements[i].systolic;
      olderSum += measurements[measurements.length - 1 - i].systolic;
    }

    final recentAvg = recentSum / sampleSize;
    final olderAvg = olderSum / sampleSize;

    if (recentAvg > olderAvg + 5) {
      return 'increasing';
    } else if (recentAvg < olderAvg - 5) {
      return 'decreasing';
    }
    return 'stable';
  }

  /// Getters para dados
  List<MeasurementModel> get measurements => _measurements;
  UserModel? get user => _user;

  /// Limpa cache quando necessário
  void clearCache() {
    _reportCache.clear();
  }

  /// Obtém medições filtradas para um período específico
  List<MeasurementModel> getFilteredMeasurements(String period) {
    return _getFilteredMeasurements(period);
  }
}