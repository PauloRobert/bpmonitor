import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/measurement_model.dart';

import '../measurements/add_measurement_screen.dart';
import '../history/history_screen.dart';

// NOVO SERVICE
import '../home/services/home_service.dart';

// Widgets extraídos
import '../home/widgets/home_header.dart';
import '../home/widgets/weekly_average_card.dart';
import '../home/widgets/recent_measurements_section.dart';

// Controller sem alterações
abstract class HomeScreenController {
  void refreshData();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    implements HomeScreenController {

  // Serviços
  final HomeService _service = HomeService();

  // Estado
  UserModel? _user;
  List<MeasurementModel> _recentMeasurements = [];
  Map<String, double> _weeklyAverage = {};

  bool _isLoading = true;

  Timer? _refreshTimer;
  Timer? _cacheCleanupTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _schedulePeriodicCacheCleanup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Atualiza automaticamente quando a Home voltar para o foco
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent) {
        _invalidateCache();
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _cacheCleanupTimer?.cancel();
    super.dispose();
  }

  // ----------------------------
  // PUBLIC API
  // ----------------------------
  @override
  void refreshData() {
    _refreshDataWithDebounce();
  }

  // ----------------------------------------------------
  // BOOTSTRAP
  // ----------------------------------------------------

  Future<void> _loadData() async {
    try {
      AppConstants.logInfo('[HomeScreen] loadData:start');

      final userFuture = _service.loadUserProfile();
      final recentFuture = _service.loadRecentMeasurements(limit: 10);

      final results = await Future.wait([userFuture, recentFuture]);

      if (!mounted) return;

      final loadedUser = results[0] as UserModel?;
      final loadedRecent = results[1] as List<MeasurementModel>;

      setState(() {
        _user = loadedUser;
        _recentMeasurements = loadedRecent;
      });

      final avg = await _service.computeWeeklyAverageOptimized(
        recentMeasurements: loadedRecent,
      );

      if (!mounted) return;

      setState(() {
        _weeklyAverage = avg;
        _isLoading = false;
      });

      AppConstants.logInfo(
        '[HomeScreen] loadData:success '
            'recent=${loadedRecent.length} avg=${avg.isNotEmpty}',
      );
    } catch (e, st) {
      AppConstants.logError('[HomeScreen] loadData:error', e, st);
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(AppConstants.defaultErrorMessage);
      }
    }
  }

  // ----------------------------------------------------
  // REFRESH / CACHE
  // ----------------------------------------------------

  void _refreshDataWithDebounce() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _invalidateCache();
      _refreshData();
    });
  }

  void _invalidateCache() {
    AppConstants.logInfo('[HomeScreen] invalidateCache');
    _service.invalidateCache();
  }

  Future<void> _refreshData() async {
    if (mounted) await _loadData();
  }

  void _schedulePeriodicCacheCleanup() {
    _cacheCleanupTimer =
        Timer.periodic(const Duration(hours: 1), (timer) {
          _service.invalidateCache();
          AppConstants.logInfo('[HomeScreen] auto cache cleanup');
        });
  }

  // ----------------------------------------------------
  // UI HELPERS
  // ----------------------------------------------------

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppConstants.dangerColor,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // NAVIGATION
  // ----------------------------------------------------

  void _navigateToAddMeasurement() async {
    AppConstants.logNavigation('HomeScreen', 'AddMeasurementScreen');

    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddMeasurementScreen()),
    );

    if (result is MeasurementModel) {
      _invalidateCache();
      try {
        final MeasurementModel newOrUpdated = result;

        final List<MeasurementModel> updatedList =
        List<MeasurementModel>.from(_recentMeasurements);

        final existingIndex = updatedList.indexWhere(
              (m) => m.id == newOrUpdated.id && newOrUpdated.id != null,
        );

        if (existingIndex >= 0) {
          updatedList[existingIndex] = newOrUpdated;
        } else {
          updatedList.insert(0, newOrUpdated);
          if (updatedList.length > 10) {
            updatedList.removeLast();
          }
        }

        final avg = await _service.computeWeeklyAverageOptimized(
          recentMeasurements: updatedList,
        );

        if (!mounted) return;

        setState(() {
          _recentMeasurements = updatedList;
          _weeklyAverage = avg;
        });
      } catch (e, st) {
        AppConstants.logError('[HomeScreen] updateLocalAfterAdd:error', e, st);

        _invalidateCache();
        if (mounted) {
          setState(() => _isLoading = true);
          await _loadData();
        }
      }
      return;
    }

    if (result == true) {
      _invalidateCache();
      if (mounted) {
        setState(() => _isLoading = true);
        await _loadData();
      }
    }
  }

  void _navigateToHistory() async {
    AppConstants.logNavigation('HomeScreen', 'HistoryScreen');

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HistoryScreen(),
        settings: const RouteSettings(arguments: {'forceRefresh': true}),
      ),
    );

    _invalidateCache();
    if (mounted) {
      setState(() => _isLoading = true);
      await _loadData();
    }
  }

  // ----------------------------------------------------
  // BUILD
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: _isLoading ? _buildLoading() : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppConstants.primaryColor),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      color: AppConstants.primaryColor,
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeader(
              user: _user,
              greeting: _getGreeting(),
            ),
            const SizedBox(height: 32),
            WeeklyAverageCard(
              weeklyAverage: _weeklyAverage,
              onAddMeasurement: _navigateToAddMeasurement,
            ),
            const SizedBox(height: 24),
            RecentMeasurementsSection(
              measurements: _recentMeasurements,
              onNavigateToHistory: _navigateToHistory,
            ),
          ],
        ),
      ),
    );
  }
}