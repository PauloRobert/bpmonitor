import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/measurement_model.dart';

class MeasurementsListTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const Center(
        child: Text('Nenhuma medição encontrada'),
      );
    }

    return ListView.builder(
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final measurement = measurements[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(
              '${measurement.systolic}/${measurement.diastolic} mmHg',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            subtitle: Text(
              '${measurement.formattedDate} • Batimentos: ${measurement.heartRate}',
              style: const TextStyle(
                color: AppConstants.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEditMeasurement(measurement),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDeleteMeasurement(measurement),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}