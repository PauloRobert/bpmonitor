import 'package:flutter/material.dart';
import 'package:bp_monitor/core/di/injection_container.dart';
import 'package:bp_monitor/core/localization/app_strings.dart';
import 'package:bp_monitor/core/theme/app_theme.dart';
import 'package:bp_monitor/core/constants/app_constants.dart';
import 'package:bp_monitor/presentation/common/widgets/app_drawer.dart';
import 'package:bp_monitor/domain/repositories/measurement_repository.dart';
import 'package:bp_monitor/domain/entities/measurement_entity.dart';
import 'package:bp_monitor/domain/usecases/get_pressure_category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppStrings _strings = sl<AppStrings>();
  final AppTheme _theme = sl<AppTheme>();
  final MeasurementRepository _repository = sl<MeasurementRepository>();
  final GetPressureCategory _getPressureCategory = sl<GetPressureCategory>();

  List<MeasurementEntity> _recentMeasurements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _repository.getRecentMeasurements(limit: 3);

      result.fold(
            (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
            (measurements) {
          setState(() {
            _recentMeasurements = measurements;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_strings.home),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppConstants.homeRoute),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: _theme.primaryColor,
        child: _buildContent(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppConstants.addMeasurementRoute);
        },
        backgroundColor: _theme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: _theme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(color: _theme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text(_strings.tryAgain),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWelcomeCard(),
        const SizedBox(height: 24),
        _buildLastMeasurementsSection(),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _theme.logoGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _strings.get('welcome_title', defaultValue: 'Olá!'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _strings.get('welcome_subtitle', defaultValue: 'Monitore sua saúde regularmente'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppConstants.addMeasurementRoute);
              },
              icon: const Icon(Icons.add),
              label: Text(_strings.addMeasurement),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastMeasurementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _strings.lastMeasurements,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppConstants.historyRoute);
              },
              child: Text(_strings.viewAll),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _recentMeasurements.isEmpty
            ? _buildNoMeasurementsCard()
            : Column(
          children: _recentMeasurements
              .map((measurement) => _buildMeasurementCard(measurement))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNoMeasurementsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: _theme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _strings.noMeasurements,
              style: TextStyle(
                fontSize: 16,
                color: _theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppConstants.addMeasurementRoute);
              },
              child: Text(_strings.addMeasurement),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(MeasurementEntity measurement) {
    final category = _getPressureCategory(
        systolic: measurement.systolic,
        diastolic: measurement.diastolic
    );

    final categoryName = _getPressureCategory.getName(category);
    final categoryColor = _theme.getCategoryColor(category);

    // Formatar data e hora
    final dateTime = measurement.measuredAt;
    final date = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: categoryColor,
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
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${measurement.heartRate} bpm',
                        style: TextStyle(
                          fontSize: 14,
                          color: _theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$date $time',
                        style: TextStyle(
                          fontSize: 12,
                          color: _theme.textSecondaryColor,
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
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                categoryName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: categoryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}