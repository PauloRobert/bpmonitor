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
  // Performance: Mantém o estado ao trocar de tabs
  @override
  bool get wantKeepAlive => true;

  // Helper para classificar pressão
  String _classifyPressure(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) {
      return 'Normal';
    } else if (systolic < 130 && diastolic < 80) {
      return 'Elevada';
    } else if (systolic < 140 || diastolic < 90) {
      return 'Hipertensão I';
    } else if (systolic < 180 || diastolic < 120) {
      return 'Hipertensão II';
    } else {
      return 'Crise Hipertensiva';
    }
  }

  Color _getPressureColor(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) {
      return Colors.green;
    } else if (systolic < 130 && diastolic < 80) {
      return Colors.orange;
    } else if (systolic < 140 || diastolic < 90) {
      return Colors.deepOrange;
    } else if (systolic < 180 || diastolic < 120) {
      return Colors.red;
    } else {
      return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.measurements.isEmpty) {
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

    // Agrupa medições por data
    final groupedMeasurements = <String, List<MeasurementModel>>{};
    for (final measurement in widget.measurements) {
      final dateKey = measurement.formattedDate;
      groupedMeasurements.putIfAbsent(dateKey, () => []).add(measurement);
    }

    // Ordena as datas (mais recente primeiro)
    final sortedDates = groupedMeasurements.keys.toList()
      ..sort((a, b) {
        final aDate = _parseDate(a);
        final bDate = _parseDate(b);
        return bDate.compareTo(aDate);
      });

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onLoadMeasurements();
      },
      color: AppConstants.primaryColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dayMeasurements = groupedMeasurements[date]!;

          // Ordena medições do dia por hora (mais recente primeiro)
          dayMeasurements.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header da data
              Container(
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
                      '${dayMeasurements.length} ${dayMeasurements.length == 1 ? 'medição' : 'medições'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de medições do dia
              ...dayMeasurements.map((measurement) => _buildMeasurementCard(measurement)),
              if (index < sortedDates.length - 1) const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMeasurementCard(MeasurementModel measurement) {
    final classification = _classifyPressure(measurement.systolic, measurement.diastolic);
    final pressureColor = _getPressureColor(measurement.systolic, measurement.diastolic);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: () => _showMeasurementDetails(measurement),
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
                          // Valores de pressão
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
                      onPressed: () => widget.onEditMeasurement(measurement),
                      tooltip: 'Editar',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 20,
                      color: Colors.red.shade600,
                      onPressed: () => widget.onDeleteMeasurement(measurement),
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

  void _showMeasurementDetails(MeasurementModel measurement) {
    final classification = _classifyPressure(measurement.systolic, measurement.diastolic);
    final pressureColor = _getPressureColor(measurement.systolic, measurement.diastolic);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onEditMeasurement(measurement);
                    },
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
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDeleteMeasurement(measurement);
                    },
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