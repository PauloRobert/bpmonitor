import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/measurement_model.dart';
import '../../../core/constants/app_constants.dart';

import 'history_period_filter.dart';
import '../widgets/history_delete_dialog.dart';

abstract class HistoryScreenController {
  void loadMeasurements();
}

class HistoryController extends ChangeNotifier {
  final HistoryScreenController widgetInterface;

  HistoryController(this.widgetInterface);

  final db = DatabaseService.instance;

  List<MeasurementModel> measurements = [];
  List<MeasurementModel> filteredMeasurements = [];

  bool isLoading = true;
  String selectedPeriod = 'all';
  bool showHeartRate = true;

  final periodFilter = HistoryPeriodFilter();
  Timer? _debounceTimer;

  final Map<String, String> periods = {
    'all': 'Todos',
    'week': '7 dias',
    'month': '30 dias',
    '3months': '90 dias',
  };

  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void toggleShowHeartRate(bool val) {
    showHeartRate = val;
    notifyListeners();
  }

  // ------ LOADING ---------

  Future<void> loadMeasurementsOptimized() async {
    try {
      isLoading = true;
      notifyListeners();

      final all = await db.getAllMeasurements();

      measurements = all;
      filteredMeasurements =
          periodFilter.applyPeriodFilter(selectedPeriod, measurements);

      isLoading = false;
      notifyListeners();

      AppConstants.logInfo('Histórico carregado: ${measurements.length}');
    } catch (e, st) {
      AppConstants.logError('Erro ao carregar histórico', e, st);
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMeasurementsWithDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadMeasurementsOptimized();
    });
  }

  // ------ PERIOD FILTER ---------

  void changePeriod(String period) {
    selectedPeriod = period;
    filteredMeasurements =
        periodFilter.applyPeriodFilter(period, measurements);
    notifyListeners();
  }

  // ------ EDIT ---------

  Future<void> editMeasurement(
      BuildContext context, MeasurementModel measurement) async {
    final result = await Navigator.of(context).pushNamed(
      '/edit_measurement',
      arguments: measurement,
    );

    if (result == true) {
      periodFilter.clearCache();
      loadMeasurementsWithDebounce();
    }
  }

  // ------ DELETE ---------

  Future<void> deleteMeasurement(
      BuildContext context, MeasurementModel measurement) async {
    final confirmed = await showDeleteDialog(context);

    if (confirmed == true) {
      try {
        await db.deleteMeasurement(measurement.id!);

        measurements.removeWhere((m) => m.id == measurement.id);
        filteredMeasurements.removeWhere((m) => m.id == measurement.id);

        periodFilter.clearCache();

        notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Medição removida com sucesso'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
      } catch (e, st) {
        AppConstants.logError('Erro ao deletar medição', e, st);

        loadMeasurementsWithDebounce();

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao remover medição'),
          backgroundColor: AppConstants.secondaryColor,
          duration: Duration(seconds: 2),
        ));
      }
    }
  }
}