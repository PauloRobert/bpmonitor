// measurements_list_tab.dart - OTIMIZADO PARA PERFORMANCE
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

class _MeasurementsListTabState extends State<MeasurementsListTab>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  // OTIMIZAÇÃO 1: Cache do agrupamento para evitar reprocessamento
  Map<String, List<MeasurementModel>>? _cachedGroupedMeasurements;
  List<String>? _cachedSortedDates;
  List<MeasurementModel>? _lastProcessedMeasurements;

  @override
  void didUpdateWidget(MeasurementsListTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // OTIMIZAÇÃO 2: Só reprocessa se a lista realmente mudou
    if (oldWidget.measurements != widget.measurements) {
      _invalidateCache();
    }
  }

  void _invalidateCache() {
    _cachedGroupedMeasurements = null;
    _cachedSortedDates = null;
    _lastProcessedMeasurements = null;
  }

  // OTIMIZAÇÃO 3: Agrupamento lazy com cache
  Map<String, List<MeasurementModel>> _getGroupedMeasurements() {
    // Verifica se pode usar cache
    if (_cachedGroupedMeasurements != null &&
        _lastProcessedMeasurements == widget.measurements) {
      return _cachedGroupedMeasurements!;
    }

    // Reprocessa apenas se necessário
    final grouped = <String, List<MeasurementModel>>{};
    for (final measurement in widget.measurements) {
      final dateKey = measurement.formattedDate;
      grouped.putIfAbsent(dateKey, () => []).add(measurement);
    }

    // Armazena no cache
    _cachedGroupedMeasurements = grouped;
    _lastProcessedMeasurements = widget.measurements;

    return grouped;
  }

  // OTIMIZAÇÃO 4: Ordenação lazy com cache
  List<String> _getSortedDates(Map<String, List<MeasurementModel>> groupedMeasurements) {
    if (_cachedSortedDates != null) {
      return _cachedSortedDates!;
    }

    final sortedDates = groupedMeasurements.keys.toList()
      ..sort((a, b) {
        final aDate = _parseDate(a);
        final bDate = _parseDate(b);
        return bDate.compareTo(aDate);
      });

    _cachedSortedDates = sortedDates;
    return sortedDates;
  }

  // Cache estático para cores de pressão
  static final Map<String, Color> _pressureColorCache = {};
  static final Map<String, String> _pressureClassificationCache = {};

  String _classifyPressure(int systolic, int diastolic) {
    final key = '$systolic-$diastolic';

    if (_pressureClassificationCache.containsKey(key)) {
      return _pressureClassificationCache[key]!;
    }

    String classification;
    if (systolic < 120 && diastolic < 80) {
      classification = 'Normal';
    } else if (systolic < 130 && diastolic < 80) {
      classification = 'Elevada';
    } else if (systolic < 140 || diastolic < 90) {
      classification = 'Hipertensão I';
    } else if (systolic < 180 || diastolic < 120) {
      classification = 'Hipertensão II';
    } else {
      classification = 'Crise Hipertensiva';
    }

    _pressureClassificationCache[key] = classification;
    return classification;
  }

  Color _getPressureColor(int systolic, int diastolic) {
    final key = '$systolic-$diastolic';

    if (_pressureColorCache.containsKey(key)) {
      return _pressureColorCache[key]!;
    }

    Color color;
    if (systolic < 120 && diastolic < 80) {
      color = Colors.green;
    } else if (systolic < 130 && diastolic < 80) {
      color = Colors.orange;
    } else if (systolic < 140 || diastolic < 90) {
      color = Colors.deepOrange;
    } else if (systolic < 180 || diastolic < 120) {
      color = Colors.red;
    } else {
      color = Colors.red.shade900;
    }

    _pressureColorCache[key] = color;
    return color;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.measurements.isEmpty) {
      return _buildEmptyState();
    }

    // Usa cache para agrupamento e ordenação
    final groupedMeasurements = _getGroupedMeasurements();
    final sortedDates = _getSortedDates(groupedMeasurements);

    return RefreshIndicator(
      onRefresh: () async {
        _invalidateCache(); // Limpa cache no refresh
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onLoadMeasurements();
      },
      color: AppConstants.primaryColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedDates.length,
        // OTIMIZAÇÃO 5: Cache extent para melhor performance
        cacheExtent: 600,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dayMeasurements = groupedMeasurements[date]!;

          // Ordena medições do dia por hora (mais recente primeiro)
          if (dayMeasurements.length > 1) {
            dayMeasurements.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
          }

          return _buildDateSection(date, dayMeasurements, index < sortedDates.length - 1);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: AppConstants.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma medição encontrada',
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.selectedPeriod != 'all'
                ? 'Tente alterar o período do filtro'
                : 'Adicione sua primeira medição',
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary.withOpacity(0.7),
            ),
          ),
          if (widget.selectedPeriod != 'all') ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => widget.onPeriodChange('all'),
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Limpar filtro'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                side: const BorderSide(color: AppConstants.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // OTIMIZAÇÃO 6: Widget separado para cada seção de data
  Widget _buildDateSection(String date, List<MeasurementModel> dayMeasurements, bool showSpacer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateHeader(date, dayMeasurements.length),
        // OTIMIZAÇÃO 7: ListView.builder para listas grandes
        ...dayMeasurements.map((measurement) => _MeasurementCard(
          key: ValueKey(measurement.id), // Key para performance
          measurement: measurement,
          onTap: () => _showMeasurementDetails(measurement),
          onEdit: () => widget.onEditMeasurement(measurement),
          onDelete: () => widget.onDeleteMeasurement(measurement),
          classification: _classifyPressure(measurement.systolic, measurement.diastolic),
          pressureColor: _getPressureColor(measurement.systolic, measurement.diastolic),
        )),
        if (showSpacer) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDateHeader(String date, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ${count == 1 ? 'medição' : 'medições'}',
            style: TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showMeasurementDetails(MeasurementModel measurement) {
    final classification = _classifyPressure(measurement.systolic, measurement.diastolic);
    final pressureColor = _getPressureColor(measurement.systolic, measurement.diastolic);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MeasurementDetailsModal(
        measurement: measurement,
        classification: classification,
        pressureColor: pressureColor,
        onEdit: () {
          Navigator.pop(context);
          widget.onEditMeasurement(measurement);
        },
        onDelete: () {
          Navigator.pop(context);
          widget.onDeleteMeasurement(measurement);
        },
      ),
    );
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }
    return DateTime.now();
  }
}

