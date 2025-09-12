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

  // Performance: Cache para evitar recalcular dimensões
  late double _chartHeight;
  late double _minChartWidth;
  late double _itemWidth;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateDimensions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Performance: Calcula dimensões baseado no tamanho da tela
  void _calculateDimensions() {
    final size = MediaQuery.of(context).size;
    // Altura responsiva: 35% da altura da tela, mínimo 200, máximo 400
    _chartHeight = (size.height * 0.20).clamp(180.0, 200.0);
    // Largura mínima igual à largura da tela
    _minChartWidth = size.width;
    // Largura por item: responsiva, mínimo 50, máximo 100
    _itemWidth = (size.width / 6.0).clamp(50.0, 100.0);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels <= 200.0 &&
        !_isLoadingMore &&
        _currentIndex + _itemsPerPage < widget.measurements.length) {
      _loadMoreMeasurements();
    }
  }

  void _loadMoreMeasurements() {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    // Performance: Reduzido delay para melhor UX
    Future.delayed(const Duration(milliseconds: 200), () {
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
      return const Center(
        child: Text(
          'Nenhuma medição para exibir',
          style: TextStyle(fontSize: 16, color: AppConstants.textSecondary),
        ),
      );
    }

    final allReversed = widget.measurements.reversed.toList();
    final take = min(_currentIndex + _itemsPerPage, allReversed.length);
    final displayedMeasurements = allReversed.take(take).toList();

    return Column(
      children: [
        _buildChartControls(),
        Expanded(
          child: _buildResponsiveChart(displayedMeasurements),
        ),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResponsiveChart(List<MeasurementModel> displayedMeasurements) {
    // Performance: Calcula largura dinâmica com limites
    final calculatedWidth = _itemWidth * displayedMeasurements.length.toDouble();
    final chartWidth = max(_minChartWidth, calculatedWidth);

    return Container(
      height: _chartHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        reverse: true,
        child: Container(
          width: chartWidth,
          constraints: BoxConstraints(
            minWidth: _minChartWidth,
            maxWidth: double.infinity,
            minHeight: _chartHeight,
            maxHeight: _chartHeight,
          ),
          child: LineChart(
            _buildLineChartData(displayedMeasurements),
          ),
        ),
      ),
    );
  }

  Widget _buildChartControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1.0,
            blurRadius: 3.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Gráfico de Medições',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Batimentos',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: widget.showHeartRate,
                onChanged: widget.onToggleHeartRate,
                activeColor: AppConstants.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(List<MeasurementModel> measurements) {
    // Performance: Cache dos valores máximos e mínimos - convertendo para double desde o início
    final systolicValues = measurements.map((m) => m.systolic.toDouble()).toList();
    final diastolicValues = measurements.map((m) => m.diastolic.toDouble()).toList();
    final heartRateValues = measurements.map((m) => m.heartRate.toDouble()).toList();

    final allValues = <double>[
      ...systolicValues,
      ...diastolicValues,
      if (widget.showHeartRate) ...heartRateValues,
    ];

    final double minY;
    final double maxY;

    if (allValues.isEmpty) {
      minY = 0.0;
      maxY = 200.0;
    } else {
      final minValue = allValues.reduce(min);
      final maxValue = allValues.reduce(max);
      minY = (minValue - 10.0).clamp(0.0, double.infinity);
      maxY = maxValue + 10.0;
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        touchSpotThreshold: 30.0, // Performance: Área maior para touch
        touchTooltipData: LineTouchTooltipData(
          tooltipBorderRadius: BorderRadius.circular(8.0),
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          tooltipMargin: 8.0,
          maxContentWidth: 200.0, // Performance: Limita largura do tooltip
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
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
        drawVerticalLine: measurements.length <= 10, // Performance: Remove grid vertical se muitos pontos
        horizontalInterval: (maxY - minY) / 5.0, // Grid dinâmico
        verticalInterval: measurements.length > 5 ? 2.0 : 1.0,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppConstants.primaryColor.withOpacity(0.1),
            strokeWidth: 1.0,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: AppConstants.primaryColor.withOpacity(0.1),
            strokeWidth: 1.0,
          );
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32.0,
            interval: _calculateBottomTitleInterval(measurements.length),
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index < 0 || index >= measurements.length) {
                return const SizedBox.shrink();
              }

              // Performance: Mostra apenas alguns rótulos se há muitos pontos
              if (measurements.length > 10 && index % 2 != 0) {
                return const SizedBox.shrink();
              }

              return Transform.rotate(
                angle: measurements.length > 6 ? -0.5 : 0.0,
                child: Text(
                  _formatDateForAxis(measurements[index].formattedDate),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45.0,
            interval: _calculateLeftTitleInterval(minY, maxY),
            getTitlesWidget: (double value, TitleMeta meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
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
          width: 1.0,
        ),
      ),
      lineBarsData: [
        _buildLineChartBarData(
          systolicValues,
          AppConstants.primaryColor,
          'Sistólica',
        ),
        _buildLineChartBarData(
          diastolicValues,
          Colors.green,
          'Diastólica',
        ),
        if (widget.showHeartRate)
          _buildLineChartBarData(
            heartRateValues,
            Colors.red,
            'Batimentos',
          ),
      ],
      minX: 0.0,
      maxX: (measurements.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
    );
  }

  // Performance: Calcula intervalo dinâmico para títulos
  double _calculateBottomTitleInterval(int length) {
    if (length <= 5) return 1.0;
    if (length <= 10) return 2.0;
    return (length.toDouble() / 5.0).ceilToDouble();
  }

  double _calculateLeftTitleInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 50.0) return 10.0;
    if (range <= 100.0) return 20.0;
    return 30.0;
  }

  // Performance: Formata data de forma mais concisa
  String _formatDateForAxis(String originalDate) {
    try {
      final parts = originalDate.split('/');
      if (parts.length >= 2) {
        return '${parts[0]}/${parts[1]}'; // dd/MM
      }
    } catch (e) {
      // Fallback
    }
    return originalDate.substring(0, min(5, originalDate.length));
  }

  LineChartBarData _buildLineChartBarData(
      List<double> spots,
      Color color,
      String label,
      ) {
    final flSpots = spots.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return LineChartBarData(
      spots: flSpots,
      isCurved: true,
      curveSmoothness: 0.3, // Performance: Reduz suavização
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: spots.length <= 20, // Performance: Oculta pontos se muitos dados
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3.0,
            color: color,
            strokeWidth: 1.0,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
      // Performance: Reduz densidade de pontos se necessário
      preventCurveOverShooting: true,
    );
  }
}