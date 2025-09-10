import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/measurement_model.dart';
import '../measurements/edit_measurement_screen.dart'; // NOVA IMPORTAÇÃO
import 'dart:math';

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
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  final ScrollController _scrollController = ScrollController();
  final int _itemsPerPage = 30;
  int _currentPage = 0;

  String _selectedPeriod = 'all';
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
    _scrollController.addListener(_onScroll);
    _loadMeasurements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void loadMeasurements() {
    _loadMeasurements();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData && _tabController.index == 0) {
        _loadMoreMeasurements();
      }
    }
  }

  Future<void> _loadMeasurements() async {
    try {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
      });
      final measurements = await db.getAllMeasurements();
      setState(() {
        _measurements = measurements;
        _filteredMeasurements = _applyPeriodFilter(measurements);
        _isLoading = false;
        _hasMoreData = _filteredMeasurements.length > _itemsPerPage;
      });
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar histórico', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMeasurements() async {
    if (_isLoadingMore || !_hasMoreData) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _currentPage++;
      _isLoadingMore = false;
      final endIndex = (_currentPage + 1) * _itemsPerPage;
      _hasMoreData = endIndex < _filteredMeasurements.length;
    });
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
      _currentPage = 0;
      _hasMoreData = _filteredMeasurements.length > _itemsPerPage;
    });
  }

  // ✅ NOVA FUNÇÃO: Navegar para edição
  void _editMeasurement(MeasurementModel measurement) async {
    AppConstants.logNavigation('HistoryScreen', 'EditMeasurementScreen');

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditMeasurementScreen(measurement: measurement),
      ),
    );

    if (result == true) {
      _loadMeasurements(); // Recarregar dados após edição

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.refresh, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Dados atualizados!'),
              ],
            ),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteMeasurement(MeasurementModel measurement) async {
    final confirmed = await _showDeleteDialog(measurement);
    if (confirmed == true) {
      try {
        await db.deleteMeasurement(measurement.id!);
        _loadMeasurements();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Medição removida com sucesso'),
                ],
              ),
              backgroundColor: AppConstants.successColor,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Desfazer',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Implementar desfazer (opcional)
                },
              ),
            ),
          );
        }
      } catch (e, stackTrace) {
        AppConstants.logError('Erro ao deletar medição', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Erro ao remover medição'),
                ],
              ),
              backgroundColor: AppConstants.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ✅ MELHORADO: Dialog de confirmação mais informativo
  Future<bool?> _showDeleteDialog(MeasurementModel measurement) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppConstants.dangerColor),
            const SizedBox(width: 8),
            const Text('Confirmar exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tem certeza que deseja remover esta medição?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Text(
                    '${measurement.systolic}/${measurement.diastolic}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${measurement.heartRate} bpm'),
                  const Spacer(),
                  Text(
                    measurement.formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta ação não pode ser desfeita.',
              style: TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.dangerColor,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
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
        automaticallyImplyLeading: false,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(),
          _buildChartView(),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppConstants.primaryColor),
      );
    }
    if (_filteredMeasurements.isEmpty) return _buildEmptyState();

    final displayItems = (_currentPage + 1) * _itemsPerPage;
    final itemsToShow = displayItems > _filteredMeasurements.length
        ? _filteredMeasurements.length
        : displayItems;

    return RefreshIndicator(
      onRefresh: _loadMeasurements,
      color: AppConstants.primaryColor,
      child: Column(
        children: [
          _buildPeriodHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: itemsToShow + (_hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == itemsToShow) return _buildLoadingIndicator();
                final measurement = _filteredMeasurements[index];
                return _buildMeasurementCard(measurement, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    if (_selectedPeriod == 'all') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppConstants.primaryColor.withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: AppConstants.primaryColor, size: 16),
          const SizedBox(width: 8),
          Text(
            'Exibindo: ${_periods[_selectedPeriod]} (${_filteredMeasurements.length} registros)',
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MELHORADO: Card de medição mais informativo e visual
  Widget _buildMeasurementCard(MeasurementModel measurement, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editMeasurement(measurement), // ✅ NOVO: Tap para editar
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: measurement.categoryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Indicador visual da categoria
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: measurement.categoryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Conteúdo principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${measurement.systolic}/${measurement.diastolic}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: measurement.categoryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: measurement.categoryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                measurement.categoryName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: measurement.categoryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(Icons.favorite, size: 16, color: Colors.red.shade400),
                            const SizedBox(width: 4),
                            Text(
                              '${measurement.heartRate} bpm',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppConstants.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.schedule, size: 16, color: AppConstants.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${measurement.formattedDate} às ${measurement.formattedTime}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.note, size: 14, color: AppConstants.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    measurement.notes!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppConstants.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Menu de ações
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppConstants.textSecondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: AppConstants.primaryColor),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 18, color: AppConstants.textSecondary),
                            SizedBox(width: 8),
                            Text('Duplicar'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppConstants.dangerColor),
                            const SizedBox(width: 8),
                            Text(
                              'Remover',
                              style: TextStyle(color: AppConstants.dangerColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editMeasurement(measurement);
                          break;
                        case 'duplicate':
                          _duplicateMeasurement(measurement);
                          break;
                        case 'delete':
                          _deleteMeasurement(measurement);
                          break;
                      }
                    },
                  ),
                ],
              ),

              // ✅ NOVO: Alertas médicos se houver
              if (measurement.medicalAlerts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: measurement.categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: measurement.categoryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: measurement.categoryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          measurement.medicalAlerts.first,
                          style: TextStyle(
                            fontSize: 11,
                            color: measurement.categoryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NOVA FUNÇÃO: Duplicar medição
  void _duplicateMeasurement(MeasurementModel measurement) async {
    try {
      final duplicated = measurement.copyWith(
        id: null, // Remove ID para criar nova
        measuredAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await db.insertMeasurement(duplicated);
      _loadMeasurements();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.content_copy, color: Colors.white),
                SizedBox(width: 8),
                Text('Medição duplicada com sucesso'),
              ],
            ),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao duplicar medição', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro ao duplicar medição'),
              ],
            ),
            backgroundColor: AppConstants.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(color: AppConstants.primaryColor),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.textSecondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 64,
                color: AppConstants.textSecondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedPeriod == 'all'
                  ? 'Nenhuma medição registrada'
                  : 'Nenhuma medição neste período',
              style: const TextStyle(
                fontSize: 18,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedPeriod == 'all'
                  ? 'Adicione sua primeira medição'
                  : 'Tente selecionar um período maior',
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartView() {
    if (_filteredMeasurements.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma medição para exibir',
          style: TextStyle(color: AppConstants.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.show_chart,
                      size: 48,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gráficos Interativos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Em desenvolvimento',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_filteredMeasurements.isEmpty) return const SizedBox.shrink();

    final data = _filteredMeasurements;
    final systolicAvg = data.map((m) => m.systolic).reduce((a, b) => a + b) / data.length;
    final diastolicAvg = data.map((m) => m.diastolic).reduce((a, b) => a + b) / data.length;
    final hrAvg = data.map((m) => m.heartRate).reduce((a, b) => a + b) / data.length;

    final systolicMax = data.map((m) => m.systolic).reduce(max);
    final systolicMin = data.map((m) => m.systolic).reduce(min);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Média',
                '${systolicAvg.round()}/${diastolicAvg.round()}',
                'mmHg',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Batimentos',
                '${hrAvg.round()}',
                'bpm',
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Máxima',
                '$systolicMax',
                'mmHg',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Mínima',
                '$systolicMin',
                'mmHg',
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}