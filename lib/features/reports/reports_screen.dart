import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/measurement_model.dart';
import '../../shared/models/user_model.dart';
import '../../features/reports/report_pdf_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true; // OTIMIZAÇÃO 1: Mantém estado

  final db = DatabaseService.instance;

  // OTIMIZAÇÃO 2: Apenas um AnimationController
  late AnimationController _masterController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _chartAnimation;

  // Data
  List<MeasurementModel> _measurements = [];
  UserModel? _user;
  bool _isLoading = true;

  // OTIMIZAÇÃO 3: Cache de dados processados
  Map<String, dynamic> _reportData = {};
  final Map<String, Map<String, dynamic>> _reportCache = {};
  Timer? _debounceTimer;

  // Selected Period
  String _selectedPeriod = 'month';
  final Map<String, String> _periods = {
    'week': 'Última semana',
    'month': 'Último mês',
    '3months': '3 meses',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDataOptimized();
  }

  void _initializeAnimations() {
    // OTIMIZAÇÃO 2: Um controller apenas com múltiplas animações
    _masterController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
    ));

    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));
  }

  @override
  void dispose() {
    _masterController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // OTIMIZAÇÃO 4: Carregamento paralelo com cache
  Future<void> _loadDataOptimized() async {
    setState(() => _isLoading = true);

    try {
      // Carregamento paralelo
      final results = await Future.wait([
        db.getAllMeasurements(),
        db.getUser(),
      ]);

      if (!mounted) return;

      setState(() {
        _measurements = results[0] as List<MeasurementModel>;
        _user = results[1] as UserModel?;
      });

      _generateReportDataWithCache();
      _masterController.forward();

    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar dados dos relatórios', e, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // OTIMIZAÇÃO 5: Cache inteligente para cálculos pesados
  void _generateReportDataWithCache() {
    // Verifica cache primeiro
    if (_reportCache.containsKey(_selectedPeriod)) {
      AppConstants.logInfo('Usando cache para relatório: $_selectedPeriod');
      setState(() {
        _reportData = _reportCache[_selectedPeriod]!;
      });
      return;
    }

    _generateReportData();
  }

  void _generateReportData() {
    if (_measurements.isEmpty) {
      _reportData = {};
      return;
    }

    final filteredMeasurements = _getFilteredMeasurements();

    if (filteredMeasurements.isEmpty) {
      _reportData = {};
      return;
    }

    // OTIMIZAÇÃO 6: Processamento otimizado em uma passada
    final stats = _calculateStatsOptimized(filteredMeasurements);

    // Distribuição por categorias
    final categoryDistribution = <String, int>{};
    for (final measurement in filteredMeasurements) {
      final category = measurement.category;
      categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;
    }

    // Tendência otimizada
    final trend = _calculateTrendOptimized(filteredMeasurements);

    // Horários mais comuns
    final hourDistribution = <int, int>{};
    for (final measurement in filteredMeasurements) {
      final hour = measurement.measuredAt.hour;
      hourDistribution[hour] = (hourDistribution[hour] ?? 0) + 1;
    }

    final mostCommonHour = hourDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final reportData = {
      'totalMeasurements': filteredMeasurements.length,
      'period': _selectedPeriod,
      'averages': stats['averages'],
      'extremes': stats['extremes'],
      'categoryDistribution': categoryDistribution,
      'trend': trend,
      'mostCommonHour': mostCommonHour,
      'measurements': filteredMeasurements,
    };

    // Armazena no cache (máximo 10 períodos)
    if (_reportCache.length >= 10) {
      _reportCache.clear();
    }
    _reportCache[_selectedPeriod] = reportData;

    setState(() {
      _reportData = reportData;
    });
  }

  // OTIMIZAÇÃO 7: Cálculo de estatísticas em uma única passada
  Map<String, dynamic> _calculateStatsOptimized(List<MeasurementModel> measurements) {
    if (measurements.isEmpty) {
      return {'averages': {}, 'extremes': {}};
    }

    double systolicSum = 0;
    double diastolicSum = 0;
    double heartRateSum = 0;

    int maxSystolic = measurements.first.systolic;
    int minSystolic = measurements.first.systolic;
    int maxDiastolic = measurements.first.diastolic;
    int minDiastolic = measurements.first.diastolic;
    int maxHeartRate = measurements.first.heartRate;
    int minHeartRate = measurements.first.heartRate;

    // Uma única passada para calcular tudo
    for (final measurement in measurements) {
      systolicSum += measurement.systolic;
      diastolicSum += measurement.diastolic;
      heartRateSum += measurement.heartRate;

      maxSystolic = math.max(maxSystolic, measurement.systolic);
      minSystolic = math.min(minSystolic, measurement.systolic);
      maxDiastolic = math.max(maxDiastolic, measurement.diastolic);
      minDiastolic = math.min(minDiastolic, measurement.diastolic);
      maxHeartRate = math.max(maxHeartRate, measurement.heartRate);
      minHeartRate = math.min(minHeartRate, measurement.heartRate);
    }

    final count = measurements.length;

    return {
      'averages': {
        'systolic': systolicSum / count,
        'diastolic': diastolicSum / count,
        'heartRate': heartRateSum / count,
      },
      'extremes': {
        'maxSystolic': maxSystolic,
        'minSystolic': minSystolic,
        'maxDiastolic': maxDiastolic,
        'minDiastolic': minDiastolic,
        'maxHeartRate': maxHeartRate,
        'minHeartRate': minHeartRate,
      },
    };
  }

  // OTIMIZAÇÃO 8: Cálculo de tendência otimizado
  String _calculateTrendOptimized(List<MeasurementModel> measurements) {
    if (measurements.length < 10) return 'stable';

    final sampleSize = math.min(5, measurements.length ~/ 2);

    double recentSum = 0;
    double olderSum = 0;

    for (int i = 0; i < sampleSize; i++) {
      recentSum += measurements[i].systolic;
      olderSum += measurements[measurements.length - 1 - i].systolic;
    }

    final recentAvg = recentSum / sampleSize;
    final olderAvg = olderSum / sampleSize;

    if (recentAvg > olderAvg + 5) {
      return 'increasing';
    } else if (recentAvg < olderAvg - 5) {
      return 'decreasing';
    }
    return 'stable';
  }

  List<MeasurementModel> _getFilteredMeasurements() {
    if (_selectedPeriod == 'all') return _measurements;

    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '3months':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case 'year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        return _measurements;
    }

    return _measurements.where((m) => m.measuredAt.isAfter(startDate)).toList();
  }

  // OTIMIZAÇÃO 9: Debounce para mudanças de período
  void _changePeriod(String period) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      setState(() {
        _selectedPeriod = period;
      });
      _generateReportDataWithCache();

      // Reinicia apenas a animação do chart
      _masterController.reset();
      _masterController.forward();
    });
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'increasing':
        return AppConstants.dangerColor;
      case 'decreasing':
        return AppConstants.successColor;
      default:
        return AppConstants.primaryColor;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'increasing':
        return Icons.trending_up;
      case 'decreasing':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  String _getTrendText(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Tendência de alta';
      case 'decreasing':
        return 'Tendência de baixa';
      default:
        return 'Estável';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Para AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        bottom: true,
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: AppConstants.primaryColor),
        )
            : FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildAppBar(),
        _buildPeriodSelector(),
        Expanded(
          child: _reportData.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildTrendCard(),
                const SizedBox(height: 16),
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildStatisticsGrid(),
                const SizedBox(height: 16),
                _buildCategoryDistribution(),
                const SizedBox(height: 16),
                _buildInsightsCard(),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Relatório de Saúde',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _periods.keys.map((period) {
            final isSelected = period == _selectedPeriod;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _changePeriod(period),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppConstants.primaryColor : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _periods[period]!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppConstants.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.insert_chart_outlined,
                size: 64,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sem dados para relatório',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione medições para gerar seu relatório de saúde',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalMeasurements = _reportData['totalMeasurements'] ?? 0;
    final averages = _reportData['averages'] ?? {};

    return ScaleTransition(
      scale: _chartAnimation,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppConstants.primaryColor.withOpacity(0.1),
                AppConstants.primaryColor.withOpacity(0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.summarize,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        Text(
                          '$totalMeasurements medições registradas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Sistólica',
                      '${averages['systolic']?.round() ?? 0}',
                      'mmHg',
                      Colors.red,
                      Icons.arrow_upward,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Diastólica',
                      '${averages['diastolic']?.round() ?? 0}',
                      'mmHg',
                      Colors.blue,
                      Icons.arrow_downward,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Batimentos',
                      '${averages['heartRate']?.round() ?? 0}',
                      'bpm',
                      Colors.pink,
                      Icons.favorite,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final extremes = _reportData['extremes'] ?? {};

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Maior Pressão',
                  '${extremes['maxSystolic'] ?? 0}/${extremes['maxDiastolic'] ?? 0}',
                  Icons.keyboard_arrow_up,
                  AppConstants.dangerColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Menor Pressão',
                  '${extremes['minSystolic'] ?? 0}/${extremes['minDiastolic'] ?? 0}',
                  Icons.keyboard_arrow_down,
                  AppConstants.successColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard() {
    final trend = _reportData['trend'] ?? 'stable';
    final trendColor = _getTrendColor(trend);
    final trendIcon = _getTrendIcon(trend);
    final trendText = _getTrendText(trend);

    return ScaleTransition(
      scale: _chartAnimation,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                trendColor.withOpacity(0.2),
                trendColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: trendColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(trendIcon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tendência',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        Text(
                          trendText,
                          style: TextStyle(
                            fontSize: 14,
                            color: trendColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _periods[_selectedPeriod]!,
                      style: TextStyle(
                        fontSize: 11,
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: trendColor.withOpacity(0.3)),
                ),
                child: Text(
                  _getTrendDescription(trend),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTrendDescription(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Sua pressão tem aumentado. Considere consultar um médico.';
      case 'decreasing':
        return 'Sua pressão está diminuindo. Continue acompanhando.';
      default:
        return 'Sua pressão está estável, continue monitorando regularmente.';
    }
  }

  Widget _buildCategoryDistribution() {
    final distribution = _reportData['categoryDistribution'] as Map<String, int>? ?? {};

    if (distribution.isEmpty) return const SizedBox.shrink();

    final total = distribution.values.reduce((a, b) => a + b);

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.pie_chart,
                        color: AppConstants.primaryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Distribuição por Categoria',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...distribution.entries.map((entry) {
                  final category = entry.key;
                  final count = entry.value;
                  final percentage = (count / total * 100).round();

                  Color color = AppConstants.primaryColor;
                  String categoryName = 'Normal';

                  switch (category) {
                    case 'optimal':
                      color = const Color(0xFF10B981);
                      categoryName = 'Ótima';
                      break;
                    case 'normal':
                      color = const Color(0xFF3B82F6);
                      categoryName = 'Normal';
                      break;
                    case 'elevated':
                      color = const Color(0xFFF59E0B);
                      categoryName = 'Elevada';
                      break;
                    case 'high_stage1':
                      color = const Color(0xFFEF4444);
                      categoryName = 'Alta Estágio 1';
                      break;
                    case 'high_stage2':
                      color = const Color(0xFFDC2626);
                      categoryName = 'Alta Estágio 2';
                      break;
                    case 'crisis':
                      color = const Color(0xFF7C3AED);
                      categoryName = 'Crise';
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                categoryName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _chartAnimation.value * (percentage / 100),
                          backgroundColor: color.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 4,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightsCard() {
    final mostCommonHour = _reportData['mostCommonHour'] ?? 12;
    final measurements = _reportData['measurements'] as List<MeasurementModel>? ?? [];

    // Calcular insights interessantes
    final morningMeasurements = measurements.where((m) => m.measuredAt.hour < 12).length;
    final afternoonMeasurements = measurements.where((m) => m.measuredAt.hour >= 12 && m.measuredAt.hour < 18).length;
    final eveningMeasurements = measurements.where((m) => m.measuredAt.hour >= 18).length;

    String preferredTime = 'manhã';
    if (afternoonMeasurements > morningMeasurements && afternoonMeasurements > eveningMeasurements) {
      preferredTime = 'tarde';
    } else if (eveningMeasurements > morningMeasurements && eveningMeasurements > afternoonMeasurements) {
      preferredTime = 'noite';
    }

    return ScaleTransition(
      scale: _chartAnimation,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppConstants.warningColor.withOpacity(0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.warningColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Insights Pessoais',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildInsightItem(
                Icons.schedule,
                'Horário preferido',
                'Você costuma medir sua pressão mais na $preferredTime',
              ),

              _buildInsightItem(
                Icons.access_time,
                'Horário mais comum',
                'Sua hora favorita é ${mostCommonHour}h',
              ),

              if (measurements.length > 10)
                _buildInsightItem(
                  Icons.trending_up,
                  'Consistência',
                  'Você tem um bom histórico com ${measurements.length} medições',
                ),

              _buildInsightItem(
                Icons.tips_and_updates,
                'Dica',
                'Meça sempre no mesmo horário para melhor precisão',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppConstants.warningColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 14, color: AppConstants.warningColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading || _reportData.isEmpty
                ? null
                : _generateAndSharePDF,
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Gerar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade de compartilhamento em desenvolvimento'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Compartilhar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateAndSharePDF() async {
    final loadingOverlay = _showLoadingOverlay(context);

    try {
      if (_user == null || _reportData.isEmpty) {
        _hideLoadingOverlay(loadingOverlay);
        _showErrorMessage('Dados insuficientes para gerar o relatório');
        return;
      }

      final periodLabel = _periods[_selectedPeriod] ?? 'Período personalizado';

      final pdfService = ReportPdfService();
      final pdfPath = await pdfService.generateHealthReport(
        user: _user!,
        measurements: _getFilteredMeasurements(),
        reportData: _reportData,
        periodLabel: periodLabel,
      );

      _hideLoadingOverlay(loadingOverlay);
      await pdfService.sharePdf(pdfPath);

    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao gerar PDF', e, stackTrace);
      _hideLoadingOverlay(loadingOverlay);
      _showErrorMessage('Ocorreu um erro ao gerar o PDF');
    }
  }

  OverlayEntry _showLoadingOverlay(BuildContext context) {
    final overlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppConstants.primaryColor),
                const SizedBox(height: 15),
                Text(
                  'Gerando PDF...',
                  style: TextStyle(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    return overlay;
  }

  void _hideLoadingOverlay(OverlayEntry overlay) {
    overlay.remove();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.dangerColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}