import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/measurement_model.dart';

class MeasurementsListTab extends StatefulWidget {
  final List<MeasurementModel> measurements;
  final Function(String) onPeriodChange;
  final Function(MeasurementModel) onEditMeasurement;
  final Function(MeasurementModel) onDeleteMeasurement;
  final Function() onLoadMeasurements;
  final String selectedPeriod;
  final Map<String, String> periods;

  const MeasurementsListTab({
    super.key,
    required this.measurements,
    required this.onPeriodChange,
    required this.onEditMeasurement,
    required this.onDeleteMeasurement,
    required this.onLoadMeasurements,
    required this.selectedPeriod,
    required this.periods,
  });

  @override
  State<MeasurementsListTab> createState() => _MeasurementsListTabState();
}

class _MeasurementsListTabState extends State<MeasurementsListTab> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  final int _itemsPerPage = 30;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreMeasurements();
      }
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
      _hasMoreData = endIndex < widget.measurements.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.measurements.isEmpty) return _buildEmptyState();

    final displayItems = (_currentPage + 1) * _itemsPerPage;
    final itemsToShow = displayItems > widget.measurements.length
        ? widget.measurements.length
        : displayItems;

    return RefreshIndicator(
      onRefresh: () async => widget.onLoadMeasurements(),
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
                final measurement = widget.measurements[index];
                return _buildMeasurementCard(measurement, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    if (widget.selectedPeriod == 'all') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppConstants.primaryColor.withOpacity(0.05),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: AppConstants.primaryColor, size: 16),
          const SizedBox(width: 8),
          Text(
            'Exibindo: ${widget.periods[widget.selectedPeriod]} (${widget.measurements.length} registros)',
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
            if (value == 'edit') widget.onEditMeasurement(measurement);
            else if (value == 'delete') widget.onDeleteMeasurement(measurement);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: AppConstants.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              widget.selectedPeriod == 'all'
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
              widget.selectedPeriod == 'all'
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
}