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
    'week': '7 dias',
    'month': '30 dias',
    '3months': '90 dias',
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

      if (!mounted) return;

      setState(() {
        _measurements = measurements;
        _filteredMeasurements = _applyPeriodFilter(measurements);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar histórico', e, stackTrace);
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<MeasurementModel> _applyPeriodFilter(List<MeasurementModel> measurements) {
    if (_selectedPeriod == 'all') {
      return measurements;
    }

    final now = DateTime.now();
    late DateTime startDate;

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

    if (result == true && mounted) {
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
              duration: Duration(seconds: 2),
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
              duration: Duration(seconds: 2),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
      if (mounted) {
        _loadMeasurements();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96), // Altura fixa otimizada
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              const Text(
                'Histórico',
                style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              if (!_isLoading && _filteredMeasurements.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredMeasurements.length}',
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            // Filtro de período
            PopupMenuButton<String>(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list, color: AppConstants.textPrimary),
                  if (_selectedPeriod != 'all')
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onSelected: _changePeriod,
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => _periods.entries.map((entry) {
                final isSelected = _selectedPeriod == entry.key;
                return PopupMenuItem<String>(
                  value: entry.key,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppConstants.primaryColor
                              : AppConstants.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected
                                ? AppConstants.primaryColor
                                : AppConstants.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppConstants.primaryColor,
            unselectedLabelColor: AppConstants.textSecondary,
            indicatorColor: AppConstants.primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                height: 46,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.list, size: 20),
                    SizedBox(width: 6),
                    Text('Lista'),
                  ],
                ),
              ),
              Tab(
                height: 46,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.show_chart, size: 20),
                    SizedBox(width: 6),
                    Text('Gráfico'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppConstants.primaryColor,
        ),
      )
          : TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Performance: evita scroll desnecessário
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
    );
  }
}