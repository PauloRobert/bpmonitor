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
  late ScrollController _scrollController;
  int _currentIndex = 0;
  final int _itemsPerPage = 6;
  bool _isLoadingMore = false;

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
    // Quando estiver próximo ao início (esquerda) do conteúdo, carregamos mais
    if (_scrollController.hasClients &&
        _scrollController.position.pixels <= 200 &&
        !_isLoadingMore &&
        _currentIndex + _itemsPerPage < widget.measurements.length) {
      _loadMoreMeasurements();
    }
  }

  void _loadMoreMeasurements() {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _currentIndex += _itemsPerPage;
        _isLoadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.measurements.isEmpty) {
      return const Center(child: Text('Nenhuma medição para exibir'));
    }

    // Lista com as últimas medições primeiro (invertida), e pega N items conforme página
    final allReversed = widget.measurements.reversed.toList();
    final take = min(_currentIndex + _itemsPerPage, allReversed.length);
    final displayedMeasurements = allReversed.take(take).toList();

    return Column(
      children: [
        _buildChartControls(),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            reverse: true, // abre mostrando as medições mais recentes (direita)
            child: SizedBox(
              width: 70.0 * displayedMeasurements.length,
              height: 300,
              child: LineChart(
                _buildLineChartData(displayedMeasurements),
              ),
            ),
          ),
        ),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildChartControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Gráfico de Medições',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              const Text('Batimentos Cardíacos'),
              Switch(
                value: widget.showHeartRate,
                onChanged: widget.onToggleHeartRate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(List<MeasurementModel> measurements) {
    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          // substitui o (removido) tooltipRoundedRadius
          tooltipBorderRadius: BorderRadius.circular(8.0),
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            // touchedSpots pode conter pontos de várias linhas; mapeamos em itens de tooltip
            return touchedSpots.map((touchedSpot) {
              final index = touchedSpot.spotIndex;
              if (index < 0 || index >= measurements.length) {
                return null;
              }
              final measurement = measurements[index];
              final lines = StringBuffer();
              lines.writeln(measurement.formattedDate);
              lines.writeln('Sistólica: ${measurement.systolic}');
              lines.writeln('Diastólica: ${measurement.diastolic}');
              if (widget.showHeartRate) {
                lines.writeln('Batimentos: ${measurement.heartRate}');
              }
              return LineTooltipItem(
                lines.toString(),
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).whereType<LineTooltipItem>().toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppConstants.primaryColor.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: AppConstants.primaryColor.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index < 0 || index >= measurements.length) {
                return const Text('');
              }
              return Text(
                measurements[index].formattedDate,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textSecondary,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 20,
            getTitlesWidget: (double value, TitleMeta meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textSecondary,
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      lineBarsData: [
        _buildLineChartBarData(
          measurements.map((m) => m.systolic.toDouble()).toList(),
          AppConstants.primaryColor,
        ),
        _buildLineChartBarData(
          measurements.map((m) => m.diastolic.toDouble()).toList(),
          Colors.green,
        ),
        if (widget.showHeartRate)
          _buildLineChartBarData(
            measurements.map((m) => m.heartRate.toDouble()).toList(),
            Colors.red,
          ),
      ],
      minX: 0,
      maxX: (measurements.length - 1).toDouble(),
      minY: 0,
      maxY: 200,
    );
  }

  LineChartBarData _buildLineChartBarData(List<double> spots, Color color) {
    final flSpots = spots.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return LineChartBarData(
      spots: flSpots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: color,
            strokeWidth: 1,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}