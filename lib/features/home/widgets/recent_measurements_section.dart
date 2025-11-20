import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/measurement_model.dart';
import '../widgets/measurement_card.dart';

class RecentMeasurementsSection extends StatelessWidget {
  final List<MeasurementModel> measurements;
  final VoidCallback onNavigateToHistory;

  const RecentMeasurementsSection({
    super.key,
    required this.measurements,
    required this.onNavigateToHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Últimas Medições',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            TextButton(
              onPressed: onNavigateToHistory,
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        measurements.isEmpty
            ? _buildEmpty()
            : _buildList(),
      ],
    );
  }

  Widget _buildEmpty() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.add_circle_outline,
                  size: 48,
                  color: AppConstants.primaryColor.withOpacity(0.5)),
              const SizedBox(height: 12),
              const Text(
                'Nenhuma medição registrada',
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toque no botão + para adicionar sua primeira medição',
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: measurements.length * 2 - 1,
      itemBuilder: (context, index) {
        if (index.isOdd) return const SizedBox(height: 8);

        final i = index ~/ 2;
        return MeasurementCard(measurement: measurements[i]);
      },
    );
  }
}