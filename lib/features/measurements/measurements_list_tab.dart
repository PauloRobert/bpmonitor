import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/measurement_model.dart';
import 'dart:math';

class MeasurementsChartTab extends StatelessWidget {
  final List<MeasurementModel> measurements;

  const MeasurementsChartTab({
    super.key,
    required this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
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
                      color: AppConstants.primaryColor.withOpacity(0.1),
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
    if (measurements.isEmpty) return const SizedBox.shrink();
    final data = measurements;
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