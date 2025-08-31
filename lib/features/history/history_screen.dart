import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../shared/models/measurement_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper();

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
      AppConstants.logInfo('Carregando histórico de medições');

      setState(() {
        _isLoading = true;
        _currentPage = 0;
      });

      final measurements = await _dbHelper.getAllMeasurements();

      setState(() {
        _measurements = measurements;
        _filteredMeasurements = _applyPeriodFilter(measurements);
        _isLoading = false;
        _hasMoreData = _filteredMeasurements.length > _itemsPerPage;
      });

      AppConstants.logInfo('Histórico carregado: ${measurements.length} medições');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar histórico', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMeasurements() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Simula carregamento

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

  void _editMeasurement(MeasurementModel measurement) {
    AppConstants.logNavigation('HistoryScreen', 'EditMeasurementScreen');
    // TODO: Navegar para tela de edição
  }

  Future<void> _deleteMeasurement(MeasurementModel measurement) async {
    final confirmed = await _showDeleteDialog();

    if (confirmed == true) {
      try {
        await _dbHelper.deleteMeasurement(measurement.id!);
        AppConstants.logInfo('Medição deletada: ID ${measurement.id}');
        _loadMeasurements(); // Recarrega a lista

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
        child: CircularProgressIndicator(
          color: AppConstants.primaryColor,
        ),
      );
    }

    if (_filteredMeasurements.isEmpty) {
      return _buildEmptyState();
    }

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
                if (index == itemsToShow) {
                  return _buildLoadingIndicator();
                }

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
      color: AppConstants.primaryColor.withOpacity(0.05),
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

  Widget _buildMeasurementCard(MeasurementModel measurement, int index) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: measurement.categoryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Row(
          children: [
            Text(
              '${measurement.systolic}/${measurement.diastolic}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: measurement.categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                measurement.categoryName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: measurement.categoryColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '❤️ ${measurement.heartRate} bpm',
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '📅 ${measurement.formattedDate} às ${measurement.formattedTime}',
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
              ),
            ),
            if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '📝 ${measurement.notes}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: AppConstants.textSecondary),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remover', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _editMeasurement(measurement);
            } else if (value == 'delete') {
              _deleteMeasurement(measurement);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          color: AppConstants.primaryColor,
        ),
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
            Icon(
              Icons.history,
              size: 80,
              color: AppConstants.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 80,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Gráfico em desenvolvimento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppConstants.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Em breve você poderá visualizar seus dados em gráficos interativos',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}