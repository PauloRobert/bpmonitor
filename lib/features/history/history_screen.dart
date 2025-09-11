import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/measurement_model.dart';
import '../../features/measurements/edit_measurement_screen.dart';
import '../../features/measurements/measurements_list_tab.dart' as list_tab;
import '../../features/measurements/measurements_chart_tab.dart' as chart_tab;

abstract class HistoryScreenController {
  void loadMeasurements();
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin
    implements HistoryScreenController {
  late TabController _tabController;
  final db = DatabaseService.instance;
  List<MeasurementModel> _measurements = [];
  List<MeasurementModel> _filteredMeasurements = [];
  bool _isLoading = true;
  String _selectedPeriod = 'all';
  bool _showHeartRate = true;

  final Map<String, String> _periods = {
    'all': 'Todos',
    'week': 'Última semana',
    'month': 'Último mês',
    '3months': 'Últimos 3 meses',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMeasurements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void loadMeasurements() {
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    try {
      setState(() => _isLoading = true);
      final measurements = await db.getAllMeasurements();
      setState(() {
        _measurements = measurements;
        _filteredMeasurements = _applyPeriodFilter(measurements);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar histórico', e, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  List<MeasurementModel> _applyPeriodFilter(List<MeasurementModel> measurements) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '3months':
        startDate = now.subtract(const Duration(days: 90));
        break;
      default:
        return measurements;
    }

    return measurements.where((m) => m.measuredAt.isAfter(startDate)).toList();
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _filteredMeasurements = _applyPeriodFilter(_measurements);
    });
  }

  Future<void> _editMeasurement(MeasurementModel measurement) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditMeasurementScreen(measurement: measurement),
      ),
    );

    if (result == true) {
      _loadMeasurements();
    }
  }

  Future<void> _deleteMeasurement(MeasurementModel measurement) async {
    final confirmed = await _showDeleteDialog();
    if (confirmed == true) {
      try {
        await db.deleteMeasurement(measurement.id!);
        _loadMeasurements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medição removida com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        AppConstants.logError('Erro ao deletar medição', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao remover medição'),
              backgroundColor: AppConstants.secondaryColor,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showDeleteDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja remover esta medição?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddMeasurement() {
    Navigator.of(context).pushNamed('/add_measurement').then((_) {
      _loadMeasurements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Histórico'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppConstants.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: AppConstants.textSecondary,
          indicatorColor: AppConstants.primaryColor,
          tabs: const [
            Tab(text: 'Lista', icon: Icon(Icons.list)),
            Tab(text: 'Gráfico', icon: Icon(Icons.show_chart)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: AppConstants.textPrimary),
            onSelected: _changePeriod,
            itemBuilder: (context) => _periods.entries.map((entry) {
              return PopupMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(
                      _selectedPeriod == entry.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(entry.value),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : TabBarView(
        controller: _tabController,
        children: [
          list_tab.MeasurementsListTab(
            measurements: _filteredMeasurements,
            onPeriodChange: _changePeriod,
            onEditMeasurement: _editMeasurement,
            onDeleteMeasurement: _deleteMeasurement,
            onLoadMeasurements: _loadMeasurements,
            selectedPeriod: _selectedPeriod,
            periods: _periods,
          ),
          chart_tab.MeasurementsChartTab(
            measurements: _filteredMeasurements,
            showHeartRate: _showHeartRate,
            onToggleHeartRate: (val) {
              setState(() => _showHeartRate = val);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addMeasurementBtn',
        onPressed: _navigateToAddMeasurement,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}