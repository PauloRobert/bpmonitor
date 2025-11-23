import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/measurement_model.dart';

class WeeklyAverageCard extends StatelessWidget {
  final Map<String, double> weeklyAverage;
  final VoidCallback onAddMeasurement;

  const WeeklyAverageCard({
    super.key,
    required this.weeklyAverage,
    required this.onAddMeasurement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppConstants.primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Média da Última Semana',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            weeklyAverage.isEmpty
                ? _buildNoData()
                : _buildAverageData(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: AppConstants.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              AppConstants.noDataMessage,
              style: TextStyle(fontSize: 14, color: AppConstants.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAddMeasurement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Adicionar 1ª Medição'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageData() {
    final systolic = weeklyAverage['systolic']!.round();
    final diastolic = weeklyAverage['diastolic']!.round();
    final heartRate = weeklyAverage['heartRate']!.round();

    final tempMeasurement = MeasurementModel(
      systolic: systolic,
      diastolic: diastolic,
      heartRate: heartRate,
      measuredAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _metric('Sistólica', systolic, 'mmHg'),
            _divider(),
            _metric('Diastólica', diastolic, 'mmHg'),
            _divider(),
            _metric('Batimentos', heartRate, 'bpm'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tempMeasurement.categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tempMeasurement.categoryColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            'Pressão ${tempMeasurement.categoryName}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tempMeasurement.categoryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, int value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary)),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 10, color: AppConstants.textSecondary)),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: AppConstants.textSecondary.withOpacity(0.3),
    );
  }
}