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

class _MeasurementsChartTabState extends State<MeasurementsChartTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late List<double> _systolicValues;
  late List<double> _diastolicValues;
  late List<double> _heartRateValues;
  late double _minY;
  late double _maxY;
  late List<MeasurementModel> _displayData;

  int _startIndex = 0;
  final int _maxVisiblePoints = 15;
  bool _showAllData = false;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void didUpdateWidget(MeasurementsChartTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.measurements != widget.measurements ||
        oldWidget.showHeartRate != widget.showHeartRate) {
      _processData();
    }
  }

  void _processData() {
    if (widget.measurements.isEmpty) {
      _displayData = [];
      return;
    }

    final sorted = List<MeasurementModel>.from(widget.measurements)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    if (_showAllData || sorted.length <= _maxVisiblePoints) {
      _displayData = sorted;
      _startIndex = 0;
    } else {
      _startIndex = max(0, sorted.length - _maxVisiblePoints);
      _displayData = sorted.sublist(_startIndex);
    }

    _systolicValues = _displayData.map((m) => m.systolic.toDouble()).toList();
    _diastolicValues = _displayData.map((m) => m.diastolic.toDouble()).toList();
    _heartRateValues = _displayData.map((m) => m.heartRate.toDouble()).toList();

    _calculateYBounds();
  }

  void _calculateYBounds() {
    if (_displayData.isEmpty) {
      _minY = 0;
      _maxY = 200;
      return;
    }

    final allValues = [
      ..._systolicValues,
      ..._diastolicValues,
      if (widget.showHeartRate) ..._heartRateValues,
    ];

    if (allValues.isNotEmpty) {
      final minVal = allValues.reduce(min);
      final maxVal = allValues.reduce(max);
      final range = maxVal - minVal;
      _minY = (minVal - range * 0.1).clamp(0, double.infinity);
      _maxY = maxVal + range * 0.1;
    } else {
      _minY = 0;
      _maxY = 200;
    }
  }

  void _toggleDataView() {
    setState(() {
      _showAllData = !_showAllData;
      _processData();
    });
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
              Icons.show_chart,
              size: 64,
              color: AppConstants.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma medição para exibir',
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione medições para ver o gráfico',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Evolução das Medições',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatsText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.showHeartRate
                          ? Colors.red.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: widget.showHeartRate ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BPM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: widget.showHeartRate ? Colors.red : Colors.grey,
                          ),
                        ),
                        Switch(
                          value: widget.showHeartRate,
                          onChanged: widget.onToggleHeartRate,
                          activeColor: Colors.red,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.measurements.length > _maxVisiblePoints) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDataViewToggle(),
                    const Spacer(),
                    Text(
                      _showAllData
                          ? 'Mostrando todas as ${widget.measurements.length} medições'
                          : 'Mostrando últimas $_maxVisiblePoints medições',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        _buildLegend(),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
            child: _buildChart(),
          ),
        ),
      ],
    );
  }

  Widget _buildDataViewToggle() {
    return InkWell(
      onTap: _toggleDataView,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppConstants.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showAllData ? Icons.zoom_in : Icons.zoom_out,
              size: 16,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              _showAllData ? 'Ver menos' : 'Ver tudo',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Sistólica', AppConstants.primaryColor),
          const SizedBox(width: 24),
          _buildLegendItem('Diastólica', Colors.green),
          if (widget.showHeartRate) ...[
            const SizedBox(width: 24),
            _buildLegendItem('BPM', Colors.red),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        lineTouchData: _buildTouchData(),
        gridData: _buildGridData(),
        titlesData: _buildTitlesData(),
        borderData: _buildBorderData(),
        lineBarsData: _buildLineBarsData(),
        minX: 0,
        maxX: (_displayData.length - 1).toDouble(),
        minY: _minY,
        maxY: _maxY,
        clipData: const FlClipData.all(),
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  //toltip
  LineTouchData _buildTouchData() {
    return LineTouchData(
      enabled: true,
      touchSpotThreshold: 20,
      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
        return spotIndexes.map((index) {
          return TouchedSpotIndicatorData(
            const FlLine(
              color: Colors.grey,
              strokeWidth: 2,
              dashArray: [5, 5],
            ),
            FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
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
        tooltipBorderRadius: BorderRadius.circular(8),
        getTooltipColor: (touchedSpot) => Colors.black87,
        tooltipPadding: const EdgeInsets.all(8),
        tooltipMargin: 12,
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          return touchedSpots.map((LineBarSpot touchedSpot) {
            final index = touchedSpot.spotIndex;
            if (index < 0 || index >= _displayData.length) {
              return null;
            }

            final measurement = _displayData[index];
            final lines = <String>[
              '${measurement.formattedDate} ${measurement.formattedTime}',
            ];

            if (touchedSpot.barIndex == 0) {
              lines.add('Sistólica: ${measurement.systolic} mmHg');
            } else if (touchedSpot.barIndex == 1) {
              lines.add('Diastólica: ${measurement.diastolic} mmHg');
            } else if (touchedSpot.barIndex == 2 && widget.showHeartRate) {
              lines.add('Batimentos: ${measurement.heartRate} bpm');
            }

            return LineTooltipItem(
              lines.join('\n'),
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList();
        },
      ),
    );
  }


  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: _displayData.length <= 10,
      horizontalInterval: (_maxY - _minY) / 6,
      verticalInterval: 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Colors.grey.withOpacity(0.15),
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: Colors.grey.withOpacity(0.15),
          strokeWidth: 1,
        );
      },
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          interval: _calculateXInterval(),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= _displayData.length) {
              return const SizedBox.shrink();
            }
            if (_displayData.length > 7 && index % 2 != 0) {
              return const SizedBox.shrink();
            }
            final measurement = _displayData[index];
            final date = measurement.formattedDate.split('/');
            return Text(
              '${date[0]}/${date[1]}',
              style: const TextStyle(
                fontSize: 10,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: _calculateYInterval(),
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: const TextStyle(
                fontSize: 10,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            );
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

  List<LineChartBarData> _buildLineBarsData() {
    return [
      LineChartBarData(
        spots: _systolicValues.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value);
        }).toList(),
        isCurved: true,
        curveSmoothness: 0.3,
        color: AppConstants.primaryColor,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: AppConstants.primaryColor,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: AppConstants.primaryColor.withOpacity(0.1),
        ),
      ),
      LineChartBarData(
        spots: _diastolicValues.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value);
        }).toList(),
        isCurved: true,
        curveSmoothness: 0.3,
        color: Colors.green,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: Colors.green,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.green.withOpacity(0.1),
        ),
      ),
      if (widget.showHeartRate)
        LineChartBarData(
          spots: _heartRateValues.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value);
          }).toList(),
          isCurved: true,
          curveSmoothness: 0.3,
          color: Colors.red,
          barWidth: 2,
          isStrokeCapRound: true,
          dashArray: [5, 3],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 2.5,
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

  double _calculateXInterval() {
    if (_displayData.length <= 5) return 1;
    if (_displayData.length <= 10) return 2;
    return (_displayData.length / 4).ceilToDouble();
  }

  double _calculateYInterval() {
    final range = _maxY - _minY;
    if (range <= 30) return 5;
    if (range <= 60) return 10;
    if (range <= 120) return 20;
    return 30;
  }

  String _getStatsText() {
    if (_displayData.isEmpty) return '';
    final avgSystolic = (_systolicValues.reduce((a, b) => a + b) / _systolicValues.length).round();
    final avgDiastolic = (_diastolicValues.reduce((a, b) => a + b) / _diastolicValues.length).round();
    return 'Média: $avgSystolic/$avgDiastolic mmHg';
  }
}