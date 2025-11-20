import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../features/measurements/measurements_list_tab.dart' as list_tab;
import '../../features/measurements/measurements_chart_tab.dart' as chart_tab;

import 'controllers/history_controller.dart';
import 'controllers/history_period_filter.dart';
import 'widgets/history_appbar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin
    implements HistoryScreenController {

  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  late HistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HistoryController(this);

    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadMeasurementsOptimized();
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 0) {
        _controller.loadMeasurementsWithDebounce();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ✅ CORRIGIDO: Este método é chamado pelo MainNavigation
  @override
  void loadMeasurements() {
    // Limpa cache antes de recarregar
    _controller.periodFilter.clearCache();
    _controller.loadMeasurementsOptimized(); // Usa o método direto, sem debounce
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Scaffold(
          backgroundColor: AppConstants.backgroundColor,
          appBar: buildHistoryAppBar(
            context: context,
            controller: _controller,
            tabController: _tabController,
          ),
          body: _controller.isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: AppConstants.primaryColor,
            ),
          )
              : TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              list_tab.MeasurementsListTab(
                measurements: _controller.filteredMeasurements,
                onPeriodChange: _controller.changePeriod,
                onEditMeasurement: (measurement) =>
                    _controller.editMeasurement(context, measurement),
                onDeleteMeasurement: (measurement) =>
                    _controller.deleteMeasurement(context, measurement),
                onLoadMeasurements: loadMeasurements,
                selectedPeriod: _controller.selectedPeriod,
                periods: _controller.periods,
              ),
              chart_tab.MeasurementsChartTab(
                measurements: _controller.filteredMeasurements,
                showHeartRate: _controller.showHeartRate,
                onToggleHeartRate: (val) =>
                    _controller.toggleShowHeartRate(val),
              ),
            ],
          ),
        );
      },
    );
  }
}