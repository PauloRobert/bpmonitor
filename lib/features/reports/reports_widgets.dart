/// ============================================================================
/// ReportsWidgets
/// ============================================================================
/// - Widgets reutilizáveis para a tela de relatórios
/// - Responsáveis apenas pela apresentação visual
/// - Otimizados para performance com widgets const quando possível
/// ============================================================================

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/measurement_model.dart';

class ReportsWidgets {

  /// Header da tela com gradiente
  static Widget buildAppBar() {
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
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 8),
          Text(
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

  /// Seletor de período horizontal
  static Widget buildPeriodSelector({
    required Map<String, String> periods,
    required String selectedPeriod,
    required Function(String) onPeriodChanged,
  }) {
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
          children: periods.keys.map((period) {
            final isSelected = period == selectedPeriod;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onPeriodChanged(period),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppConstants.primaryColor : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    periods[period]!,
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

  /// Estado vazio quando não há dados
  static Widget buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EmptyStateIcon(),
            SizedBox(height: 24),
            Text(
              'Sem dados para relatório',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            SizedBox(height: 8),
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

  /// Card de resumo com médias
  static Widget buildSummaryCard({
    required Animation<double> animation,
    required Map<String, dynamic> reportData,
  }) {
    final totalMeasurements = reportData['totalMeasurements'] ?? 0;
    final averages = reportData['averages'] ?? {};

    return ScaleTransition(
      scale: animation,
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
              _buildSummaryHeader(totalMeasurements),
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

  /// Card de tendência com análise
  static Widget buildTrendCard({
    required Animation<double> animation,
    required Map<String, dynamic> reportData,
    required Map<String, String> periods,
    required String selectedPeriod,
  }) {
    final trend = reportData['trend'] ?? 'stable';
    final trendColor = _getTrendColor(trend);
    final trendIcon = _getTrendIcon(trend);
    final trendText = _getTrendText(trend);

    return ScaleTransition(
      scale: animation,
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
                      periods[selectedPeriod]!,
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
                  style: const TextStyle(
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

  /// Grid de estatísticas (maior/menor pressão)
  static Widget buildStatisticsGrid({
    required Animation<double> animation,
    required Map<String, dynamic> reportData,
  }) {
    final extremes = reportData['extremes'] ?? {};

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
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

  /// Card de distribuição por categorias
  static Widget buildCategoryDistribution({
    required Animation<double> animation,
    required Map<String, dynamic> reportData,
  }) {
    final distribution = reportData['categoryDistribution'] as Map<String, int>? ?? {};

    if (distribution.isEmpty) return const SizedBox.shrink();

    final total = distribution.values.reduce((a, b) => a + b);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryHeader(),
                const SizedBox(height: 12),
                ...distribution.entries.map((entry) {
                  return _buildCategoryItem(
                    entry.key,
                    entry.value,
                    (entry.value / total * 100).round(),
                    animation,
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Card de insights pessoais
  static Widget buildInsightsCard({
    required Animation<double> animation,
    required Map<String, dynamic> reportData,
  }) {
    final mostCommonHour = reportData['mostCommonHour'] ?? 12;
    final measurements = reportData['measurements'] as List<MeasurementModel>? ?? [];

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
      scale: animation,
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
              _buildInsightsHeader(),
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

  /// Botões de ação (PDF e Compartilhar) - CORRIGIDO
  static Widget buildActionButtons({
    required bool isLoading,
    required bool hasData,
    required VoidCallback onGeneratePDF,
    required VoidCallback onShare,
  }) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading || !hasData ? null : onGeneratePDF,
            icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
            label: const Text(
              'Gerar PDF',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onShare,
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

  // =================== WIDGETS PRIVADOS ===================

  static Widget _buildSummaryHeader(int totalMeasurements) {
    return Row(
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
              const Text(
                'Resumo',
                style: TextStyle(
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
    );
  }

  static Widget _buildSummaryItem(String label, String value, String unit, Color color, IconData icon) {
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

  static Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  static Widget _buildCategoryHeader() {
    return Row(
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
    );
  }

  static Widget _buildCategoryItem(String category, int count, int percentage, Animation<double> animation) {
    final categoryInfo = _getCategoryInfo(category);

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
                  color: categoryInfo['color'],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoryInfo['name'],
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
                  color: categoryInfo['color'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: animation.value * (percentage / 100),
            backgroundColor: categoryInfo['color'].withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(categoryInfo['color']),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  static Widget _buildInsightsHeader() {
    return Row(
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
    );
  }

  static Widget _buildInsightItem(IconData icon, String title, String description) {
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

  // =================== HELPERS ===================

  static Color _getTrendColor(String trend) {
    switch (trend) {
      case 'increasing':
        return AppConstants.dangerColor;
      case 'decreasing':
        return AppConstants.successColor;
      default:
        return AppConstants.primaryColor;
    }
  }

  static IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'increasing':
        return Icons.trending_up;
      case 'decreasing':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  static String _getTrendText(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Tendência de alta';
      case 'decreasing':
        return 'Tendência de baixa';
      default:
        return 'Estável';
    }
  }

  static String _getTrendDescription(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Sua pressão tem aumentado. Considere consultar um médico.';
      case 'decreasing':
        return 'Sua pressão está diminuindo. Continue acompanhando.';
      default:
        return 'Sua pressão está estável, continue monitorando regularmente.';
    }
  }

  static Map<String, dynamic> _getCategoryInfo(String category) {
    switch (category) {
      case 'optimal':
        return {
          'color': const Color(0xFF10B981),
          'name': 'Ótima',
        };
      case 'normal':
        return {
          'color': const Color(0xFF3B82F6),
          'name': 'Normal',
        };
      case 'elevated':
        return {
          'color': const Color(0xFFF59E0B),
          'name': 'Elevada',
        };
      case 'high_stage1':
        return {
          'color': const Color(0xFFEF4444),
          'name': 'Alta Estágio 1',
        };
      case 'high_stage2':
        return {
          'color': const Color(0xFFDC2626),
          'name': 'Alta Estágio 2',
        };
      case 'crisis':
        return {
          'color': const Color(0xFF7C3AED),
          'name': 'Crise',
        };
      default:
        return {
          'color': AppConstants.primaryColor,
          'name': 'Normal',
        };
    }
  }
}

// Widget const para ícone do estado vazio
class _EmptyStateIcon extends StatelessWidget {
  const _EmptyStateIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}