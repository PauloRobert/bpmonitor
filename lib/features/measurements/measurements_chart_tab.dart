// measurements_chart_tab.dart - MAXIMIZADO PARA GRÁFICO
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/measurement_model.dart';
import 'dart:math';

class MeasurementsChartTab extends StatefulWidget {
  final List<MeasurementModel> measurements;
  final bool showHeartRate;
  final Function(bool) onToggleHeartRate;

  const MeasurementsChartTab({
    super.key,
    required this.measurements,
    required this.showHeartRate,
    required this.onToggleHeartRate,
  });

  @override
  State<MeasurementsChartTab> createState() => _MeasurementsChartTabState();
}

class _MeasurementsChartTabState extends State<MeasurementsChartTab> {
  int? _selectedSpotIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.measurements.isEmpty) {
      return _buildEmptyState();
    }

    final displayData = _getDisplayData();
    final chartData = _getChartData(displayData);

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20), // Padding mínimo
          margin: const EdgeInsets.only(bottom: 80), // Margem para navegação
          child: _buildChart(displayData, chartData),
        ),
        if (_selectedSpotIndex != null) _buildCustomTooltip(displayData),
      ],
    );
  }

  List<MeasurementModel> _getDisplayData() {
    if (widget.measurements.isEmpty) return [];

    final sorted = List<MeasurementModel>.from(widget.measurements)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    return sorted;
  }

  Map<String, dynamic> _getChartData(List<MeasurementModel> displayData) {
    if (displayData.isEmpty) {
      return {
        'systolicValues': <double>[],
        'diastolicValues': <double>[],
        'heartRateValues': <double>[],
        'minY': 40.0,
        'maxY': 200.0,
      };
    }

    final systolicValues = displayData.map((m) => m.systolic.toDouble()).toList();
    final diastolicValues = displayData.map((m) => m.diastolic.toDouble()).toList();
    final heartRateValues = displayData.map((m) => m.heartRate.toDouble()).toList();

    // Sempre inclui batimentos cardíacos nos cálculos
    final allValues = <double>[
      ...systolicValues,
      ...diastolicValues,
      ...heartRateValues,
    ];

    double minY = 40;
    double maxY = 200;

    if (allValues.isNotEmpty) {
      final minVal = allValues.reduce(min);
      final maxVal = allValues.reduce(max);
      final range = maxVal - minVal;

      minY = max(40, (minVal - range * 0.1).clamp(0, double.infinity));
      maxY = min(250, maxVal + range * 0.2);

      if (maxY - minY < 50) {
        final center = (maxY + minY) / 2;
        minY = max(40, center - 25);
        maxY = min(250, center + 25);
      }
    }

    return {
      'systolicValues': systolicValues,
      'diastolicValues': diastolicValues,
      'heartRateValues': heartRateValues,
      'minY': minY,
      'maxY': maxY,
    };
  }

  Widget _buildCustomTooltip(List<MeasurementModel> displayData) {
    if (_selectedSpotIndex == null ||
        _selectedSpotIndex! < 0 ||
        _selectedSpotIndex! >= displayData.length) {
      return const SizedBox.shrink();
    }

    final measurement = displayData[_selectedSpotIndex!];

    return Positioned(
      top: 30, // Mais próximo do topo
      right: 20,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSpotIndex = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${measurement.formattedDate} - ${measurement.formattedTime}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${measurement.systolic} x ${measurement.diastolic} mmHg',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${measurement.heartRate} bpm',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: measurement.categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: measurement.categoryColor, width: 1),
                ),
                child: Text(
                  measurement.categoryName,
                  style: TextStyle(
                    color: measurement.categoryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toque para fechar',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Nenhuma medição para exibir', style: TextStyle(fontSize: 16, color: AppConstants.textSecondary)),
          SizedBox(height: 8),
          Text('Adicione medições para ver o gráfico', style: TextStyle(fontSize: 14, color: AppConstants.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildChart(List<MeasurementModel> displayData, Map<String, dynamic> chartData) {
    return LineChart(
      LineChartData(
        lineTouchData: _buildTouchData(),
        gridData: _buildGridData(chartData),
        titlesData: _buildTitlesData(displayData, chartData),
        borderData: _buildBorderData(),
        lineBarsData: _buildLineBarsData(chartData),
        minX: 0,
        maxX: (displayData.length - 1).toDouble(),
        minY: chartData['minY'],
        maxY: chartData['maxY'],
        clipData: const FlClipData.all(),
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  LineTouchData _buildTouchData() {
    return LineTouchData(
      enabled: true,
      touchSpotThreshold: 25,
      touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
        if (event is FlTapUpEvent && response?.lineBarSpots?.isNotEmpty == true) {
          final spot = response!.lineBarSpots!.first;
          setState(() {
            _selectedSpotIndex = spot.spotIndex;
          });
        }
      },
      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
        return spotIndexes.map((index) {
          return TouchedSpotIndicatorData(
            const FlLine(color: Colors.grey, strokeWidth: 2, dashArray: [5, 5]),
            FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 8,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: barData.color ?? Colors.blue,
                );
              },
            ),
          );
        }).toList();
      },
      touchTooltipData: LineTouchTooltipData(
        showOnTopOfTheChartBoxArea: false,
        getTooltipItems: (touchedSpots) => [],
      ),
    );
  }

  FlGridData _buildGridData(Map<String, dynamic> chartData) {
    return FlGridData(
      show: true,
      drawVerticalLine: widget.measurements.length <= 10,
      horizontalInterval: (chartData['maxY'] - chartData['minY']) / 6,
      verticalInterval: 1,
      getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
      getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
    );
  }

  FlTitlesData _buildTitlesData(List<MeasurementModel> displayData, Map<String, dynamic> chartData) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 25, // Reduzido
          interval: _calculateXInterval(displayData),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= displayData.length) return const SizedBox.shrink();
            if (displayData.length > 7 && index % 2 != 0) return const SizedBox.shrink();

            final measurement = displayData[index];
            final date = measurement.formattedDate.split('/');
            return Padding(
              padding: const EdgeInsets.only(top: 2), // Reduzido
              child: Text('${date[0]}/${date[1]}', style: const TextStyle(fontSize: 9, color: AppConstants.textSecondary, fontWeight: FontWeight.w500)),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40, // Reduzido
          interval: _calculateYInterval(chartData),
          getTitlesWidget: (value, meta) {
            return Text(value.toInt().toString(), style: const TextStyle(fontSize: 9, color: AppConstants.textSecondary, fontWeight: FontWeight.w500));
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border(
        left: BorderSide(color: Colors.grey.shade300, width: 1),
        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData(Map<String, dynamic> chartData) {
    final systolicValues = chartData['systolicValues'] as List<double>;
    final diastolicValues = chartData['diastolicValues'] as List<double>;
    final heartRateValues = chartData['heartRateValues'] as List<double>;

    return [
      // Sistólica
      LineChartBarData(
        spots: systolicValues.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
        isCurved: true,
        curveSmoothness: 0.3,
        color: AppConstants.primaryColor,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            final isSelected = _selectedSpotIndex == index;
            return FlDotCirclePainter(
              radius: isSelected ? 6 : 4,
              color: AppConstants.primaryColor,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(show: true, color: AppConstants.primaryColor.withOpacity(0.1)),
      ),
      // Diastólica
      LineChartBarData(
        spots: diastolicValues.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
        isCurved: true,
        curveSmoothness: 0.3,
        color: Colors.green,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            final isSelected = _selectedSpotIndex == index;
            return FlDotCirclePainter(
              radius: isSelected ? 6 : 4,
              color: Colors.green,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
      ),
      // Batimentos (sempre visível)
      LineChartBarData(
        spots: heartRateValues.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
        isCurved: true,
        curveSmoothness: 0.3,
        color: Colors.red,
        barWidth: 2,
        isStrokeCapRound: true,
        dashArray: [5, 3],
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            final isSelected = _selectedSpotIndex == index;
            return FlDotCirclePainter(
              radius: isSelected ? 4 : 2.5,
              color: Colors.red,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(show: false),
      ),
    ];
  }

  double _calculateXInterval(List<MeasurementModel> displayData) {
    if (displayData.length <= 5) return 1;
    if (displayData.length <= 10) return 2;
    return (displayData.length / 4).ceilToDouble();
  }

  double _calculateYInterval(Map<String, dynamic> chartData) {
    final range = chartData['maxY'] - chartData['minY'];
    if (range <= 30) return 5;
    if (range <= 60) return 10;
    if (range <= 120) return 20;
    return 30;
  }
}