// lib/features/history/controllers/history_period_filter.dart
import '../../../shared/models/measurement_model.dart';
import '../../../core/constants/app_constants.dart';

class HistoryPeriodFilter {
  final Map<String, List<MeasurementModel>> _cache = {};

  List<MeasurementModel> applyPeriodFilter(
      String period, List<MeasurementModel> measurements) {
    if (_cache.containsKey(period)) {
      AppConstants.logInfo('Usando cache: $period');
      return _cache[period]!;
    }

    List<MeasurementModel> filtered;

    if (period == 'all') {
      filtered = measurements;
    } else {
      final now = DateTime.now();
      late DateTime start;

      switch (period) {
        case 'week':
          start = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          start = now.subtract(const Duration(days: 30));
          break;
        case '3months':
          start = now.subtract(const Duration(days: 90));
          break;
        default:
          filtered = measurements;
          _cache[period] = filtered;
          return filtered;
      }

      filtered = measurements.where((m) => m.measuredAt.isAfter(start)).toList();
    }

    if (_cache.length >= 5) _cache.clear();
    _cache[period] = filtered;
    return filtered;
  }

  void clearCache() => _cache.clear();
}