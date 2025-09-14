/// ============================================================================
/// ReportsScreen - REFATORADA
/// ============================================================================
/// - Fachada pública que mantém 100% de compatibilidade
/// - Orquestra ReportsDataService e ReportsWidgets
/// - Responsável apenas por estado da UI e coordenação
/// - Muito mais limpa e fácil de manter
/// ============================================================================

import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import '../../features/reports/report_pdf_service.dart';
import 'reports_data_service.dart';
import 'reports_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  // Services
  final ReportsDataService _dataService = ReportsDataService();

  // Animation
  late AnimationController _masterController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _chartAnimation;

  // State
  Map<String, dynamic> _reportData = {};
  UserModel? _user;
  bool _isLoading = true;
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
    _loadData();
  }

  void _initializeAnimations() {
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

  /// Carrega dados usando o serviço
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final result = await _dataService.loadData();

      if (!mounted) return;

      if (result['success'] == true) {
        _user = result['user'];
        _generateReportData();
        _masterController.forward();
      } else {
        _showErrorMessage('Erro ao carregar dados: ${result['error']}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Gera dados do relatório
  void _generateReportData() {

    print('DEBUG: Gerando relatório para período $_selectedPeriod');
    print('DEBUG: Measurements no service: ${_dataService.measurements.length}');

    final reportData = _dataService.generateReportData(_selectedPeriod);

    print('DEBUG: Dados gerados: ${reportData.keys}');
    print('DEBUG: Total measurements no relatório: ${reportData['totalMeasurements']}');


    setState(() {
      _reportData = reportData;
    });
  }

  /// Mudança de período com debounce
  void _changePeriod(String period) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      setState(() {
        _selectedPeriod = period;
      });
      _generateReportData();

      _masterController.reset();
      _masterController.forward();
    });
  }

  /// Geração de PDF com toast elegante
  Future<void> _generateAndSharePDF() async {
    if (_user == null || _reportData.isEmpty) {
      _showErrorMessage('Dados insuficientes para gerar o relatório');
      return;
    }

    // Toast de carregamento
    _showLoadingToast();

    try {
      final periodLabel = _periods[_selectedPeriod] ?? 'Período personalizado';
      final pdfService = ReportPdfService();

      final pdfPath = await pdfService.generateHealthReport(
        user: _user!,
        measurements: _dataService.getFilteredMeasurements(_selectedPeriod),
        reportData: _reportData,
        periodLabel: periodLabel,
      );

      _hideLoadingToast();
      _showSuccessToast('PDF gerado com sucesso!');

      await pdfService.sharePdf(pdfPath);

    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao gerar PDF', e, stackTrace);
      _hideLoadingToast();
      _showErrorMessage('Erro ao gerar PDF');
    }
  }

  /// Compartilhamento (placeholder)
  void _handleShare() {
    _showInfoToast('Funcionalidade em desenvolvimento');
  }

  // =================== TOAST METHODS ===================

  void _showLoadingToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Gerando PDF...'),
          ],
        ),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 30), // Longo para dar tempo
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _hideLoadingToast() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showInfoToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppConstants.warningColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppConstants.dangerColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // =================== BUILD METHODS ===================

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
        ReportsWidgets.buildAppBar(),
        ReportsWidgets.buildPeriodSelector(
          periods: _periods,
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: _changePeriod,
        ),
        Expanded(
          child: _reportData.isEmpty
              ? ReportsWidgets.buildEmptyState()
              : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),
                ReportsWidgets.buildTrendCard(
                  animation: _chartAnimation,
                  reportData: _reportData,
                  periods: _periods,
                  selectedPeriod: _selectedPeriod,
                ),
                const SizedBox(height: 16),
                ReportsWidgets.buildSummaryCard(
                  animation: _chartAnimation,
                  reportData: _reportData,
                ),
                const SizedBox(height: 16),
                ReportsWidgets.buildStatisticsGrid(
                  animation: _chartAnimation,
                  reportData: _reportData,
                ),
                const SizedBox(height: 16),
                ReportsWidgets.buildCategoryDistribution(
                  animation: _chartAnimation,
                  reportData: _reportData,
                ),
                const SizedBox(height: 16),
                ReportsWidgets.buildInsightsCard(
                  animation: _chartAnimation,
                  reportData: _reportData,
                ),
                const SizedBox(height: 16),
                ReportsWidgets.buildActionButtons(
                  isLoading: _isLoading,
                  hasData: _reportData.isNotEmpty,
                  onGeneratePDF: _generateAndSharePDF,
                  onShare: _handleShare,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}