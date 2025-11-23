import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/measurement_model.dart';

class MeasurementCard extends StatelessWidget {
  final MeasurementModel measurement;

  const MeasurementCard({
    super.key,
    required this.measurement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: measurement.categoryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${measurement.systolic}/${measurement.diastolic}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${measurement.heartRate} bpm',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        measurement.formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        measurement.formattedTime,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: measurement.categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                measurement.categoryName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: measurement.categoryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}