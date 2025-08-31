import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/measurement_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  UserModel? _user;
  List<MeasurementModel> _recentMeasurements = [];
  Map<String, double> _weeklyAverage = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      AppConstants.logInfo('Carregando dados da tela principal');

      final user = await _dbHelper.getUser();
      final measurements = await _dbHelper.getRecentMeasurements(limit: 3);
      final weeklyData = await _calculateWeeklyAverage();

      setState(() {
        _user = user;
        _recentMeasurements = measurements;
        _weeklyAverage = weeklyData;
        _isLoading = false;
      });

      AppConstants.logInfo('Dados carregados - Usuário: ${user?.name}, Medições: ${measurements.length}');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar dados da home', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, double>> _calculateWeeklyAverage() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      final measurements = await _dbHelper.getMeasurementsInRange(startDate, endDate);

      if (measurements.isEmpty) {
        return {};
      }

      double totalSystolic = 0;
      double totalDiastolic = 0;
      double totalHeartRate = 0;

      for (final measurement in measurements) {
        totalSystolic += measurement.systolic;
        totalDiastolic += measurement.diastolic;
        totalHeartRate += measurement.heartRate;
      }

      final count = measurements.length;
      return {
        'systolic': totalSystolic / count,
        'diastolic': totalDiastolic / count,
        'heartRate': totalHeartRate / count,
      };
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao calcular média semanal', e, stackTrace);
      return {};
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  void _navigateToAddMeasurement() {
    AppConstants.logNavigation('HomeScreen', 'AddMeasurementScreen');
    // TODO: Implementar navegação para tela de adicionar medição
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: _isLoading ? _buildLoadingState() : _buildContent(),
      ), //termina aqui
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppConstants.primaryColor,
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppConstants.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildWeeklyAverageCard(),
            const SizedBox(height: 24),
            _buildRecentMeasurementsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userName = _user?.name ?? 'Usuário';
    final age = _user?.age ?? 0;

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppConstants.logoGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, $userName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              if (age > 0)
                Text(
                  '$age anos',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyAverageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Média da Última Semana',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _weeklyAverage.isEmpty
                ? _buildNoDataMessage()
                : _buildAverageData(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: AppConstants.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              AppConstants.noDataMessage,
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

  Widget _buildAverageData() {
    final systolic = _weeklyAverage['systolic']!.round();
    final diastolic = _weeklyAverage['diastolic']!.round();
    final heartRate = _weeklyAverage['heartRate']!.round();

    // Criar medição temporária para classificação
    final tempMeasurement = MeasurementModel(
      systolic: systolic,
      diastolic: diastolic,
      heartRate: heartRate,
      measuredAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricColumn('Sistólica', '$systolic', 'mmHg'),
            Container(
              width: 1,
              height: 40,
              color: AppConstants.textSecondary.withOpacity(0.3),
            ),
            _buildMetricColumn('Diastólica', '$diastolic', 'mmHg'),
            Container(
              width: 1,
              height: 40,
              color: AppConstants.textSecondary.withOpacity(0.3),
            ),
            _buildMetricColumn('Batimentos', '$heartRate', 'bpm'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tempMeasurement.categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tempMeasurement.categoryColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            'Pressão ${tempMeasurement.categoryName}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tempMeasurement.categoryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricColumn(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 10,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMeasurementsSection() {
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
              onPressed: () {
                AppConstants.logNavigation('HomeScreen', 'HistoryScreen');
                // TODO: Navegar para histórico completo
              },
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
        _recentMeasurements.isEmpty
            ? _buildNoRecentMeasurements()
            : _buildMeasurementsList(),
      ],
    );
  }

  Widget _buildNoRecentMeasurements() {
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
              Icon(
                Icons.add_circle_outline,
                size: 48,
                color: AppConstants.primaryColor.withOpacity(0.5),
              ),
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

  Widget _buildMeasurementsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentMeasurements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final measurement = _recentMeasurements[index];
        return _buildMeasurementCard(measurement);
      },
    );
  }

  Widget _buildMeasurementCard(MeasurementModel measurement) {
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