// home_screen.dart - VERSÃO FINAL OTIMIZADA
import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/measurement_model.dart';
import '../measurements/add_measurement_screen.dart';
import '../history/history_screen.dart';
import '../../shared/widgets/main_navigation.dart';

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

  final DatabaseService _db = DatabaseService.instance;

  // Estado da UI
  UserModel? _user;
  List<MeasurementModel> _recentMeasurements = [];
  Map<String, double> _weeklyAverage = {};
  bool _isLoading = true;

  // Cache interno
  Map<String, double>? _cachedWeeklyAverage;
  DateTime? _lastCalculationDate;
  Timer? _refreshTimer;
  Timer? _cacheCleanupTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _schedulePeriodicCacheCleanup();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _cacheCleanupTimer?.cancel();
    super.dispose();
  }

  // MESMA assinatura pública - SEM BREAKING CHANGES
  @override
  void refreshData() {
    _refreshDataWithDebounce();
  }

  /// Carregamento principal de dados com verificações robustas
  Future<void> _loadData() async {
    try {
      AppConstants.logInfo('Iniciando carregamento da HomeScreen');

      // Passo 1: Carrega dados básicos em paralelo
      final basicResults = await Future.wait([
        _db.getUser(),
        _db.getRecentMeasurements(limit: 10),
      ]);

      if (!mounted) return;

      // Passo 2: Atualiza estado com dados carregados
      setState(() {
        _user = basicResults[0] as UserModel?;
        _recentMeasurements = basicResults[1] as List<MeasurementModel>;
      });

      // Passo 3: Calcula média com dados já em memória
      final weeklyAverage = await _calculateWeeklyAverageOptimized();

      if (!mounted) return;

      setState(() {
        _weeklyAverage = weeklyAverage;
        _isLoading = false;
      });

      AppConstants.logInfo(
          'HomeScreen carregada - Usuário: ${_user?.name}, '
              'Medições recentes: ${_recentMeasurements.length}, '
              'Média semanal: ${_weeklyAverage.isNotEmpty ? "calculada" : "vazia"}'
      );

    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao carregar HomeScreen', e, stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erro ao carregar dados. Tente novamente.');
      }
    }
  }

  /// Calcula média semanal usando dados em memória quando possível
  Future<Map<String, double>> _calculateWeeklyAverageOptimized() async {
    final now = DateTime.now();

    // Verifica cache válido (30 minutos)
    if (_isCacheValid(now)) {
      AppConstants.logInfo('Usando cache da média semanal');
      return _cachedWeeklyAverage!;
    }

    try {
      AppConstants.logInfo('Calculando nova média semanal');

      final endDate = now;
      final startDate = endDate.subtract(const Duration(days: 7));

      // Estratégia 1: Usar dados já carregados se suficientes
      List<MeasurementModel> measurements = _filterRecentMeasurementsForWeek(startDate, endDate);

      // Estratégia 2: Buscar no banco se dados insuficientes
      if (measurements.length < 3 && _recentMeasurements.isNotEmpty) {
        AppConstants.logInfo('Buscando dados adicionais no banco para média');
        measurements = await _db.getMeasurementsInRange(startDate, endDate);
      }

      final result = _calculateAverageFromMeasurements(measurements);

      // Atualiza cache
      _cachedWeeklyAverage = result;
      _lastCalculationDate = now;

      AppConstants.logInfo('Média calculada com ${measurements.length} medições');
      return result;

    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao calcular média semanal', e, stackTrace);
      return {};
    }
  }

  /// Filtra medições recentes para última semana
  List<MeasurementModel> _filterRecentMeasurementsForWeek(DateTime startDate, DateTime endDate) {
    return _recentMeasurements.where((measurement) {
      return measurement.measuredAt.isAfter(startDate) &&
          measurement.measuredAt.isBefore(endDate);
    }).toList();
  }

  /// Calcula estatísticas de uma lista de medições
  Map<String, double> _calculateAverageFromMeasurements(List<MeasurementModel> measurements) {
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
  }

  /// Verifica se cache é válido
  bool _isCacheValid(DateTime now) {
    return _cachedWeeklyAverage != null &&
        _lastCalculationDate != null &&
        now.difference(_lastCalculationDate!).inMinutes < 30;
  }

  /// Refresh com debounce para evitar múltiplas chamadas
  void _refreshDataWithDebounce() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _invalidateCache();
        _refreshData();
      }
    });
  }

  /// Invalida cache quando dados mudam
  void _invalidateCache() {
    _cachedWeeklyAverage = null;
    _lastCalculationDate = null;
    AppConstants.logInfo('Cache da média semanal invalidado');
  }

  /// Limpeza periódica de cache
  void _schedulePeriodicCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (mounted && _lastCalculationDate != null) {
        final now = DateTime.now();
        if (now.difference(_lastCalculationDate!).inHours > 2) {
          _invalidateCache();
          AppConstants.logInfo('Cache limpo automaticamente');
        }
      }
    });
  }

  Future<void> _refreshData() async {
    if (mounted) {
      await _loadData();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  /// Navegação para adicionar medição
  void _navigateToAddMeasurement() async {
    AppConstants.logNavigation('HomeScreen', 'AddMeasurementScreen');

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddMeasurementScreen(),
      ),
    );

    if (result == true) {
      _invalidateCache(); // Invalida cache pois dados podem ter mudado
      _refreshDataWithDebounce();
    }
  }

  /// Navegação para histórico
  void _navigateToHistory() async {
    AppConstants.logNavigation('HomeScreen', 'HistoryScreen');
    // Usa a navegação do MainNavigation

    MainNavigation.navigateToTab(context, 1); // Índice 1 = Histórico

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
        settings: const RouteSettings(
          arguments: {'forceRefresh': true}, // Força refresh
      ),
      ),
    );

    if (result == true) {
      _invalidateCache(); // Invalida cache pois dados podem ter mudado
      _refreshDataWithDebounce();
    }
  }

  /// Mostra mensagem de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppConstants.dangerColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  /// Estado de carregamento otimizado
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppConstants.primaryColor,
      ),
    );
  }

  /// Conteúdo principal
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

  /// Header com saudação e informações do usuário
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

  /// Card de média semanal
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

  /// Mensagem quando não há dados
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

  /// Dados da média calculada
  Widget _buildAverageData() {
    final systolic = _weeklyAverage['systolic']!.round();
    final diastolic = _weeklyAverage['diastolic']!.round();
    final heartRate = _weeklyAverage['heartRate']!.round();

    // Cria medição temporária para classificação
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

  /// Divisor vertical
  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppConstants.textSecondary.withOpacity(0.3),
    );
  }

  /// Coluna de métrica individual
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

  /// Seção de medições recentes
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

  /// Estado quando não há medições recentes
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

  /// Lista de medições otimizada
  Widget _buildMeasurementsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentMeasurements.length * 2 - 1,
      cacheExtent: 100,
      itemBuilder: (context, index) {
        if (index.isOdd) {
          return const SizedBox(height: 8);
        }

        final measurementIndex = index ~/ 2;
        return _buildMeasurementCard(_recentMeasurements[measurementIndex]);
      },
    );
  }

  /// Card individual de medição
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