// OTIMIZAÇÃO 8: Widget separado para o card de medição
class _MeasurementCard extends StatelessWidget {
  final MeasurementModel measurement;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String classification;
  final Color pressureColor;

  const _MeasurementCard({
    Key? key,
    required this.measurement,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.classification,
    required this.pressureColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Indicador de pressão
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: pressureColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
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
                          const SizedBox(width: 4),
                          const Text(
                            'mmHg',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Badge de classificação
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: pressureColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              classification,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: pressureColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Hora
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppConstants.textSecondary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            measurement.formattedTime,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppConstants.textSecondary.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Batimentos
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${measurement.heartRate} bpm',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppConstants.textSecondary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Ações
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: 20,
                      color: Colors.blue.shade600,
                      onPressed: onEdit,
                      tooltip: 'Editar',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 20,
                      color: Colors.red.shade600,
                      onPressed: onDelete,
                      tooltip: 'Excluir',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// OTIMIZAÇÃO 9: Modal de detalhes como widget separado
class _MeasurementDetailsModal extends StatelessWidget {
  final MeasurementModel measurement;
  final String classification;
  final Color pressureColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MeasurementDetailsModal({
    Key? key,
    required this.measurement,
    required this.classification,
    required this.pressureColor,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: pressureColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalhes da Medição',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${measurement.formattedDate} às ${measurement.formattedTime}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Dados
          _buildDetailRow('Pressão Sistólica', '${measurement.systolic} mmHg'),
          _buildDetailRow('Pressão Diastólica', '${measurement.diastolic} mmHg'),
          _buildDetailRow('Batimentos Cardíacos', '${measurement.heartRate} bpm'),
          _buildDetailRow('Classificação', classification, valueColor: pressureColor),
          const SizedBox(height: 20),
          // Ações
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Excluir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}