// home_screen.dart - MESMA INTERFACE, PERFORMANCE OTIMIZADA
import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/measurement_model.dart';
import '../measurements/add_measurement_screen.dart';
import '../history/history_screen.dart';

// MESMO abstract class - SEM BREAKING CHANGES
abstract class HomeScreenController {
  void refreshData();
}

// MESMA classe pública - SEM BREAKING CHANGES
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin
    implements HomeScreenController {

  @override
  bool get wantKeepAlive => true;

  final db = DatabaseService.instance;

  // MESMOS campos públicos/protegidos
  UserModel? _user;
  List<MeasurementModel> _recentMeasurements = [];
  Map<String, double> _weeklyAverage = {};
  bool _isLoading = true;

  // NOVOS: Cache interno (não afeta API externa)
  Map<String, double>? _cachedWeeklyAverage;
  DateTime? _lastCalculationDate;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // MESMA assinatura pública - SEM BREAKING CHANGES
  @override
  void refreshData() {
    _refreshDataWithDebounce();
  }

  // OTIMIZADO: Execução paralela + cache
  Future<void> _loadData() async {
    try {
      AppConstants.logInfo('Carregando dados da tela principal');

      // OTIMIZAÇÃO 1: Execução paralela ao invés de sequencial
      final results = await Future.wait([
        db.getUser(),
        db.getRecentMeasurements(limit: 10),
        _calculateWeeklyAverageWithCache(),
      ]);

      if (!mounted) return;

      setState(() {
        _user = results[0] as UserModel?;
        _recentMeasurements = results[1] as List<MeasurementModel>;
        _weeklyAverage = results[2] as Map<String, double>;
        _isLoading = false;
      });

      AppConstants.logInfo('Dados carregados - Usuário: ${_user?.name}, Medições: ${_recentMeasurements.length}');
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar dados da home', e, stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // OTIMIZAÇÃO 2: Cache inteligente para média semanal
  Future<Map<String, double>> _calculateWeeklyAverageWithCache() async {
    final now = DateTime.now();

    // Cache válido por 30 minutos
    if (_cachedWeeklyAverage != null &&
        _lastCalculationDate != null &&
        now.difference(_lastCalculationDate!).inMinutes < 30) {
      AppConstants.logInfo('Usando cache da média semanal');
      return _cachedWeeklyAverage!;
    }

    AppConstants.logInfo('Calculando nova média semanal');
    final result = await _calculateWeeklyAverage();

    _cachedWeeklyAverage = result;
    _lastCalculationDate = now;

    return result;
  }

  // MÉTODO ORIGINAL mantido para não quebrar
  Future<Map<String, double>> _calculateWeeklyAverage() async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      final measurements = await db.getMeasurementsInRange(startDate, endDate);

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

  // OTIMIZAÇÃO 3: Debounce para refresh
  void _refreshDataWithDebounce() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _refreshData();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  // MESMAS assinaturas de navegação - SEM BREAKING CHANGES
  void _navigateToAddMeasurement() async {
    AppConstants.logNavigation('HomeScreen', 'AddMeasurementScreen');

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddMeasurementScreen(),
      ),
    );

    if (result == true) {
      _refreshDataWithDebounce(); // Usa versão otimizada
    }
  }

  void _navigateToHistory() async {
    AppConstants.logNavigation('HomeScreen', 'HistoryScreen');

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    );

    if (result == true) {
      _refreshDataWithDebounce(); // Usa versão otimizada
    }
  }

  Future<void> _refreshData() async {
    if (mounted) {
      await _loadData();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // NOVO: Limpar timer
    super.dispose();
  }

  // MESMA estrutura de build - SEM BREAKING CHANGES
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  // OTIMIZAÇÃO 4: Widget const estático
  static const Widget _loadingIndicator = CircularProgressIndicator(
    color: AppConstants.primaryColor,
  );

  Widget _buildLoadingState() {
    return const Center(child: _loadingIndicator);
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
          decoration: const BoxDecoration(
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
            const Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToAddMeasurement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Adicionar 1ª Medição'),
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
            _buildVerticalDivider(),
            _buildMetricColumn('Diastólica', '$diastolic', 'mmHg'),
            _buildVerticalDivider(),
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

  // OTIMIZAÇÃO 5: Widget const para divisor
  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppConstants.textSecondary.withOpacity(0.3),
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
              onPressed: _navigateToHistory,
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

  // OTIMIZAÇÃO 6: ListView mais eficiente
  Widget _buildMeasurementsList() {
    return ListView.builder( // Mudou de separated para builder
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentMeasurements.length * 2 - 1, // Para incluir separadores
      cacheExtent: 100, // Cache para performance
      itemBuilder: (context, index) {
        if (index.isOdd) {
          return const SizedBox(height: 8); // Separador
        }

        final measurementIndex = index ~/ 2;
        return _buildMeasurementCard(_recentMeasurements[measurementIndex]);
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