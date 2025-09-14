// history_screen.dart - OTIMIZADO PARA PERFORMANCE
import 'package:flutter/material.dart';
import 'dart:async';
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
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin
    implements HistoryScreenController {

  @override
  bool get wantKeepAlive => true; // NOVO: Mantém estado ao voltar

  late TabController _tabController;
  final db = DatabaseService.instance;

  List<MeasurementModel> _measurements = [];
  List<MeasurementModel> _filteredMeasurements = [];
  bool _isLoading = true;
  String _selectedPeriod = 'all';
  bool _showHeartRate = true;

  // OTIMIZAÇÃO 1: Cache para evitar reprocessamento
  final Map<String, List<MeasurementModel>> _periodCache = {};
  Timer? _loadDebounceTimer;

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
    _loadMeasurementsOptimized();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loadDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void loadMeasurements() {
    _loadMeasurementsWithDebounce();
  }

  // OTIMIZAÇÃO 2: Carregamento com paginação e cache
  Future<void> _loadMeasurementsOptimized() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // ESTRATÉGIA: Carrega em chunks pequenos para não travar a UI
      final measurements = await _loadMeasurementsInChunks();

      if (!mounted) return;

      setState(() {
        _measurements = measurements;
        _filteredMeasurements = _applyPeriodFilterWithCache(measurements);
        _isLoading = false;
      });

      AppConstants.logInfo('Histórico carregado: ${measurements.length} medições');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar histórico', e, stackTrace);
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // TEMPORÁRIO: Usa método original até implementar paginação
  Future<List<MeasurementModel>> _loadMeasurementsInChunks() async {
    // Por enquanto, usa o método original para não quebrar
    return await db.getAllMeasurements();
  }

  // OTIMIZAÇÃO 3: Cache de filtros para evitar reprocessamento
  List<MeasurementModel> _applyPeriodFilterWithCache(List<MeasurementModel> measurements) {
    // Verifica cache primeiro
    if (_periodCache.containsKey(_selectedPeriod)) {
      AppConstants.logInfo('Usando cache para período: $_selectedPeriod');
      return _periodCache[_selectedPeriod]!;
    }

    List<MeasurementModel> filtered;

    if (_selectedPeriod == 'all') {
      filtered = measurements;
    } else {
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
        // Fallback para 'all' se período não reconhecido
          filtered = measurements;
          _periodCache[_selectedPeriod] = filtered;
          return filtered;
      }

      filtered = measurements.where((m) => m.measuredAt.isAfter(startDate)).toList();
    }

    // Armazena no cache (máximo 5 períodos)
    if (_periodCache.length >= 5) {
      _periodCache.clear();
    }
    _periodCache[_selectedPeriod] = filtered;

    return filtered;
  }

  // OTIMIZAÇÃO 4: Debounce para mudanças rápidas
  void _loadMeasurementsWithDebounce() {
    _loadDebounceTimer?.cancel();
    _loadDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _loadMeasurementsOptimized();
    });
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _filteredMeasurements = _applyPeriodFilterWithCache(_measurements);
    });
  }

  Future<void> _editMeasurement(MeasurementModel measurement) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditMeasurementScreen(measurement: measurement),
      ),
    );

    if (result == true && mounted) {
      // Limpa cache ao editar
      _periodCache.clear();
      _loadMeasurementsWithDebounce();
    }
  }

  Future<void> _deleteMeasurement(MeasurementModel measurement) async {
    final confirmed = await _showDeleteDialog();
    if (confirmed == true) {
      try {
        await db.deleteMeasurement(measurement.id!);

        // OTIMIZAÇÃO 5: Remove localmente primeiro (otimistic update)
        setState(() {
          _measurements.removeWhere((m) => m.id == measurement.id);
          _filteredMeasurements.removeWhere((m) => m.id == measurement.id);
        });

        // Limpa cache
        _periodCache.clear();

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
        // Recarrega em caso de erro
        _loadMeasurementsWithDebounce();

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
        _periodCache.clear(); // Limpa cache ao adicionar
        _loadMeasurementsWithDebounce();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
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
            tabs: const [
              Tab(
                height: 46,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                  children: [
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
        physics: const NeverScrollableScrollPhysics(),
        children: [
          list_tab.MeasurementsListTab(
            measurements: _filteredMeasurements,
            onPeriodChange: _changePeriod,
            onEditMeasurement: _editMeasurement,
            onDeleteMeasurement: _deleteMeasurement,
            onLoadMeasurements: loadMeasurements,
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