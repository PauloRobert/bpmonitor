import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/measurement_model.dart';
import '../../shared/models/user_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  final db = DatabaseService.instance;

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _chartController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _chartAnimation;

  // Data
  List<MeasurementModel> _measurements = [];
  UserModel? _user;
  bool _isLoading = true;

  // Report Data
  Map<String, dynamic> _reportData = {};

  // Selected Period
  String _selectedPeriod = 'month';
  final Map<String, String> _periods = {
    'week': 'Última semana',
    'month': 'Último mês',
    '3months': 'Últimos 3 meses',
    'year': 'Último ano',
    'all': 'Todo período',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final measurements = await db.getAllMeasurements();
      final user = await db.getUser();

      setState(() {
        _measurements = measurements;
        _user = user;
      });

      _generateReportData();
      _startAnimations();

    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar dados dos relatórios', e, stackTrace);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _chartController.forward();
    });
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

    // Estatísticas básicas
    final systolicValues = filteredMeasurements.map((m) => m.systolic).toList();
    final diastolicValues = filteredMeasurements.map((m) => m.diastolic).toList();
    final heartRateValues = filteredMeasurements.map((m) => m.heartRate).toList();

    // Médias
    final avgSystolic = systolicValues.reduce((a, b) => a + b) / systolicValues.length;
    final avgDiastolic = diastolicValues.reduce((a, b) => a + b) / diastolicValues.length;
    final avgHeartRate = heartRateValues.reduce((a, b) => a + b) / heartRateValues.length;

    // Extremos
    final maxSystolic = systolicValues.reduce(math.max);
    final minSystolic = systolicValues.reduce(math.min);
    final maxDiastolic = diastolicValues.reduce(math.max);
    final minDiastolic = diastolicValues.reduce(math.min);
    final maxHeartRate = heartRateValues.reduce(math.max);
    final minHeartRate = heartRateValues.reduce(math.min);

    // Distribuição por categorias
    final categoryDistribution = <String, int>{};
    for (final measurement in filteredMeasurements) {
      final category = measurement.category;
      categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;
    }

    // Tendência (últimas 5 medições vs primeiras 5)
    String trend = 'stable';
    if (filteredMeasurements.length >= 10) {
      final recent = filteredMeasurements.take(5).map((m) => m.systolic).toList();
      final older = filteredMeasurements.skip(filteredMeasurements.length - 5).map((m) => m.systolic).toList();

      final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
      final olderAvg = older.reduce((a, b) => a + b) / older.length;

      if (recentAvg > olderAvg + 5) {
        trend = 'increasing';
      } else if (recentAvg < olderAvg - 5) {
        trend = 'decreasing';
      }
    }

    // Horários mais comuns de medição
    final hourDistribution = <int, int>{};
    for (final measurement in filteredMeasurements) {
      final hour = measurement.measuredAt.hour;
      hourDistribution[hour] = (hourDistribution[hour] ?? 0) + 1;
    }

    final mostCommonHour = hourDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    _reportData = {
      'totalMeasurements': filteredMeasurements.length,
      'period': _selectedPeriod,
      'averages': {
        'systolic': avgSystolic,
        'diastolic': avgDiastolic,
        'heartRate': avgHeartRate,
      },
      'extremes': {
        'maxSystolic': maxSystolic,
        'minSystolic': minSystolic,
        'maxDiastolic': maxDiastolic,
        'minDiastolic': minDiastolic,
        'maxHeartRate': maxHeartRate,
        'minHeartRate': minHeartRate,
      },
      'categoryDistribution': categoryDistribution,
      'trend': trend,
      'mostCommonHour': mostCommonHour,
      'measurements': filteredMeasurements,
    };
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

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _generateReportData();
    _chartController.reset();
    _chartController.forward();
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
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      // Padding para evitar que o conteúdo fique atrás do menu inferior
      body: SafeArea(
        bottom: true, // Garante espaço na parte inferior
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
        // AppBar simplificada e fixa
        _buildAppBar(),

        // Seletor de período redesenhado
        _buildPeriodSelector(),

        // Conteúdo principal com scroll
        Expanded(
          child: _reportData.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Padding extra no fundo
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Primeiro o card de tendência conforme solicitado
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
                // Espaço extra no final para garantir que nada fique escondido pelo menu
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
      height: 120,
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Relatório de Saúde',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          // Nome do usuário removido conforme solicitado
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
        elevation: 3, // Elevação maior para destaque
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

              // Descrição adicional para destacar o card de tendência
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

  // Função adicional para descrição da tendência
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

                  // Determinar cor baseado na categoria
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade de export PDF em desenvolvimento'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
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
}